import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/portfolio_page.dart';

/// Centralized route names for the Clarivo app.
///
/// Add new screens here as the project grows. The order below reflects the
/// intended navigation flow once onboarding & auth screens are added later.
class AppRoutes {
  AppRoutes._();

  // ── Onboarding flow (to be implemented) ──────────────────────────────────
  static const String splash      = '/splash';
  static const String onboarding  = '/onboarding';
  static const String login       = '/login';
  static const String register    = '/register';

  // ── Main app flow ────────────────────────────────────────────────────────
  static const String home        = '/home';
  static const String market      = '/market';
  static const String news        = '/news';
  static const String portfolio   = '/portfolio';
  static const String profile     = '/profile';

  // ── Detail screens (to be implemented) ───────────────────────────────────
  static const String stockDetail = '/stock-detail';
  static const String settings    = '/settings';

  /// The route the app launches into.
  static const String initial = home;

  /// Route table consumed by [MaterialApp].
  ///
  /// Register a new screen by importing it above and adding a single entry
  /// to this map. Routes not yet implemented are intentionally omitted —
  /// they are handled by [onUnknownRoute] until the screen is built.
  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        home: (_) => const HomeScreen(),
        portfolio: (_) => const PortfolioPage(),
      };

  /// Opens Portfolio with no transition animation — instant tab switch.
  static void openPortfolio(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: portfolio),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PortfolioPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// Opens Home with no transition animation — instant tab switch.
  static void openHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: home),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// Fallback route shown when navigating to a name that isn't registered
  /// yet. Keeps the app crash-free as new screens are wired in.
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => _ComingSoonScreen(routeName: settings.name ?? 'Unknown'),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final String routeName;
  const _ComingSoonScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E2E),
        elevation: 0,
        title: Text(
          routeName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF00E096),
                size: 36,
              ),
              SizedBox(height: 14),
              Text(
                'Coming soon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This screen is part of an upcoming step in the Clarivo flow.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFA8B3C7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
