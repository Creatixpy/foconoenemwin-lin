import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../account/data/account_providers.dart';
import '../../noticias/data/noticias_providers.dart';
import '../../shared/application/update_controller.dart';
import '../../shared/widgets/async_value_widget.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _updateTimer;
  bool _updateWatcherStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartUpdateChecks());
    ref.listen(updateControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Atualização: ${next.error}')),
        );
      }
      if (next.installerLaunched && next.installerLaunched != previous?.installerLaunched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Instalador iniciado. Conclua a instalação e reinicie o aplicativo.',
            ),
          ),
        );
        ref.read(updateControllerProvider.notifier).clearInstallerMessage();
      }
    });
    ref.listen(sessionProvider, (previous, next) {
      if (next != null) {
        _maybeStartUpdateChecks();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybeStartUpdateChecks() async {
    if (_updateWatcherStarted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    _updateWatcherStarted = true;
    await ref.read(updateControllerProvider.notifier).checkForUpdates();
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => ref.read(updateControllerProvider.notifier).checkForUpdates(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(userStatisticsProvider);
    final essays = ref.watch(recentEssayResultsProvider);
    final news = ref.watch(noticiasProvider);
    final updateState = ref.watch(updateControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroHeader(onGoToRedacao: () => context.go('/redacao'), onGoToQuestoes: () => context.go('/questoes')),
          if (updateState.hasUpdate && updateState.info != null) ...[
            const SizedBox(height: 16),
            _UpdateCard(state: updateState),
          ],
          const SizedBox(height: 32),
          AsyncValueWidget(
            value: stats,
            data: (value) {
              if (value == null) {
                return const Text('Complete seu perfil para começar a acompanhar seus indicadores.');
              }
              return GridView.count(
                shrinkWrap: true,
                crossAxisCount: MediaQuery.sizeOf(context).width > 1000 ? 4 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                children: [
                  StatCard(
                    label: 'Redações corrigidas',
                    value: value.totalRedacoes.toString(),
                    icon: Icons.edit_note_outlined,
                  ),
                  StatCard(
                    label: 'Média das notas',
                    value:
                        value.mediaNotaRedacao?.toStringAsFixed(1) ?? '--',
                    icon: Icons.star_border_rounded,
                  ),
                  StatCard(
                    label: 'Simulados feitos',
                    value: value.totalSimulados.toString(),
                    icon: Icons.analytics_outlined,
                  ),
                  StatCard(
                    label: 'Taxa de acerto',
                    value:
                        value.taxaAcerto != null ? '${(value.taxaAcerto! * 100).toStringAsFixed(0)}%' : '--',
                    icon: Icons.bolt_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          SectionHeader(
            title: 'Últimas correções',
            subtitle: 'Acompanhe os feedbacks e progrida por competência',
            action: TextButton(
              onPressed: () => context.go('/conta'),
              child: const Text('Ver todas'),
            ),
          ),
          const SizedBox(height: 16),
          AsyncValueWidget(
            value: essays,
            data: (items) {
              if (items.isEmpty) {
                return const Text('Nenhuma redação corrigida ainda. Comece agora!');
              }
              return Column(
                children: [
                  for (final essay in items.take(3))
                    Card(
                      child: ListTile(
                        title: Text(essay.theme),
                        subtitle: Text(
                          'Nota ${essay.score} • ${DateFormat('dd/MM/yyyy – HH:mm').format(essay.createdAt)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/resultados/${essay.id}'),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          SectionHeader(
            title: 'Destaques do dia',
            subtitle: 'Notícias selecionadas automaticamente e atualizadas a cada 24h',
            action: TextButton(
              onPressed: () => context.go('/noticias'),
              child: const Text('Ver notícias'),
            ),
          ),
          const SizedBox(height: 16),
          AsyncValueWidget(
            value: news,
            data: (articles) {
              if (articles.isEmpty) {
                return const Text('Sem notícias por enquanto.');
              }
              return Column(
                children: [
                  for (final article in articles.take(3))
                    Card(
                      child: ListTile(
                        title: Text(article.title),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(article.publishedAt)),
                        trailing: const Icon(Icons.open_in_new),
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.onGoToRedacao,
    required this.onGoToQuestoes,
  });

  final VoidCallback onGoToRedacao;
  final VoidCallback onGoToQuestoes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8F57FF), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foco no ENEM\nSeu hub de estudos inteligente',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Redações corrigidas por IA alinhada às competências do ENEM, simulador de questões e comunidade em tempo real.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: onGoToRedacao,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4F46E5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Enviar redação agora'),
              ),
              OutlinedButton(
                onPressed: onGoToQuestoes,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Montar simulado'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdateCard extends ConsumerWidget {
  const _UpdateCard({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = state.info;
    if (info == null) return const SizedBox.shrink();
    final controller = ref.read(updateControllerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Atualização disponível (${info.version})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              info.releaseNotes.isNotEmpty
                  ? info.releaseNotes.split('\n').take(3).join('\n')
                  : 'Uma nova versão está pronta para ser instalada automaticamente.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: state.isInstalling ? null : controller.installUpdate,
                  icon: state.isInstalling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update),
                  label: Text(state.isInstalling ? 'Baixando...' : 'Atualizar agora'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed:
                      state.isInstalling ? null : controller.dismissUpdate,
                  child: const Text('Depois'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
