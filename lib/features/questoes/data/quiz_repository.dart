import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/rate_limit_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../shared/models/quiz_result.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  return QuizRepository(
    client: client,
    groqService: ref.watch(groqServiceProvider),
    scheduleService: ref.watch(scheduleServiceProvider),
    rateLimitService: ref.watch(rateLimitServiceProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
    sessionUserId: session?.user.id,
  );
});

class QuizRepository {
  QuizRepository({
    required this.client,
    required this.groqService,
    required this.scheduleService,
    required this.rateLimitService,
    required this.analyticsService,
    required this.sessionUserId,
  });

  final SupabaseClient client;
  final GroqService groqService;
  final ScheduleService scheduleService;
  final RateLimitService rateLimitService;
  final AnalyticsService analyticsService;
  final String? sessionUserId;
  final Uuid _uuid = const Uuid();

  Future<List<QuizQuestion>> gerarQuestoes({
    required List<String> disciplinas,
    int quantidadePorDisciplina = 3,
  }) async {
    if (disciplinas.isEmpty) {
      throw StateError('Escolha ao menos uma disciplina.');
    }

    await scheduleService.ensureOperatingHours();
    final userId = sessionUserId;
    if (userId == null) {
      throw StateError('Faça login para gerar simulados.');
    }

    await rateLimitService.ensureWithinLimit(
      identifier: userId,
      endpoint: 'quiz_generation',
      maxRequests: 3,
      window: const Duration(hours: 1),
    );

    final results = <QuizQuestion>[];
    for (final disciplina in disciplinas) {
      final generated = await groqService.generateQuestionsForDiscipline(
        disciplina: disciplina,
        quantidade: quantidadePorDisciplina,
      );
      results.addAll(
        generated.map(
          (q) => QuizQuestion(
            id: _uuid.v4(),
            disciplina: disciplina,
            enunciado: q.enunciado,
            alternativas: q.alternativas,
            respostaCorreta: q.respostaCorreta,
            explicacao: q.explicacao,
          ),
        ),
      );
    }

    results.shuffle(Random());

    await analyticsService.track(
      'quiz_started',
      metadata: {'disciplinas': disciplinas},
      userId: sessionUserId,
    );

    return results;
  }

  Future<QuizResult> salvarResultado({
    required List<QuizQuestion> questions,
    required Map<String, String> respostas,
  }) async {
    final userId = sessionUserId;
    if (userId == null) {
      throw StateError('Faça login para salvar o resultado do simulado.');
    }

    if (questions.isEmpty) {
      throw StateError('Sem questões para salvar.');
    }

    final total = questions.length;
    final correct = questions
        .where((q) => respostas[q.id]?.toUpperCase() == q.respostaCorreta)
        .length;
    final wrong = total - correct;
    final unanswered = total - respostas.length;
    final score = (correct / total * 1000).round();

    final record = await client
        .from('quiz_results')
        .insert({
          'user_id': userId,
          'total_questions': total,
          'correct_answers': correct,
          'wrong_answers': wrong,
          'unanswered_questions': unanswered,
          'score': score,
          'disciplines':
              questions.map((q) => q.disciplina).toSet().toList(),
          'questions_data':
              questions.map((question) => question.toJson()).toList(),
          'answers_data': respostas,
        })
        .select()
        .single();

    await _triggerStatisticsRefresh(userId);

    await analyticsService.track(
      'quiz_completed',
      metadata: {
        'total': total,
        'correct': correct,
        'score': score,
      },
      userId: userId,
    );

    return QuizResult.fromMap(record);
  }

  Future<void> _triggerStatisticsRefresh(String userId) async {
    try {
      await client.rpc(
        'recalculate_user_statistics',
        params: {'target_user_id': userId},
      );
    } catch (_) {
      // Ignora falhas silenciosamente para não quebrar a experiência.
    }
  }

  Future<QuizResult> buscarResultado(String id) async {
    final record =
        await client.from('quiz_results').select().eq('id', id).maybeSingle();
    if (record == null) throw StateError('Resultado não encontrado');
    return QuizResult.fromMap(record);
  }
}
