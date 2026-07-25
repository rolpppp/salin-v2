class InferenceResult<T> {
  final String provider;
  final String model;
  final Duration latency;
  final String finishReason;
  final Map<String, dynamic> safetyFlags;
  final Map<String, dynamic> usage;
  final String rawResponse;
  final T parsedPayload;

  const InferenceResult({
    required this.provider,
    required this.model,
    required this.latency,
    required this.finishReason,
    required this.safetyFlags,
    required this.usage,
    required this.rawResponse,
    required this.parsedPayload,
  });
}
