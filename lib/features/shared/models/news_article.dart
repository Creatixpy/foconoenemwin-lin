class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.slug,
    required this.publishedAt,
    required this.tags,
    this.imageUrl,
    this.author,
    this.sourceUrl,
    this.isHighlight = false,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final String slug;
  final DateTime publishedAt;
  final List<String> tags;
  final String? imageUrl;
  final String? author;
  final String? sourceUrl;
  final bool isHighlight;

  factory NewsArticle.fromMap(Map<String, dynamic> map) {
    return NewsArticle(
      id: map['id'] as String,
      title: map['titulo'] as String? ?? '',
      summary: map['resumo'] as String? ?? '',
      content: map['conteudo'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      publishedAt: DateTime.parse(map['data_publicacao'] as String),
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      imageUrl: map['imagem_url'] as String?,
      author: map['autor'] as String?,
      sourceUrl: map['fonte_url'] as String?,
      isHighlight: map['destaque'] as bool? ?? false,
    );
  }
}
