import 'ai_adapter.dart';
import 'ai_result.dart';
import 'inference_result.dart';
import 'parsed_transaction.dart';

class ParsedTransactionAdapter implements AIAdapter<List<ParsedTransaction>> {
  @override
  AIResult<List<ParsedTransaction>> adapt(InferenceResult<List<ParsedTransaction>> providerResult) {
    // The heuristics path (used when the real model call fails or isn't
    // configured) is a much cruder parser than the LLM — it shouldn't look
    // identical to a real parse in the review UI. Flagging it here means it
    // surfaces as "Needs Review" downstream rather than silently passing
    // for confident, correct output.
    final isDegradedFallback = providerResult.provider.contains('Heuristics Fallback');

    return AIResult<List<ParsedTransaction>>(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      provider: providerResult.provider,
      source: 'Text',
      processingTime: providerResult.latency,
      confidence: providerResult.provider == 'Rule Parser'
          ? 1.0
          : (isDegradedFallback ? 0.3 : 0.8),
      warnings: isDegradedFallback
          ? const ['AI parsing was unavailable — this was extracted with basic pattern matching, not the language model. Double-check the amount, description, and category before confirming.']
          : const [],
      rawResponse: providerResult.rawResponse,
      parsedData: providerResult.parsedPayload,
    );
  }
}