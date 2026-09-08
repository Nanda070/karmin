import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:karmin/app/router.dart';
import 'package:karmin/app/theme.dart';
import 'package:karmin/app/theme_mode_controller.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/l10n/app_localizations.dart';

class KarminApp extends ConsumerStatefulWidget {
  const KarminApp({super.key});

  @override
  ConsumerState<KarminApp> createState() => _KarminAppState();
}

class _KarminAppState extends ConsumerState<KarminApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = ref.read(authControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        auth.onAppPaused();
      case AppLifecycleState.resumed:
        auth.onAppResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: 'Karmin',
      debugShowCheckedModeBanner: false,
      theme: KarminTheme.light(),
      darkTheme: KarminTheme.dark(),
      themeMode: themeMode,
      // GoogleFonts inherit:false — skip Material lerp between light/dark.
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
