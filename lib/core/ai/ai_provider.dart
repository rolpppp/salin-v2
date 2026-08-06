import 'inference_result.dart';
import 'parsed_transaction.dart';

abstract class AIProvider {
  String get name;
  Future<InferenceResult<List<ParsedTransaction>>> parseTransaction(String input);
}
