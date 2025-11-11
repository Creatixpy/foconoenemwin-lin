import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final sessionChangesStreamProvider = Provider<Stream<Session?>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((event) => event.session);
});

final sessionStreamProvider = StreamProvider<Session?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  yield client.auth.currentSession;
  final stream = ref.watch(sessionChangesStreamProvider);
  yield* stream;
});

final sessionProvider = Provider<Session?>((ref) {
  final sessionAsync = ref.watch(sessionStreamProvider);
  return sessionAsync.maybeWhen(
    data: (session) => session,
    orElse: () => Supabase.instance.client.auth.currentSession,
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyOnError = stream.listen(
      (_) => notifyListeners(),
      onError: (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> notifyOnError;

  @override
  void dispose() {
    notifyOnError.cancel();
    super.dispose();
  }
}
