import 'ai_provider.dart';
import 'ai_adapter.dart';
import 'ai_result.dart';
import 'parsed_transaction.dart';
import 'ai_validator.dart';

class AIService {
  final AIProvider? _provider;
  final AIAdapter<ParsedTransaction>? _adapter;

  AIService({
    AIProvider? provider,
    AIAdapter<ParsedTransaction>? adapter,
  })  : _provider = provider,
        _adapter = adapter;

  Future<AIResult<ParsedTransaction>> parseTransaction(String rawText) async {
    if (_provider == null || _adapter == null) {
      return AIResult<ParsedTransaction>(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        provider: 'None',
        source: 'Text',
        processingTime: Duration.zero,
        confidence: 0.0,
        warnings: const ['No active AI providers.'],
        rawResponse: '',
        errorMessage: 'AI service parsing not implemented in this sprint.',
      );
    }

    try {
      final startTime = DateTime.now();
      final inferenceResult = await _provider!.parseTransaction(rawText);
      final duration = DateTime.now().difference(startTime);

      final adaptedResult = _adapter!.adapt(inferenceResult);

      if (adaptedResult.isSuccess) {
        final parsedData = adaptedResult.parsedData!;
        final validationWarnings = AIValidator.validate(parsedData);

        return AIResult<ParsedTransaction>(
          id: adaptedResult.id,
          provider: adaptedResult.provider,
          source: adaptedResult.source,
          processingTime: duration,
          confidence: adaptedResult.confidence,
          warnings: [...adaptedResult.warnings, ...validationWarnings],
          rawResponse: adaptedResult.rawResponse,
          parsedData: parsedData,
        );
      } else {
        return adaptedResult;
      }
    } catch (e) {
      return AIResult<ParsedTransaction>(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        provider: _provider!.name,
        source: 'Text',
        processingTime: Duration.zero,
        confidence: 0.0,
        warnings: const [],
        rawResponse: '',
        errorMessage: 'Failed parsing transaction: $e',
      );
    }
  }
}
