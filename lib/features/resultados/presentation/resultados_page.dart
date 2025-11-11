import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/models/essay_result.dart';
import '../../shared/widgets/async_value_widget.dart';
import '../../shared/widgets/section_header.dart';
import '../data/resultados_providers.dart';

class ResultadosPage extends ConsumerWidget {
  const ResultadosPage({super.key, required this.resultId});

  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(essayResultProvider(resultId));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AsyncValueWidget(
        value: result,
        data: (data) => _ResultadoView(result: data),
      ),
    );
  }
}

class _ResultadoView extends StatelessWidget {
  const _ResultadoView({required this.result});
  final EssayResult result;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Resultado da redação',
          subtitle: df.format(result.createdAt),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.theme,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Nota final'),
                      Text(
                        result.score.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Pontos fortes', style: Theme.of(context).textTheme.titleMedium),
                    ...result.strengths.map(Text.new),
                    const SizedBox(height: 12),
                    Text('Para melhorar', style: Theme.of(context).textTheme.titleMedium),
                    ...result.improvements.map(Text.new),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'Competências detalhadas',
          subtitle: 'Cada competência avaliada individualmente com feedback textual.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: result.competencias
              .map(
                (competencia) => SizedBox(
                  width: 320,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            competencia.label.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${competencia.nota} pts',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (competencia.feedback != null) ...[
                            const SizedBox(height: 8),
                            Text(competencia.feedback!),
                          ],
                          if (competencia.destaques.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Destaques',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            for (final destaque in competencia.destaques)
                              Text('• $destaque'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'Texto original',
          subtitle: 'Mantemos o histórico completo e sincronizado com Supabase.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: MarkdownBody(data: result.originalEssay),
          ),
        ),
        if (result.supportText1 != null || result.supportText2 != null) ...[
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Textos de apoio',
            subtitle: 'Conteúdos usados no prompt do Groq.',
          ),
          const SizedBox(height: 12),
          if (result.supportText1 != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(result.supportText1!),
              ),
            ),
          if (result.supportText2 != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(result.supportText2!),
              ),
            ),
        ],
      ],
    );
  }
}
