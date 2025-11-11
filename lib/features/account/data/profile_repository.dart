import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  return ProfileRepository(client, session?.user.id);
});

class ProfileRepository {
  ProfileRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String? _userId;

  Future<Map<String, dynamic>?> fetchProfile() async {
    if (_userId == null) return null;
    final data = await _client
        .from('user_profiles')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();
    return data;
  }

  Future<void> upsertProfile({
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
    final userId = _userId;
    if (userId == null) {
      throw StateError('Usuário não autenticado.');
    }

    final payload = {
      'user_id': userId,
      'nome_completo': nomeCompleto,
      'bio': bio,
      'objetivo': objetivo,
      'ano_enem': anoEnem,
      'community_tagline': communityTagline,
      'community_profile_theme': communityTheme,
      'community_show_statistics': showStatistics,
      if (acceptedCommunityTerms)
        'community_terms_accepted_at': DateTime.now().toIso8601String(),
      if (confirmedAge) 'community_age_confirmed_at': DateTime.now().toIso8601String(),
      if (termsVersion != null) 'community_terms_version': termsVersion,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('user_profiles').upsert(payload);
  }
}
