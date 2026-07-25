class AIResult<T> {
  final String id;
  final String provider;
  final String source;
  final Duration processingTime;
  final double confidence;
  final List<String> warnings;
  final String rawResponse;
  final T? parsedData;
  final String? errorMessage;

  const AIResult({
    required this.id,
    required this.provider,
    required this.source,
    required this.processingTime,
    required this.confidence,
    required this.warnings,
    required this.rawResponse,
    this.parsedData,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null && parsedData != null;
  bool get isFailure => errorMessage != null;
}
