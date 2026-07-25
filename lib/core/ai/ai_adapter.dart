import 'ai_result.dart';
import 'inference_result.dart';

abstract class AIAdapter<T> {
  AIResult<T> adapt(InferenceResult<T> providerResult);
}
