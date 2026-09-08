import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:karmin/app/router.dart';
import 'package:karmin/app/theme.dart';
import 'package:karmin/l10n/app_localizations.dart';

class KarminApp extends ConsumerWidget {
  const KarminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Karmin',
      debugShowCheckedModeBanner: false,
      theme: KarminTheme.dark(),
      darkTheme: KarminTheme.dark(),
      themeMode: ThemeMode.dark,
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
