class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String postId;
  final String userId;
  final String content;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CommunityComment.fromMap(Map<String, dynamic> map) {
    return CommunityComment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
