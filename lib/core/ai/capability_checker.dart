abstract class CapabilityChecker {
  Future<bool> isCapable();
  Future<List<String>> getAvailableCapabilities();
}
