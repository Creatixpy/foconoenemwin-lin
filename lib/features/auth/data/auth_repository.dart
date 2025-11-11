import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

const _oauthRedirectUri = 'io.supabase.flutter://callback';

class AuthRepository {
  const AuthRepository(this._client);
  final SupabaseClient _client;

  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> sendMagicLink(String email) {
    return _client.auth.signInWithOtp(email: email, data: {'channel': 'desktop'});
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _oauthRedirectUri,
    );
  }
}
