class CompetenciaScore {
  const CompetenciaScore({
    required this.label,
    required this.nota,
    this.feedback,
    this.destaques = const [],
  });

  final String label;
  final int nota;
  final String? feedback;
  final List<String> destaques;

  factory CompetenciaScore.fromMap(String label, Map<String, dynamic> map) {
    return CompetenciaScore(
      label: label,
      nota: (map['nota'] as num?)?.toInt() ?? 0,
      feedback: map['feedback'] as String?,
      destaques: (map['destaques'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
    );
  }
}

class EssayResult {
  const EssayResult({
    required this.id,
    required this.userId,
    required this.score,
    required this.theme,
    required this.originalEssay,
    required this.strengths,
    required this.improvements,
    required this.createdAt,
    required this.competencias,
    this.supportText1,
    this.supportText2,
  });

  final String id;
  final String userId;
  final int score;
  final String theme;
  final String originalEssay;
  final List<String> strengths;
  final List<String> improvements;
  final DateTime createdAt;
  final List<CompetenciaScore> competencias;
  final String? supportText1;
  final String? supportText2;

  factory EssayResult.fromMap(Map<String, dynamic> map) {
    List<CompetenciaScore> parseCompetencias() {
      final keys = ['competencia1', 'competencia2', 'competencia3', 'competencia4', 'competencia5'];
      return keys
          .map((key) {
            final data = map[key];
            if (data is Map<String, dynamic>) {
              return CompetenciaScore.fromMap(key, data);
            }
            return null;
          })
          .whereType<CompetenciaScore>()
          .toList();
    }

    List<String> asStrings(dynamic data) {
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return EssayResult(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      score: (map['nota'] as num?)?.toInt() ?? 0,
      theme: map['tema'] as String? ?? 'Tema indisponível',
      originalEssay: map['redacao_original'] as String? ?? '',
      strengths: asStrings(map['ponto_fortes']),
      improvements: asStrings(map['pontos_a_melhorar']),
      createdAt: DateTime.parse(map['created_at'] as String),
      competencias: parseCompetencias(),
      supportText1: map['texto_apoio1'] as String?,
      supportText2: map['texto_apoio2'] as String?,
    );
  }
}
