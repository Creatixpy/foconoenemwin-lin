class CommunityTopic {
  const CommunityTopic({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
  });

  final String id;
  final String slug;
  final String title;
  final String description;

  factory CommunityTopic.fromMap(Map<String, dynamic> map) {
    return CommunityTopic(
      id: map['id'] as String,
      slug: map['slug'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}
