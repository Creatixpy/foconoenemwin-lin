import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/rate_limit_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../shared/models/essay_result.dart';
import '../domain/tema_tipo.dart';
import '../models/selected_theme.dart';

const _defaultThemeTitle =
    'Os desafios da educação digital no Brasil contemporâneo';
const _defaultSupportText1 =
    'Segundo dados do IBGE, em 2021, 85% dos domicílios brasileiros possuíam acesso à internet, porém com grande disparidade regional e socioeconômica. Nas regiões Norte e Nordeste, e em famílias de baixa renda, o acesso é significativamente menor.';
const _defaultSupportText2 =
    'A pandemia de COVID-19 evidenciou a necessidade de integração digital no ensino, mas também mostrou que muitos estudantes e professores não estão preparados para o uso efetivo das tecnologias educacionais.';
const _minEssayLength = 50;
const _maxEssayLength = 5000;

final essayRepositoryProvider = Provider<EssayRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  final groq = ref.watch(groqServiceProvider);
  final schedule = ref.watch(scheduleServiceProvider);
  final rateLimiter = ref.watch(rateLimitServiceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return EssayRepository(
    client: client,
    groqService: groq,
    scheduleService: schedule,
    rateLimitService: rateLimiter,
    analyticsService: analytics,
    sessionUserId: session?.user.id,
  );
});

class EssayRepository {
  EssayRepository({
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

  Future<EssayResult> submitEssay({
    required String texto,
    required TemaTipo temaTipo,
    SelectedTheme? temaSelecionado,
    String? customTema,
  }) async {
    final userId = sessionUserId;
    if (userId == null) {
      throw StateError('Usuário não autenticado.');
    }

    final trimmedEssay = texto.trim();
    if (trimmedEssay.length < _minEssayLength) {
      throw StateError('A redação deve ter pelo menos $_minEssayLength caracteres.');
    }
    if (trimmedEssay.length > _maxEssayLength) {
      throw StateError('A redação deve ter no máximo $_maxEssayLength caracteres.');
    }

    await scheduleService.ensureOperatingHours();
    await rateLimitService.ensureWithinLimit(
      identifier: userId,
      endpoint: 'essay_correction',
      maxRequests: 3,
      window: const Duration(hours: 2),
    );

    final SelectedTheme resolvedTheme = _resolveTema(
      tipo: temaTipo,
      temaSelecionado: temaSelecionado,
      customTema: customTema,
    );

    final aligned = await groqService.validateThemeAlignment(
      tema: resolvedTheme.tema,
      texto: trimmedEssay,
    );
    if (!aligned) {
      await analyticsService.track(
        'essay_rejected_theme',
        metadata: {
          'theme_type': temaTipo.name,
          'tema': resolvedTheme.tema,
        },
        userId: userId,
      );
      throw StateError(
        'A redação não parece alinhada ao tema informado. Ajuste antes de enviar.',
      );
    }

    final correction = await groqService.correctEssay(
      tema: resolvedTheme.tema,
      texto: trimmedEssay,
      textoApoio1: resolvedTheme.textoApoio1,
      textoApoio2: resolvedTheme.textoApoio2,
    );

    final insertPayload = _buildInsertPayload(
      userId: userId,
      texto: trimmedEssay,
      tema: resolvedTheme.tema,
      correction: correction,
      temaSelecionado: resolvedTheme.id == 'default' ? null : resolvedTheme,
    );

    final inserted = await client
        .from('essay_results')
        .insert(insertPayload)
        .select()
        .single();

    await analyticsService.track(
      'essay_submitted',
      metadata: {
        'tema': resolvedTheme.tema,
        'nota_final': correction.notaFinal,
        if (temaTipo == TemaTipo.ia)
          'theme_source': 'ia'
        else if (temaTipo == TemaTipo.sugerido)
          'theme_source': 'default'
        else
          'theme_source': 'custom',
        if (correction.provider != null) 'provider': correction.provider,
      },
      userId: userId,
    );

    return EssayResult.fromMap(inserted);
  }

  Future<EssayResult> fetchEssayById(String id) async {
    final record = await client
        .from('essay_results')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (record == null) {
      throw StateError('Resultado não encontrado.');
    }
    return EssayResult.fromMap(record);
  }

  SelectedTheme _resolveTema({
    required TemaTipo tipo,
    SelectedTheme? temaSelecionado,
    String? customTema,
  }) {
    switch (tipo) {
      case TemaTipo.sugerido:
        return SelectedTheme(
          id: 'default',
          tema: _defaultThemeTitle,
          textoApoio1: _defaultSupportText1,
          textoApoio2: _defaultSupportText2,
          usadoCount: 0,
        );
      case TemaTipo.ia:
        final theme = temaSelecionado;
        if (theme == null) {
          throw StateError('Selecione um tema gerado com IA antes de enviar.');
        }
        return theme;
      case TemaTipo.personalizado:
        final value = customTema?.trim();
        if (value == null || value.length < 5) {
          throw StateError('Informe um tema personalizado válido.');
        }
        return SelectedTheme(
          id: 'custom',
          tema: value,
          textoApoio1: null,
          textoApoio2: null,
          usadoCount: 0,
        );
    }
  }

  Map<String, dynamic> _buildInsertPayload({
    required String userId,
    required String texto,
    required String tema,
    required GroqCorrection correction,
    SelectedTheme? temaSelecionado,
  }) {
    Map<String, dynamic> competenciaJson(int numero) {
      final comp = correction.competencias.firstWhere(
        (element) => element.numero == numero,
        orElse: () => GroqCompetencia(
          numero: numero,
          nota: 0,
          feedback: 'Sem feedback',
          destaques: const [],
        ),
      );
      return comp.toJson();
    }

    return {
      'user_id': userId,
      'nota': correction.notaFinal,
      'competencia1': competenciaJson(1),
      'competencia2': competenciaJson(2),
      'competencia3': competenciaJson(3),
      'competencia4': competenciaJson(4),
      'competencia5': competenciaJson(5),
      'feedback_geral': correction.feedbackGeral,
      'ponto_fortes': correction.pontosFortes,
      'pontos_a_melhorar': correction.pontosMelhorar,
      'redacao_original': texto,
      'tema': tema,
      'texto_apoio1': temaSelecionado?.textoApoio1,
      'texto_apoio2': temaSelecionado?.textoApoio2,
      'origem': 'flutter_app',
    };
  }
}
