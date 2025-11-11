class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.topicId,
    required this.userId,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  final String id;
  final String topicId;
  final String userId;
  final String title;
  final String content;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;
  final int likeCount;
  final int commentCount;

  factory CommunityPost.fromMap(Map<String, dynamic> map) {
    return CommunityPost(
      id: map['id'] as String,
      topicId: map['topic_id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastActivityAt: map['last_activity_at'] != null
          ? DateTime.parse(map['last_activity_at'] as String)
          : null,
      likeCount: (map['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (map['comment_count'] as num?)?.toInt() ?? 0,
    );
  }
}
