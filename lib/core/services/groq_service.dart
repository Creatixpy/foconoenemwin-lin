import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';

final groqServiceProvider = Provider<GroqService>((ref) {
  final config = ref.watch(appConfigProvider);
  return GroqService(
    primaryKey: config.groqApiKey,
    primaryModel: config.groqModel,
    fallbackKey: config.groqFallbackApiKey,
    fallbackModel: config.groqFallbackModel,
    maxAttempts: config.groqMaxAttempts,
  );
});

class GroqService {
  GroqService({
    required String primaryKey,
    required String primaryModel,
    String? fallbackKey,
    String? fallbackModel,
    int maxAttempts = 2,
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _maxAttempts = maxAttempts,
        _providers = [
          _GroqProvider(
            apiKey: primaryKey,
            model: primaryModel,
            label: 'primary',
          ),
          if (fallbackKey != null && fallbackKey.isNotEmpty)
            _GroqProvider(
              apiKey: fallbackKey,
              model: (fallbackModel?.isNotEmpty ?? false)
                  ? fallbackModel!
                  : primaryModel,
              label: 'fallback',
            ),
        ];

  final http.Client _httpClient;
  final List<_GroqProvider> _providers;
  final int _maxAttempts;

  static const _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<_GroqCallResult<Map<String, dynamic>>> _chatCompletionDetailed(
    List<Map<String, String>> messages, {
    double temperature = 0.2,
    int maxTokens = 2048,
    bool forceJson = true,
  }) {
    return _executeWithFallback<Map<String, dynamic>>((provider) async {
      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${provider.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': provider.model,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'messages': messages,
          if (forceJson) 'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode >= 400) {
        throw GroqException(
          'Groq ${provider.label} (${response.statusCode}): ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? const [];
      if (choices.isEmpty) {
        throw GroqException('Groq ${provider.label} respondeu sem conteúdo.');
      }

      final content = choices.first['message']?['content'];
      if (content is! String || content.trim().isEmpty) {
        throw GroqException('Groq ${provider.label} retornou conteúdo vazio.');
      }

      final sanitized = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final result = jsonDecode(sanitized);
      if (result is! Map<String, dynamic>) {
        throw GroqException('Groq ${provider.label} retornou formato inesperado.');
      }
      return result;
    });
  }

  Future<Map<String, dynamic>> _chatCompletion(
    List<Map<String, String>> messages, {
    double temperature = 0.2,
    int maxTokens = 2048,
    bool forceJson = true,
  }) async {
    final call = await _chatCompletionDetailed(
      messages,
      temperature: temperature,
      maxTokens: maxTokens,
      forceJson: forceJson,
    );
    return call.data;
  }

  Future<_GroqCallResult<T>> _executeWithFallback<T>(
    Future<T> Function(_GroqProvider provider) task,
  ) async {
    final errors = <String>[];
    for (final provider in _providers) {
      for (var attempt = 0; attempt < _maxAttempts; attempt++) {
        try {
          final data = await task(provider);
          return _GroqCallResult(data: data, provider: provider);
        } catch (error) {
          errors.add('[${provider.label} tentativa ${attempt + 1}] $error');
        }
      }
    }
    throw GroqException(
      'Todas as tentativas Groq falharam: ${errors.join(' | ')}',
    );
  }

  Future<GroqTheme> generateTheme() async {
    final response = await _chatCompletionDetailed(
      [
        const {
          'role': 'system',
          'content':
              'Você gera temas originais de redação do ENEM. '
                  'Retorne JSON com campos: tema, texto_apoio1, texto_apoio2, foco.',
        },
        const {
          'role': 'user',
          'content':
              'Crie um tema inédito e dois textos de apoio concisos em português.',
        },
      ],
      maxTokens: 600,
    );

    final map = response.data;
    return GroqTheme(
      tema: map['tema'] as String? ?? 'Tema indisponível',
      textoApoio1: map['texto_apoio1'] as String?,
      textoApoio2: map['texto_apoio2'] as String?,
      foco: map['foco'] as String?,
      provider: response.provider.label,
    );
  }

  Future<bool> validateThemeAlignment({
    required String tema,
    required String texto,
  }) async {
    final response = await _chatCompletion(
      [
        const {
          'role': 'system',
          'content':
              'Você é um verificador que responde somente JSON com aligned (bool) e reason (string).',
        },
        {
          'role': 'user',
          'content':
              'Tema: $tema\n\nRedação:\n$texto',
        },
      ],
      maxTokens: 200,
    );

    return response['aligned'] == true;
  }

  Future<GroqCorrection> correctEssay({
    required String tema,
    required String texto,
    String? textoApoio1,
    String? textoApoio2,
  }) async {
    final support = [
      if (textoApoio1 != null) textoApoio1,
      if (textoApoio2 != null) textoApoio2,
    ].join('\n---\n');

    final response = await _chatCompletionDetailed(
      [
        const {
          'role': 'system',
          'content':
              'Você é um corretor oficial do ENEM. '
              'Responda JSON com nota_final (0-1000), '
              'competencias (lista com numero, nota, feedback, destaques), '
              'pontos_fortes, pontos_melhorar, feedback_geral.',
        },
        {
          'role': 'user',
          'content':
              'Tema oficial: $tema\n\n'
              'Textos de apoio:\n$support\n\n'
              'Redação do estudante:\n$texto',
        },
      ],
      maxTokens: 1200,
    );

    final map = response.data;
    final correction = GroqCorrection.fromMap(map);
    return correction.copyWith(provider: response.provider.label);
  }

  Future<List<GroqQuizQuestion>> generateQuestionsForDiscipline({
    required String disciplina,
    int quantidade = 3,
  }) async {
    final response = await _chatCompletion(
      [
        const {
          'role': 'system',
          'content':
              'Você é um elaborador de simulados do ENEM. '
              'Responda apenas JSON com questions (array). Cada questão deve conter '
              '{id, enunciado, alternativas: [A,B,C,D], resposta_correta (letra), explicacao}.',
        },
        {
          'role': 'user',
          'content':
              'Disciplina: $disciplina\n'
              'Gere exatamente $quantidade questões inéditas no formato ENEM, com explicação sucinta.',
        },
      ],
      maxTokens: 1500,
    );

    List<dynamic> extractQuestions(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) return raw;
      if (raw is Map) {
        if (raw['questions'] is List) return raw['questions'] as List;
        if (raw['data'] is List) return raw['data'] as List;
        if (raw['items'] is List) return raw['items'] as List;
      }
      return const [];
    }

    final rawList = extractQuestions(
      response['questions'] ??
          response['data'] ??
          response['questoes'] ??
          response,
    );

    final questions = rawList
        .whereType<Map<String, dynamic>>()
        .map((q) => GroqQuizQuestion.fromMap(q, disciplina: disciplina))
        .toList();

    if (questions.length < quantidade) {
      throw GroqException(
        'Groq retornou apenas ${questions.length} questões para $disciplina.',
      );
    }

    return questions;
  }
}

class GroqException implements Exception {
  GroqException(this.message);
  final String message;

  @override
  String toString() => 'GroqException: $message';
}

class GroqTheme {
  const GroqTheme({
    required this.tema,
    this.textoApoio1,
    this.textoApoio2,
    this.foco,
    this.provider,
  });

  final String tema;
  final String? textoApoio1;
  final String? textoApoio2;
  final String? foco;
  final String? provider;
}

class GroqCorrection {
  GroqCorrection({
    required this.notaFinal,
    required this.competencias,
    required this.pontosFortes,
    required this.pontosMelhorar,
    required this.feedbackGeral,
    this.provider,
  });

  final int notaFinal;
  final List<GroqCompetencia> competencias;
  final List<String> pontosFortes;
  final List<String> pontosMelhorar;
  final String feedbackGeral;
  final String? provider;

  factory GroqCorrection.fromMap(Map<String, dynamic> map) {
    List<String> toStringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return const [];
    }

    final competencias = (map['competencias'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GroqCompetencia.fromMap)
        .toList();

    return GroqCorrection(
      notaFinal: (map['nota_final'] as num?)?.toInt() ?? 0,
      competencias: competencias,
      pontosFortes: toStringList(map['pontos_fortes']),
      pontosMelhorar: toStringList(map['pontos_melhorar']),
      feedbackGeral: map['feedback_geral']?.toString() ?? '',
    );
  }

  GroqCorrection copyWith({String? provider}) {
    return GroqCorrection(
      notaFinal: notaFinal,
      competencias: competencias,
      pontosFortes: pontosFortes,
      pontosMelhorar: pontosMelhorar,
      feedbackGeral: feedbackGeral,
      provider: provider ?? this.provider,
    );
  }
}

class GroqCompetencia {
  const GroqCompetencia({
    required this.numero,
    required this.nota,
    required this.feedback,
    required this.destaques,
  });

  final int numero;
  final int nota;
  final String feedback;
  final List<String> destaques;

  factory GroqCompetencia.fromMap(Map<String, dynamic> map) {
    return GroqCompetencia(
      numero: (map['numero'] as num?)?.toInt() ?? 0,
      nota: (map['nota'] as num?)?.toInt() ?? 0,
      feedback: map['feedback']?.toString() ?? '',
      destaques: (map['destaques'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'nota': nota,
        'feedback': feedback,
        'destaques': destaques,
      };
}

class GroqQuizQuestion {
  GroqQuizQuestion({
    required this.id,
    required this.disciplina,
    required this.enunciado,
    required this.alternativas,
    required this.respostaCorreta,
    this.explicacao,
  });

  final String id;
  final String disciplina;
  final String enunciado;
  final List<String> alternativas;
  final String respostaCorreta;
  final String? explicacao;

  factory GroqQuizQuestion.fromMap(
    Map<String, dynamic> map, {
    required String disciplina,
  }) {
    final alternativas = (map['alternativas'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const [];
    if (alternativas.length < 4) {
      throw GroqException('Questão incompleta: alternativas insuficientes.');
    }
    return GroqQuizQuestion(
      id: (map['id']?.toString().isNotEmpty ?? false)
          ? map['id'].toString()
          : 'quiz_${DateTime.now().microsecondsSinceEpoch}',
      disciplina: disciplina,
      enunciado: map['enunciado']?.toString() ?? '',
      alternativas: alternativas,
      respostaCorreta: map['resposta_correta']?.toString() ?? 'A',
      explicacao: map['explicacao']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'disciplina': disciplina,
        'enunciado': enunciado,
        'alternativas': alternativas,
        'resposta_correta': respostaCorreta,
        if (explicacao != null) 'explicacao': explicacao,
      };
}

class _GroqProvider {
  const _GroqProvider({
    required this.apiKey,
    required this.model,
    required this.label,
  });

  final String apiKey;
  final String model;
  final String label;
}

class _GroqCallResult<T> {
  const _GroqCallResult({
    required this.data,
    required this.provider,
  });

  final T data;
  final _GroqProvider provider;
}
