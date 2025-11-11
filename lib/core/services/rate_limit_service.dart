import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_providers.dart';

final rateLimitServiceProvider = Provider<RateLimitService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RateLimitService(client);
});

class RateLimitService {
  RateLimitService(this._client);
  final SupabaseClient _client;

  Future<void> ensureWithinLimit({
    required String identifier,
    required String endpoint,
    required int maxRequests,
    required Duration window,
  }) async {
    final now = DateTime.now().toUtc();
    final record = await _client
        .from('rate_limits')
        .select()
        .eq('identifier', identifier)
        .eq('endpoint', endpoint)
        .maybeSingle();

    if (record == null) {
      await _client.from('rate_limits').insert({
        'identifier': identifier,
        'endpoint': endpoint,
        'request_count': 1,
        'window_start': now.toIso8601String(),
      });
      return;
    }

    final data = Map<String, dynamic>.from(record as Map);
    final windowStart =
        DateTime.parse(data['window_start'] as String).toUtc();
    final count = (data['request_count'] as num?)?.toInt() ?? 0;

    if (now.difference(windowStart) > window) {
      await _client
          .from('rate_limits')
          .update({
            'request_count': 1,
            'window_start': now.toIso8601String(),
          })
          .eq('id', data['id']);
      return;
    }

    if (count >= maxRequests) {
      throw RateLimitException(timeRemaining: window - now.difference(windowStart));
    }

    await _client
        .from('rate_limits')
        .update({
          'request_count': count + 1,
        })
        .eq('id', data['id']);
  }
}

class RateLimitException implements Exception {
  RateLimitException({required this.timeRemaining});
  final Duration timeRemaining;

  @override
  String toString() =>
      'Limite atingido. Tente novamente em ${timeRemaining.inMinutes} min.';
}
