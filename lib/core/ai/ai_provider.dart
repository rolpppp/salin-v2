import 'inference_result.dart';
import 'parsed_transaction.dart';

abstract class AIProvider {
  String get name;
  Future<InferenceResult<ParsedTransaction>> parseTransaction(String input);
}
