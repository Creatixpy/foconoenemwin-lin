import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider = Provider<AppConfig>((_) {
  throw UnimplementedError('AppConfig must be overridden in bootstrap');
});

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
    required this.groqApiKey,
    required this.groqModel,
    required this.worldTimeApiUrl,
    this.groqFallbackApiKey,
    this.groqFallbackModel,
    this.newsApiKey,
    this.rapidApiKey,
    this.stripeSecretKey,
    this.adminCronSecret,
    this.adminAllowedEmails,
    this.supabaseServiceRoleKey,
    this.githubRepo,
    this.groqMaxAttempts = 2,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;
  final String groqApiKey;
  final String groqModel;
  final String worldTimeApiUrl;
  final String? groqFallbackApiKey;
  final String? groqFallbackModel;
  final int groqMaxAttempts;
  final String? newsApiKey;
  final String? rapidApiKey;
  final String? stripeSecretKey;
  final String? adminCronSecret;
  final String? adminAllowedEmails;
  final String? supabaseServiceRoleKey;
  final String? githubRepo;

  static AppConfig fromEnv() {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const groqApiKey = String.fromEnvironment('GROQ_API_KEY');
    const groqModel =
        String.fromEnvironment('GROQ_MODEL', defaultValue: 'llama-3.1-70b-versatile');
    const groqFallbackApiKeyRaw =
        String.fromEnvironment('GROQ_FALLBACK_API_KEY');
    const groqFallbackModelRaw =
        String.fromEnvironment('GROQ_FALLBACK_MODEL');
    const groqMaxAttemptsStr =
        String.fromEnvironment('GROQ_MAX_ATTEMPTS', defaultValue: '2');
    const worldTimeApiUrl = String.fromEnvironment(
      'WORLD_TIME_API_URL',
      defaultValue: 'https://worldtimeapi.org/api/timezone/America/Sao_Paulo',
    );
    const newsApiKeyRaw = String.fromEnvironment('NEWSAPI_API_KEY');
    const rapidApiKeyRaw = String.fromEnvironment('RAPIDAPI_KEY');
    const stripeSecretKeyRaw = String.fromEnvironment('STRIPE_SECRET_KEY');
    const adminCronSecretRaw = String.fromEnvironment('ADMIN_CRON_SECRET');
    const adminAllowedEmailsRaw =
        String.fromEnvironment('ADMIN_ALLOWED_EMAILS');
    const supabaseServiceRoleKeyRaw =
        String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    const githubRepoRaw = String.fromEnvironment('GITHUB_REPO');

    final groqMaxAttempts =
        int.tryParse(groqMaxAttemptsStr) ?? 2;
    final groqFallbackApiKey =
        groqFallbackApiKeyRaw.isEmpty ? null : groqFallbackApiKeyRaw;
    final groqFallbackModel =
        groqFallbackModelRaw.isEmpty ? null : groqFallbackModelRaw;
    final newsApiKey = newsApiKeyRaw.isEmpty ? null : newsApiKeyRaw;
    final rapidApiKey = rapidApiKeyRaw.isEmpty ? null : rapidApiKeyRaw;
    final stripeSecretKey =
        stripeSecretKeyRaw.isEmpty ? null : stripeSecretKeyRaw;
    final adminCronSecret =
        adminCronSecretRaw.isEmpty ? null : adminCronSecretRaw;
    final adminAllowedEmails =
        adminAllowedEmailsRaw.isEmpty ? null : adminAllowedEmailsRaw;
    final supabaseServiceRoleKey =
        supabaseServiceRoleKeyRaw.isEmpty ? null : supabaseServiceRoleKeyRaw;
    final githubRepo = githubRepoRaw.isEmpty ? null : githubRepoRaw;

    void ensure(String value, String key) {
      if (value.isEmpty) {
        throw FlutterError(
          'Missing $key. Provide it via --dart-define or env.dev.json.',
        );
      }
    }

    ensure(supabaseUrl, 'SUPABASE_URL');
    ensure(supabaseAnonKey, 'SUPABASE_ANON_KEY');
    ensure(apiBaseUrl, 'API_BASE_URL');
    ensure(groqApiKey, 'GROQ_API_KEY');

    return AppConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      apiBaseUrl: apiBaseUrl,
      groqApiKey: groqApiKey,
      groqModel: groqModel,
      worldTimeApiUrl: worldTimeApiUrl,
      groqFallbackApiKey: groqFallbackApiKey,
      groqFallbackModel: groqFallbackModel,
      groqMaxAttempts: groqMaxAttempts,
      newsApiKey: newsApiKey,
      rapidApiKey: rapidApiKey,
      stripeSecretKey: stripeSecretKey,
      adminCronSecret: adminCronSecret,
      adminAllowedEmails: adminAllowedEmails,
      supabaseServiceRoleKey: supabaseServiceRoleKey,
      githubRepo: githubRepo,
    );
  }
}
