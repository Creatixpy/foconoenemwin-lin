import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../shared/models/essay_result.dart';
import '../../shared/models/quiz_result.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/user_statistics.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  if (session == null) return null;

  final data = await client
      .from('user_profiles')
      .select()
      .eq('user_id', session.user.id)
      .maybeSingle();
  if (data == null) return null;
  return UserProfile.fromMap(data);
});

final userStatisticsProvider = FutureProvider<UserStatistics?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  if (session == null) return null;

  final data = await client
      .from('user_statistics')
      .select()
      .eq('user_id', session.user.id)
      .maybeSingle();
  if (data == null) return null;
  return UserStatistics.fromMap(data);
});

final recentEssayResultsProvider =
    FutureProvider<List<EssayResult>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  if (session == null) return const [];

  final data = await client
      .from('essay_results')
      .select()
      .eq('user_id', session.user.id)
      .order('created_at', ascending: false)
      .limit(10);

  return data.map<EssayResult>((row) => EssayResult.fromMap(row)).toList();
});

final recentQuizResultsProvider = FutureProvider<List<QuizResult>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  if (session == null) return const [];

  final data = await client
      .from('quiz_results')
      .select()
      .eq('user_id', session.user.id)
      .order('created_at', ascending: false)
      .limit(10);

  return data.map<QuizResult>((row) => QuizResult.fromMap(row)).toList();
});
