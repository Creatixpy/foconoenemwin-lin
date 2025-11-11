class UserStatistics {
  const UserStatistics({
    required this.totalRedacoes,
    required this.mediaNotaRedacao,
    required this.melhorNota,
    required this.piorNota,
    required this.totalSimulados,
    required this.totalQuestoes,
    required this.totalAcertos,
    required this.totalErros,
    required this.taxaAcerto,
    required this.mediaCompetencia1,
    required this.mediaCompetencia2,
    required this.mediaCompetencia3,
    required this.mediaCompetencia4,
    required this.mediaCompetencia5,
    required this.acertosMatematica,
    required this.totalMatematica,
    required this.acertosPortugues,
    required this.totalPortugues,
    required this.acertosQuimica,
    required this.totalQuimica,
    required this.acertosFisica,
    required this.totalFisica,
    required this.acertosGeografia,
    required this.totalGeografia,
  });

  final int totalRedacoes;
  final double? mediaNotaRedacao;
  final int? melhorNota;
  final int? piorNota;
  final int totalSimulados;
  final int totalQuestoes;
  final int totalAcertos;
  final int totalErros;
  final double? taxaAcerto;
  final double? mediaCompetencia1;
  final double? mediaCompetencia2;
  final double? mediaCompetencia3;
  final double? mediaCompetencia4;
  final double? mediaCompetencia5;
  final int acertosMatematica;
  final int totalMatematica;
  final int acertosPortugues;
  final int totalPortugues;
  final int acertosQuimica;
  final int totalQuimica;
  final int acertosFisica;
  final int totalFisica;
  final int acertosGeografia;
  final int totalGeografia;

  factory UserStatistics.fromMap(Map<String, dynamic> map) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return UserStatistics(
      totalRedacoes: (map['total_redacoes'] as int?) ?? 0,
      mediaNotaRedacao: toDouble(map['media_nota_redacao']),
      melhorNota: map['melhor_nota_redacao'] as int?,
      piorNota: map['pior_nota_redacao'] as int?,
      totalSimulados: (map['total_simulados'] as int?) ?? 0,
      totalQuestoes: (map['total_questoes_respondidas'] as int?) ?? 0,
      totalAcertos: (map['total_acertos'] as int?) ?? 0,
      totalErros: (map['total_erros'] as int?) ?? 0,
      taxaAcerto: toDouble(map['taxa_acerto']),
      mediaCompetencia1: toDouble(map['media_competencia1']),
      mediaCompetencia2: toDouble(map['media_competencia2']),
      mediaCompetencia3: toDouble(map['media_competencia3']),
      mediaCompetencia4: toDouble(map['media_competencia4']),
      mediaCompetencia5: toDouble(map['media_competencia5']),
      acertosMatematica: (map['acertos_matematica'] as int?) ?? 0,
      totalMatematica: (map['total_matematica'] as int?) ?? 0,
      acertosPortugues: (map['acertos_portugues'] as int?) ?? 0,
      totalPortugues: (map['total_portugues'] as int?) ?? 0,
      acertosQuimica: (map['acertos_quimica'] as int?) ?? 0,
      totalQuimica: (map['total_quimica'] as int?) ?? 0,
      acertosFisica: (map['acertos_fisica'] as int?) ?? 0,
      totalFisica: (map['total_fisica'] as int?) ?? 0,
      acertosGeografia: (map['acertos_geografia'] as int?) ?? 0,
      totalGeografia: (map['total_geografia'] as int?) ?? 0,
    );
  }
}
