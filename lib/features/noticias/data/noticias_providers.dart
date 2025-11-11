import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../shared/models/news_article.dart';

final noticiasProvider = FutureProvider<List<NewsArticle>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('noticias')
      .select()
      .order('data_publicacao', ascending: false)
      .limit(30);

  return data.map<NewsArticle>((row) => NewsArticle.fromMap(row)).toList();
});
