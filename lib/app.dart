import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class FocoNoEnemApp extends ConsumerWidget {
  const FocoNoEnemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Foco no ENEM',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        return DefaultTextStyle(
          style: GoogleFonts.inter(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
