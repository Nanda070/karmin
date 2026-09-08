import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:karmin/app/widgets/karmin_bottom_nav.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart';
import 'package:karmin/auth/auth_redirect.dart';
import 'package:karmin/auth/boot_page.dart';
import 'package:karmin/auth/disclaimer_page.dart';
import 'package:karmin/auth/login_page.dart';
import 'package:karmin/auth/otp_page.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/auth/set_pin_page.dart';
import 'package:karmin/auth/unlock_page.dart';
import 'package:karmin/features/calendar/calendar_page.dart';
import 'package:karmin/features/inbox/inbox_page.dart';
import 'package:karmin/features/settings/settings_page.dart';
import 'package:karmin/features/study/study_page.dart';
import 'package:karmin/features/today/today_page.dart';
import 'package:karmin/l10n/app_localizations.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  final router = GoRouter(
    initialLocation: '/today',
    refreshListenable: refresh,
    redirect: (context, state) {
      return authRedirect(
        ref.read(authControllerProvider),
        state.uri.path,
      );
    },
    routes: [
      GoRoute(
        path: '/boot',
        name: 'boot',
        builder: (context, state) => const BootPage(),
      ),
      GoRoute(
        path: '/disclaimer',
        name: 'disclaimer',
        builder: (context, state) => const DisclaimerPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/verify',
        name: 'verify',
        builder: (context, state) => const OtpPage(),
      ),
      GoRoute(
        path: '/set-pin',
        name: 'setPin',
        builder: (context, state) => const SetPinPage(),
      ),
      GoRoute(
        path: '/unlock',
        name: 'unlock',
        builder: (context, state) => const UnlockPage(),
      ),
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
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}

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
