import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/quiz_result.dart' as models;
import '../data/quiz_repository.dart';

final quizControllerProvider =
    StateNotifierProvider<QuizController, AsyncValue<List<models.QuizQuestion>?>>(
        (ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return QuizController(repository);
});

class QuizController
    extends StateNotifier<AsyncValue<List<models.QuizQuestion>?>> {
  QuizController(this._repository) : super(const AsyncData(null));

  final QuizRepository _repository;

  Future<List<models.QuizQuestion>> gerar({
    required List<String> disciplinas,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _repository.gerarQuestoes(
        disciplinas: disciplinas,
      ),
    );
    state = result;
    return result.value ?? const [];
  }

  Future<models.QuizResult> salvar({
    required List<models.QuizQuestion> questions,
    required Map<String, String> respostas,
  }) {
    return _repository.salvarResultado(
      questions: questions,
      respostas: respostas,
    );
  }
}
