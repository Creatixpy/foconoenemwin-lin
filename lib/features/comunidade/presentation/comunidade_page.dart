import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/async_value_widget.dart';
import '../../shared/widgets/section_header.dart';
import '../data/comunidade_providers.dart';

class ComunidadePage extends ConsumerWidget {
  const ComunidadePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(communityTopicsProvider);
    final posts = ref.watch(communityPostsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Comunidade Foco no ENEM',
            subtitle: 'Atualizações em tempo real via Supabase Realtime/SSE',
          ),
          const SizedBox(height: 16),
          AsyncValueWidget(
            value: topics,
            data: (items) {
              if (items.isEmpty) return const Text('Sem tópicos cadastrados.');
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final topic in items)
                    Chip(
                      label: Text(topic.title),
                      avatar: const Icon(Icons.tag, size: 16),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          AsyncValueWidget(
            value: posts,
            data: (items) {
              if (items.isEmpty) return const Text('Nenhum post ainda.');
              final df = DateFormat('dd/MM HH:mm');
              return Column(
                children: [
                  for (final post in items)
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(post.title),
                        subtitle: Text(
                          '${post.status} · ${df.format(post.lastActivityAt ?? post.createdAt)}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.content),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.favorite_border,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text('${post.likeCount} curtidas'),
                                    const SizedBox(width: 16),
                                    Icon(Icons.mode_comment_outlined,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text('${post.commentCount} comentários'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _Comentarios(postId: post.id),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Comentarios extends ConsumerWidget {
  const _Comentarios({required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(communityCommentsProvider(postId));
    final df = DateFormat('dd/MM HH:mm');
    return AsyncValueWidget(
      value: comments,
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Ainda sem comentários.'),
          );
        }
        return Column(
          children: [
            for (final comment in items)
              ListTile(
                title: Text(comment.content),
                subtitle: Text(df.format(comment.createdAt)),
              ),
          ],
        );
      },
    );
  }
}
