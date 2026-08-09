import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ai_provider.dart';
import 'ai_adapter.dart';
import 'ai_result.dart';
import 'inference_result.dart';
import 'parsed_transaction.dart';
import 'ai_validator.dart';
import 'rule_parser.dart';
import 'gemini_cloud_provider.dart';
import 'parsed_transaction_adapter.dart';
import 'local_ai_service.dart';
import '../config/ai_config.dart';

class AIService {
  final List<AIProvider> _providers;
  final AIAdapter<List<ParsedTransaction>> _adapter;
  final LocalAIService _localAI;

  AIService({
    List<AIProvider>? providers,
    AIAdapter<List<ParsedTransaction>>? adapter,
    LocalAIService? localAI,
  })  : _providers = providers ?? [RuleParser(), GeminiCloudProvider()],
        _adapter = adapter ?? ParsedTransactionAdapter(),
        _localAI = localAI ?? LocalAIService();

  Future<bool> _checkFastPreFilter() async {
    try {
      final result = await InternetAddress.lookup('generativelanguage.googleapis.com')
          .timeout(const Duration(milliseconds: 600));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<AIResult<List<ParsedTransaction>>> parseTransaction(String rawText) async {
    final startTime = DateTime.now();

    // 1. Hardware capability check for local NPU on-device AI (disabled/deprecated)
    final isLocalSupported = await _localAI.isHardwareSupported();
    if (isLocalSupported) {
      try {
        final systemPrompt = """You are a strict, precise financial data extraction engine for a college budgeting app. Your sole job is to read the user's input, identify every distinct financial transaction (income or expense), and output them as a structured JSON array.

RULES:
1. MULTIPLE TRANSACTIONS: A user may log multiple transactions in one sentence. You must extract EVERY distinct transaction into its own separate object within the JSON array.
2. IGNORE FLUFF: Completely ignore conversational filler, complaints, emotional text, or storytelling (e.g., "Okay let's see", "Worth it though", "Man I had to rush"). DO NOT create empty or zero-amount transactions for these.
3. CONTEXTUAL TITLES: Create a concise, 2-to-4 word title for each transaction based on the item bought or the income received. 
4. CATEGORIES: You may ONLY use the following categories: Food, Transport, Academics, Dorm, Leisure, Income, Uncategorized.
5. FORMAT: You must return ONLY a valid JSON array of objects. Do not include markdown formatting, backticks, or conversational text.

JSON SCHEMA:
[
  {
    "title": "String (Concise description of the specific item)",
    "amount": Number (The exact numeric value),
    "category": "String (Must match the allowed categories list)",
    "type": "String (Must be 'expense' or 'income')"
  }
]""";

        final localJsonStr = await _localAI.parseLocal(systemPrompt, rawText);
        if (localJsonStr != null) {
          final parsedList = jsonDecode(localJsonStr.trim()) as List<dynamic>;

          final parsedTransactions = parsedList.map((item) {
            final categoryName = (item['category'] as String? ?? 'Uncategorized').toLowerCase();
            final double amtVal = (item['amount'] as num? ?? 0.0).toDouble();
            final amountMinor = (amtVal * 100).round();

            return ParsedTransaction(
              description: item['title'] as String? ?? 'Local Quick Add',
              amountMinor: amountMinor > 0 ? amountMinor : null,
              currency: 'PHP',
              transactionType: item['type'] as String? ?? 'expense',
              category: categoryName == 'uncategorized' ? null : categoryName,
              transactionDate: DateTime.now().toUtc(),
            );
          }).toList();

          final duration = DateTime.now().difference(startTime);
          final validationWarnings = <String>[];
          for (final tx in parsedTransactions) {
            validationWarnings.addAll(AIValidator.validate(tx));
          }

          debugPrint('[AI Routing] 🚀 Utilized On-Device Local NPU (Apple Intelligence / Gemini Nano)');
          return AIResult<List<ParsedTransaction>>(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            provider: 'Local NPU (On-Device)',
            source: 'Text',
            processingTime: duration,
            confidence: 0.95,
            warnings: validationWarnings,
            rawResponse: localJsonStr,
            parsedData: parsedTransactions,
          );
        }
      } catch (e) {
        debugPrint('[AI Routing] ⚠️ Local NPU parsing failed: $e. Silently falling back to default cloud provider chain.');
      }
    }

    // 2. Rule Parser first — always. It's synchronous, instant, offline,
    // and free, and it already handles the exact-format case ("Lunch 180")
    // that most Quick Add input actually is. Cloud is only ever consulted
    // as a fallback for ambiguous/unparseable input, and only with
    // explicit user consent — see step 3 below. This matches the
    // documented privacy order: Rule Parser -> Native -> Cloud (opt-in).
    final ruleParser = _providers.firstWhere((p) => p is RuleParser, orElse: () => RuleParser());

    InferenceResult<List<ParsedTransaction>>? ruleResult;
    Object? ruleParserError;
    try {
      ruleResult = await ruleParser.parseTransaction(rawText);
    } catch (e) {
      ruleParserError = e;
    }

    AIResult<List<ParsedTransaction>> ruleParserFailureResult() {
      return AIResult<List<ParsedTransaction>>(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        provider: ruleParser.name,
        source: 'Text',
        processingTime: DateTime.now().difference(startTime),
        confidence: 0.0,
        warnings: const [],
        rawResponse: '',
        errorMessage: ruleParserError is FormatException
            ? ruleParserError.message
            : 'Failed parsing transaction: $ruleParserError',
      );
    }

    // Every line matched the exact "<amount> <description>" format — no
    // ambiguity, so return instantly without ever touching the network.
    final ruleParserConfident = ruleResult != null &&
        ruleResult.parsedPayload.every((tx) => tx.notes != 'needs_review');

    InferenceResult<List<ParsedTransaction>> inferenceResult;
    AIProvider activeProvider;

    if (ruleParserConfident) {
      debugPrint('[AI Routing] 🔍 Rule Parser matched exactly. Skipping cloud entirely.');
      inferenceResult = ruleResult;
      activeProvider = ruleParser;
    } else {
      // 3. Ambiguous parse (needs_review) or no parse at all — only
      // escalate to Gemini if the user has opted in to cloud AI AND the
      // device is online. Otherwise surface the Rule Parser's best-effort
      // result as-is; ambiguous lines show as NEEDS REVIEW for manual
      // editing, which is an acceptable non-blocking path.
      final cloudEnabled = await AIConfig.isCloudAiEnabled();
      final isOnline = cloudEnabled && await _checkFastPreFilter();

      if (cloudEnabled && isOnline) {
        activeProvider = _providers.firstWhere((p) => p is GeminiCloudProvider, orElse: () => GeminiCloudProvider());
        debugPrint('[AI Routing] ☁️ Ambiguous/unparsed input with cloud AI enabled and online. Routing to GeminiCloudProvider.');
        try {
          inferenceResult = await activeProvider.parseTransaction(rawText);
        } catch (e) {
          debugPrint('[AI Routing] ⚠️ Gemini Cloud call failed with error: $e. Degrading to RuleParser.');
          activeProvider = ruleParser;
          if (ruleResult == null) return ruleParserFailureResult();
          inferenceResult = ruleResult;
        }
      } else {
        debugPrint(
          '[AI Routing] ℹ️ Ambiguous/unparsed input; cloud AI '
          '${cloudEnabled ? "enabled but device is offline" : "disabled by user"}. '
          'Using RuleParser result as-is.',
        );
        activeProvider = ruleParser;
        if (ruleResult == null) return ruleParserFailureResult();
        inferenceResult = ruleResult;
      }
    }

    final duration = DateTime.now().difference(startTime);
    final adaptedResult = _adapter.adapt(inferenceResult);

    if (adaptedResult.isSuccess) {
      final parsedData = adaptedResult.parsedData!;
      final validationWarnings = <String>[];
      for (final tx in parsedData) {
        validationWarnings.addAll(AIValidator.validate(tx));
      }

      if (adaptedResult.provider == 'Rule Parser') {
        debugPrint('[AI Routing] 🔍 Utilized Local Rule Parser (Offline Regex Matching)');
      } else {
        debugPrint('[AI Routing] ☁️ Utilized Gemini Cloud REST API (gemini-3.1-flash-lite)');
      }

      return AIResult<List<ParsedTransaction>>(
        id: adaptedResult.id,
        provider: adaptedResult.provider,
        source: adaptedResult.source,
        processingTime: duration,
        confidence: adaptedResult.confidence,
        warnings: [...adaptedResult.warnings, ...validationWarnings],
        rawResponse: adaptedResult.rawResponse,
        parsedData: parsedData,
      );
    }

    return AIResult<List<ParsedTransaction>>(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      provider: activeProvider.name,
      source: 'Text',
      processingTime: duration,
      confidence: 0.0,
      warnings: const [],
      rawResponse: '',
      errorMessage: 'Failed to parse transaction input.',
    );
  }
}
