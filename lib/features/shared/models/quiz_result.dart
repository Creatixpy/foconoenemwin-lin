class QuizQuestion {
  const QuizQuestion({
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

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as String? ?? 'sem-id',
      disciplina: map['disciplina'] as String? ?? 'Geral',
      enunciado: map['enunciado'] as String? ?? '',
      alternativas: (map['alternativas'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      respostaCorreta: map['resposta_correta']?.toString() ?? '',
      explicacao: map['explicacao'] as String?,
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

class QuizResult {
  const QuizResult({
    required this.id,
    required this.userId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.unansweredQuestions,
    required this.score,
    required this.disciplines,
    required this.questions,
    required this.answersData,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int unansweredQuestions;
  final int score;
  final List<String> disciplines;
  final List<QuizQuestion> questions;
  final Map<String, dynamic> answersData;
  final DateTime createdAt;

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      totalQuestions: (map['total_questions'] as num?)?.toInt() ?? 0,
      correctAnswers: (map['correct_answers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (map['wrong_answers'] as num?)?.toInt() ?? 0,
      unansweredQuestions:
          (map['unanswered_questions'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toInt() ?? 0,
      disciplines: (map['disciplines'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      questions: (map['questions_data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestion.fromMap)
          .toList(),
      answersData:
          (map['answers_data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
