import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/essay_result.dart';
import '../data/essay_repository.dart';
import '../data/theme_repository.dart';
import '../domain/tema_tipo.dart';
import '../models/selected_theme.dart';

final cachedThemesProvider = FutureProvider<List<SelectedTheme>>((ref) async {
  final repository = ref.watch(themeRepositoryProvider);
  return repository.fetchLatestThemes();
});

final redacaoControllerProvider =
    StateNotifierProvider<RedacaoController, AsyncValue<EssayResult?>>((ref) {
  final repository = ref.watch(essayRepositoryProvider);
  return RedacaoController(repository);
});

class RedacaoController extends StateNotifier<AsyncValue<EssayResult?>> {
  RedacaoController(this._repository) : super(const AsyncData(null));

  final EssayRepository _repository;

  Future<void> enviar({
    required String texto,
    required TemaTipo tipo,
    SelectedTheme? temaSelecionado,
    String? temaCustom,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.submitEssay(
          texto: texto,
          temaTipo: tipo,
          temaSelecionado: temaSelecionado,
          customTema: temaCustom,
        ));
  }
}
