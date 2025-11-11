import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/async_value_widget.dart';
import '../../shared/widgets/section_header.dart';
import '../data/noticias_providers.dart';

class NoticiasPage extends ConsumerWidget {
  const NoticiasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticias = ref.watch(noticiasProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SectionHeader(
            title: 'Notícias e destaques',
            subtitle: 'Normalização via NewsAPI + Supabase',
          ),
          const SizedBox(height: 16),
          AsyncValueWidget(
            value: noticias,
            data: (articles) {
              if (articles.isEmpty) {
                return const Text('Nenhum artigo disponível.');
              }
              final df = DateFormat('dd MMM yyyy', 'pt_BR');
              return Column(
                children: [
                  for (final article in articles)
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: article.sourceUrl != null
                            ? () => launchUrl(Uri.parse(article.sourceUrl!))
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (article.imageUrl != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: article.imageUrl!,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const SizedBox(height: 180),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    article.summary,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Text(df.format(article.publishedAt)),
                                      if (article.tags.isNotEmpty)
                                        ...article.tags.map(
                                          (tag) {
                                            final color = Theme.of(context)
                                                .colorScheme
                                                .primaryContainer;
                                            final bg = color.withValues(
                                              alpha: color.a * 0.2,
                                            );
                                            return Chip(
                                              label: Text(tag),
                                              backgroundColor: bg,
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
