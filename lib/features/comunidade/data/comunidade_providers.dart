import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../shared/models/community_comment.dart';
import '../../shared/models/community_post.dart';
import '../../shared/models/community_topic.dart';

final communityTopicsProvider = FutureProvider<List<CommunityTopic>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final List<dynamic> data =
      await client.from('community_topics').select().order('title');
  return data
      .map<CommunityTopic>((row) => CommunityTopic.fromMap(row as Map<String, dynamic>))
      .toList();
});

final communityPostsProvider =
    FutureProvider<List<CommunityPost>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final List<dynamic> data = await client
      .from('community_posts')
      .select('*, likes:community_post_likes(count), comments:community_comments(count)')
      .order('last_activity_at', ascending: false)
      .limit(25);

  return data.map<CommunityPost>((rowData) {
    final row =
        Map<String, dynamic>.from(rowData as Map<String, dynamic>);
    int countFromKey(String key) {
      final list = row[key];
      if (list is List && list.isNotEmpty) {
        final first = list.first;
        if (first is Map<String, dynamic>) {
          return (first['count'] as num?)?.toInt() ?? 0;
        }
      }
      return 0;
    }

    final likeCount = countFromKey('likes');
    final commentCount = countFromKey('comments');
    return CommunityPost.fromMap({
      ...row,
      'like_count': likeCount,
      'comment_count': commentCount,
    });
  }).toList();
});

final communityCommentsProvider =
    FutureProvider.family<List<CommunityComment>, String>((ref, postId) async {
  final client = ref.watch(supabaseClientProvider);
  final List<dynamic> data = await client
      .from('community_comments')
      .select()
      .eq('post_id', postId)
      .order('created_at');

  return data
      .map<CommunityComment>((row) => CommunityComment.fromMap(row as Map<String, dynamic>))
      .toList();
});
