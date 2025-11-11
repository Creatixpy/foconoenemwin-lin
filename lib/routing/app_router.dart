import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/supabase_providers.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/comunidade/presentation/comunidade_page.dart';
import '../features/conta/presentation/conta_page.dart';
import '../features/conta/presentation/conta_editar_page.dart';
import '../features/doacao/presentation/doacao_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/noticias/presentation/noticias_page.dart';
import '../features/questoes/presentation/questoes_page.dart';
import '../features/redacao/presentation/redacao_page.dart';
import '../features/resultados/presentation/resultados_page.dart';
import '../features/shared/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(ref.watch(sessionChangesStreamProvider));

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loggingIn = state.uri.path == '/login';
      if (session == null) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final location = state.uri.path;
          return AppShell(location: location, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/redacao',
            name: 'redacao',
            builder: (context, state) => const RedacaoPage(),
          ),
          GoRoute(
            path: '/questoes',
            name: 'questoes',
            builder: (context, state) => const QuestoesPage(),
          ),
          GoRoute(
            path: '/conta',
            name: 'conta',
            builder: (context, state) => const ContaPage(),
            routes: [
              GoRoute(
                path: 'editar',
                name: 'conta-editar',
                builder: (context, state) => const ContaEditarPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/noticias',
            name: 'noticias',
            builder: (context, state) => const NoticiasPage(),
          ),
          GoRoute(
            path: '/comunidade',
            name: 'comunidade',
            builder: (context, state) => const ComunidadePage(),
          ),
          GoRoute(
            path: '/doacao',
            name: 'doacao',
            builder: (context, state) => const DoacaoPage(),
          ),
          GoRoute(
            path: '/resultados/:id',
            name: 'resultado-detalhe',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ResultadosPage(resultId: id);
            },
          ),
        ],
      ),
    ],
  );
});
