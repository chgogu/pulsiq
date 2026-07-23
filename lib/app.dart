import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/lock/lock_gate.dart';
import 'features/nutrition/nutrition_screen.dart';
import 'features/nutrition/scan_barcode_screen.dart';
import 'features/nutrition/snap_meal_screen.dart';
import 'features/order_hack/order_hack_screen.dart';
import 'features/profile/body_profile_screen.dart';
import 'features/settings/integrations_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/pulsiq_shell.dart';
import 'features/splash/splash_screen.dart';
import 'theme/pulse_theme.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
        ShellRoute(
          builder: (_, _, child) => PulsIQShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const DashboardScreen()),
            GoRoute(
              path: '/order-hack',
              builder: (_, _) => const OrderHackScreen(),
            ),
            GoRoute(
              path: '/nutrition',
              builder: (_, _) => const NutritionScreen(),
            ),
            GoRoute(
              path: '/snap-meal',
              builder: (_, _) => const SnapMealScreen(),
            ),
            GoRoute(
              path: '/scan-barcode',
              builder: (_, _) => const ScanBarcodeScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'privacy',
                  builder: (_, _) => const PrivacyScreen(),
                ),
                GoRoute(
                  path: 'body',
                  builder: (_, _) => const BodyProfileScreen(),
                ),
                GoRoute(
                  path: 'integrations',
                  builder: (_, _) => const IntegrationsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

class PulsIQApp extends StatefulWidget {
  const PulsIQApp({super.key});

  @override
  State<PulsIQApp> createState() => _PulsIQAppState();
}

class _PulsIQAppState extends State<PulsIQApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PulsIQ',
      debugShowCheckedModeBanner: false,
      theme: pulsiqTheme(Brightness.light),
      darkTheme: pulsiqTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      builder: (_, child) =>
          LockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
