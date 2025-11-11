import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme_controller.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  static final _destinations = <_Destination>[
    const _Destination('Início', '/', Icons.home_outlined),
    const _Destination('Redação', '/redacao', Icons.edit_outlined),
    const _Destination('Questões', '/questoes', Icons.quiz_outlined),
    const _Destination('Conta', '/conta', Icons.person_pin_circle_outlined),
    const _Destination('Notícias', '/noticias', Icons.article_outlined),
    const _Destination('Comunidade', '/comunidade', Icons.forum_outlined),
    const _Destination('Doação', '/doacao', Icons.favorite_border),
  ];

  int get _currentIndex {
    final index = _destinations.indexWhere(
      (dest) => location == dest.route || location.startsWith('${dest.route}/'),
    );
    return index == -1 ? 0 : index;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final route = _destinations[index].route;
    if (route != location) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width > 900;
    final themeMode = ref.watch(themeModeProvider);
    final themeController = ref.read(themeModeProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              _Sidebar(
                currentIndex: _currentIndex,
                onTap: (index) => _onDestinationSelected(context, index),
                isDarkMode: themeMode == ThemeMode.dark,
                onToggleTheme: themeController.toggle,
              ),
            Expanded(
              child: Column(
                children: [
                  if (!isWide)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _ThemeToggleButton(
                          isDarkMode: themeMode == ThemeMode.dark,
                          onToggle: themeController.toggle,
                        ),
                      ),
                    ),
                  if (!isWide)
                    NavigationBar(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (index) =>
                          _onDestinationSelected(context, index),
                      destinations: [
                        for (final dest in _destinations)
                          NavigationDestination(
                            icon: Icon(dest.icon),
                            label: dest.label,
                          ),
                      ],
                    ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.route, this.icon);
  final String label;
  final String route;
  final IconData icon;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.currentIndex,
    required this.onTap,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 240,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foco no ENEM',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Painel de estudos',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _ThemeToggleButton(
                isDarkMode: isDarkMode,
                onToggle: onToggleTheme,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: AppShell._destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final destination = AppShell._destinations[index];
                final selected = index == currentIndex;
                return Material(
                  color: selected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    selected: selected,
                    leading: Icon(
                      destination.icon,
                      color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      destination.label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onTap: () => onTap(index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  colorScheme.secondary.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meta do dia',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Complete 1 simulado e envie 1 redação para manter o ritmo!',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({
    required this.isDarkMode,
    required this.onToggle,
  });

  final bool isDarkMode;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isDarkMode ? 'Ativar modo claro' : 'Ativar modo escuro',
      onPressed: onToggle,
      icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
    );
  }
}
