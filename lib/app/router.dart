import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:karmin/app/widgets/karmin_bottom_nav.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart';
import 'package:karmin/features/calendar/calendar_page.dart';
import 'package:karmin/features/inbox/inbox_page.dart';
import 'package:karmin/features/settings/settings_page.dart';
import 'package:karmin/features/study/study_page.dart';
import 'package:karmin/features/today/today_page.dart';
import 'package:karmin/l10n/app_localizations.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                name: 'today',
                builder: (context, state) => const TodayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                name: 'calendar',
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/study',
                name: 'study',
                builder: (context, state) => const StudyPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                name: 'inbox',
                builder: (context, state) => const InboxPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return KarminScaffold(
      bottomNavigationBar: KarminBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: navigationShell.goBranch,
        labels: [
          l10n.tabToday,
          l10n.tabCalendar,
          l10n.tabStudy,
          l10n.tabInbox,
        ],
      ),
      body: navigationShell,
    );
  }
}
