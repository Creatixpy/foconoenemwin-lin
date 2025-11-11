import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';

final profileFormControllerProvider =
    StateNotifierProvider<ProfileFormController, AsyncValue<void>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileFormController(repository);
});

class ProfileFormController extends StateNotifier<AsyncValue<void>> {
  ProfileFormController(this._repository) : super(const AsyncData(null));

  final ProfileRepository _repository;

  Future<void> salvar({
    required String nomeCompleto,
    String? bio,
    String? objetivo,
    int? anoEnem,
    String? communityTagline,
    String? communityTheme,
    bool showStatistics = true,
    bool acceptedCommunityTerms = false,
    bool confirmedAge = false,
    String? termsVersion,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.upsertProfile(
        nomeCompleto: nomeCompleto,
        bio: bio,
        objetivo: objetivo,
        anoEnem: anoEnem,
        communityTagline: communityTagline,
        communityTheme: communityTheme,
        showStatistics: showStatistics,
        acceptedCommunityTerms: acceptedCommunityTerms,
        confirmedAge: confirmedAge,
        termsVersion: termsVersion,
      ),
    );
  }
}
