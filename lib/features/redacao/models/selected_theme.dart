class SelectedTheme {
  const SelectedTheme({
    required this.id,
    required this.tema,
    this.textoApoio1,
    this.textoApoio2,
    this.usadoCount,
    this.createdAt,
  });

  final String id;
  final String tema;
  final String? textoApoio1;
  final String? textoApoio2;
  final int? usadoCount;
  final DateTime? createdAt;

  factory SelectedTheme.fromMap(Map<String, dynamic> map) {
    return SelectedTheme(
      id: map['id'] as String,
      tema: map['tema'] as String? ?? '',
      textoApoio1: map['texto_apoio1'] as String?,
      textoApoio2: map['texto_apoio2'] as String?,
      usadoCount: (map['usado_count'] as num?)?.toInt(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
