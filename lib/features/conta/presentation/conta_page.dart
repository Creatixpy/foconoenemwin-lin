import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../account/data/account_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/widgets/async_value_widget.dart';
import '../../shared/widgets/section_header.dart';
import '../widgets/competence_chart.dart';
import '../widgets/discipline_progress.dart';

class ContaPage extends ConsumerWidget {
  const ContaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final stats = ref.watch(userStatisticsProvider);
    final essays = ref.watch(recentEssayResultsProvider);
    final quizzes = ref.watch(recentQuizResultsProvider);
    final authState = ref.watch(authControllerProvider);

    Future<void> recalcular() async {
      final client = ref.read(supabaseClientProvider);
      await client.rpc('recalculate_user_statistics', params: {
        'target_user_id': ref.read(sessionProvider)?.user.id,
      });
      ref.invalidate(userStatisticsProvider);
    }

    Future<void> sair() async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(authControllerProvider.notifier).signOut();
        ref.invalidate(sessionStreamProvider);
        if (context.mounted) {
          context.go('/login');
        }
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Falha ao sair: $error')),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Minha conta',
            subtitle: 'Sincronizado com Supabase Auth + tabelas públicas',
            action: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/conta/editar'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar perfil'),
                ),
                TextButton.icon(
                  onPressed: recalcular,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recalcular estatísticas'),
                ),
                FilledButton.icon(
                  onPressed: authState.isLoading ? null : sair,
                  icon: authState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                ),
              ],
            ),
          ),
          if (authState.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Erro ao sair: ${authState.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const SizedBox(height: 16),
          AsyncValueWidget(
            value: profile,
            data: (data) {
              if (data == null) {
                return const Card(
                  child: ListTile(
                    title: Text('Complete seu perfil'),
                    subtitle: Text('Adicione nome, ano do ENEM e objetivos.'),
                  ),
                );
              }
              return Card(
                child: ListTile(
                  title: Text(data.fullName ?? 'Sem nome cadastrado'),
                  subtitle: Text(data.goal ?? 'Sem objetivo definido'),
                  trailing: Text('Ano ENEM: ${data.targetYear ?? '—'}'),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          AsyncValueWidget(
            value: stats,
            data: (data) {
              if (data == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _ContaMetric(
                        label: 'Redações',
                        value: data.totalRedacoes.toString(),
                        icon: Icons.edit_note_outlined,
                      ),
                      _ContaMetric(
                        label: 'Melhor nota',
                        value: data.melhorNota?.toString() ?? '--',
                        icon: Icons.workspace_premium_outlined,
                      ),
                      _ContaMetric(
                        label: 'Simulados',
                        value: data.totalSimulados.toString(),
                        icon: Icons.fact_check_outlined,
                      ),
                      _ContaMetric(
                        label: 'Taxa de acerto',
                        value: data.taxaAcerto != null
                            ? '${(data.taxaAcerto! * 100).toStringAsFixed(0)}%'
                            : '--',
                        icon: Icons.query_stats_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: CompetenceChart(stats: data)),
                            const SizedBox(width: 16),
                            Expanded(child: DisciplineProgress(stats: data)),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          CompetenceChart(stats: data),
                          const SizedBox(height: 16),
                          DisciplineProgress(stats: data),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          SectionHeader(
            title: 'Redações salvas',
            action: TextButton(
              onPressed: () => ref.invalidate(recentEssayResultsProvider),
              child: const Text('Atualizar'),
            ),
          ),
          const SizedBox(height: 12),
          AsyncValueWidget(
            value: essays,
            data: (items) {
              if (items.isEmpty) return const Text('Sem redações ainda.');
              final df = DateFormat('dd/MM HH:mm');
              return Column(
                children: [
                  for (final essay in items)
                    Card(
                      child: ListTile(
                        title: Text(essay.theme),
                        subtitle: Text(df.format(essay.createdAt)),
                        trailing: Text('${essay.score} pts'),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          SectionHeader(title: 'Simulados recentes'),
          const SizedBox(height: 12),
          AsyncValueWidget(
            value: quizzes,
            data: (items) {
              if (items.isEmpty) return const Text('Sem simulados ainda.');
              final df = DateFormat('dd/MM HH:mm');
              return Column(
                children: [
                  for (final quiz in items)
                    Card(
                      child: ListTile(
                        title: Text(quiz.disciplines.join(' · ')),
                        subtitle: Text(df.format(quiz.createdAt)),
                        trailing: Text('${quiz.correctAnswers}/${quiz.totalQuestions}'),
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

class _ContaMetric extends StatelessWidget {
  const _ContaMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
