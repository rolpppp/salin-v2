import Flutter
import UIKit

// Requires iOS 26+ deployment target and the FoundationModels framework,
// which only exists on iOS 26 and later. Guard the import so this still
// compiles for anyone on an older SDK during the transition.
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Implements the "app.salin/local_ai" channel that local_ai_service.dart
/// already expects. Register this in AppDelegate.swift (see bottom of this
/// file for the snippet) — right now nothing answers that channel at all,
/// which is why isHardwareSupported() always silently returns false.
@available(iOS 26.0, *)
class LocalAIChannel: NSObject {
    static let channelName = "app.salin/local_ai"

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = LocalAIChannel()
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "isHardwareSupported":
                instance.isHardwareSupported(result: result)
            case "parseLocal":
                guard let args = call.arguments as? [String: Any],
                      let prompt = args["prompt"] as? String else {
                    result(FlutterError(code: "BAD_ARGS", message: "Missing 'prompt' argument", details: nil))
                    return
                }
                instance.parseLocal(prompt: prompt, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func isHardwareSupported(result: @escaping FlutterResult) {
        #if canImport(FoundationModels)
        // SystemLanguageModel.default.availability reflects both hardware
        // eligibility AND whether Apple Intelligence is actually turned on
        // in Settings — a capable device with Apple Intelligence disabled
        // correctly reports unavailable here, which is exactly right.
        switch SystemLanguageModel.default.availability {
        case .available:
            result(true)
        case .unavailable:
            result(false)
        @unknown default:
            result(false)
        }
        #else
        result(false)
        #endif
    }

    private func parseLocal(prompt: String, result: @escaping FlutterResult) {
        #if canImport(FoundationModels)
        guard SystemLanguageModel.default.availability == .available else {
            result(nil) // triggers the Dart-side cloud fallback, as designed
            return
        }

        Task {
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                result(response.content)
            } catch {
                // Return nil (not FlutterError) so the Dart side's existing
                // "silently fall back to cloud" behavior still applies —
                // an on-device hiccup shouldn't be a hard failure for the
                // user, just a routing decision.
                result(nil)
            }
        }
        #else
        result(nil)
        #endif
    }
}

/*
 Add to AppDelegate.swift, inside application(_:didFinishLaunchingWithOptions:),
 before the call to GeneratedPluginRegistrant.register(with: self):

    if #available(iOS 26.0, *) {
        if let registrar = self.registrar(forPlugin: "LocalAIChannel") {
            LocalAIChannel.register(with: registrar)
        }
    }

 Also required:
 - Deployment target raised to iOS 26.0 in ios/Podfile and Xcode project settings
 - Test on a real iPhone 16e, not the simulator — the on-device model isn't
   available in the simulator
 - Apple Intelligence must be turned on in Settings > Apple Intelligence & Siri
   on the test device, and the on-device model must have finished downloading
   (first-time setup can take a while over Wi-Fi)
*/
