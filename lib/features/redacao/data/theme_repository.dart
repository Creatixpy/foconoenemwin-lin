import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/rate_limit_service.dart';
import '../../../core/services/schedule_service.dart';
import '../models/selected_theme.dart';

final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  final groq = ref.watch(groqServiceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  final schedule = ref.watch(scheduleServiceProvider);
  final rateLimiter = ref.watch(rateLimitServiceProvider);
  return ThemeRepository(
    client: client,
    groqService: groq,
    analyticsService: analytics,
    scheduleService: schedule,
    rateLimitService: rateLimiter,
    sessionUserId: session?.user.id,
  );
});

class ThemeRepository {
  ThemeRepository({
    required this.client,
    required this.groqService,
    required this.analyticsService,
    required this.scheduleService,
    required this.rateLimitService,
    required this.sessionUserId,
  });

  final SupabaseClient client;
  final GroqService groqService;
  final AnalyticsService analyticsService;
  final ScheduleService scheduleService;
  final RateLimitService rateLimitService;
  final String? sessionUserId;

  Future<List<SelectedTheme>> fetchLatestThemes() async {
    final List<dynamic> data = await client
        .from('cached_themes')
        .select()
        .order('created_at', ascending: false)
        .limit(20);
    return data
        .map((row) => SelectedTheme.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<SelectedTheme> requestTheme() async {
    final userId = sessionUserId;
    if (userId == null) {
      throw StateError('Faça login para gerar temas.');
    }
    await scheduleService.ensureOperatingHours();
    await rateLimitService.ensureWithinLimit(
      identifier: userId,
      endpoint: 'theme_generation',
      maxRequests: 3,
      window: const Duration(minutes: 1),
    );

    final cached = await _findCachedTheme();
    if (cached != null) {
      await _incrementUsage(cached.id, cached.usadoCount ?? 0);
      await analyticsService.track(
        'theme_cached',
        metadata: {
          'tema': cached.tema,
          if (cached.createdAt != null)
            'cache_age_hours': DateTime.now()
                .difference(cached.createdAt!)
                .inHours,
        },
        userId: sessionUserId,
      );
      return cached;
    }

    final generated = await groqService.generateTheme();
    final inserted = await client
        .from('cached_themes')
        .insert({
          'tema': generated.tema,
          'texto_apoio1': generated.textoApoio1,
          'texto_apoio2': generated.textoApoio2,
          'usado_count': 1,
        })
        .select()
        .single();

    final theme =
        SelectedTheme.fromMap(Map<String, dynamic>.from(inserted));

    await analyticsService.track(
      'theme_generated',
      metadata: {'tema': generated.tema, 'provider': generated.provider},
      userId: sessionUserId,
    );

    return theme;
  }

  Future<SelectedTheme?> _findCachedTheme() async {
    final since = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
    final data = await client
        .from('cached_themes')
        .select()
        .gte('created_at', since)
        .order('usado_count', ascending: true)
        .order('created_at', ascending: false)
        .limit(1);

    if (data.isEmpty) return null;
    return SelectedTheme.fromMap(
      Map<String, dynamic>.from(data.first as Map),
    );
  }

  Future<void> _incrementUsage(String themeId, int currentCount) {
    return client
        .from('cached_themes')
        .update({'usado_count': currentCount + 1})
        .eq('id', themeId);
  }
}
