import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/essay_result.dart';
import '../../shared/models/quiz_result.dart';
import '../../redacao/data/essay_repository.dart';
import '../../questoes/data/quiz_repository.dart';

final essayResultProvider =
    FutureProvider.family<EssayResult, String>((ref, id) async {
  final repository = ref.watch(essayRepositoryProvider);
  return repository.fetchEssayById(id);
});

final quizResultProvider =
    FutureProvider.family<QuizResult, String>((ref, id) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.buscarResultado(id);
});
