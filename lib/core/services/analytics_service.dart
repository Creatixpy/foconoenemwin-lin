import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_providers.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AnalyticsService(client);
});

class AnalyticsService {
  AnalyticsService(this._client);
  final SupabaseClient _client;

  Future<void> track(
    String eventType, {
    Map<String, dynamic>? metadata,
    String? userId,
  }) async {
    try {
      await _client.from('analytics_events').insert({
        'event_type': eventType,
        'metadata': metadata ?? const <String, dynamic>{},
        'user_id': userId,
      });
    } catch (error, stack) {
      debugPrint('Analytics tracking failed: $error\n$stack');
    }
  }
}
