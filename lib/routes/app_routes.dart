import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/news_screen.dart';
import '../screens/portfolio_page.dart';
import '../screens/profile_screen.dart';
import '../screens/stock_detail_screen.dart';
import '../services/marketstack_service.dart';

/// Centralized route names for the Clarivo app.
///
/// Add new screens here as the project grows. The order below reflects the
/// intended navigation flow once onboarding & auth screens are added later.
class AppRoutes {
  AppRoutes._();

  // ── Auth flow ─────────────────────────────────────────────────────────────
  static const String splash         = '/splash';
  static const String onboarding     = '/onboarding';
  static const String login          = '/login';
  static const String register       = '/register';
  static const String forgotPassword = '/forgot-password';

  // ── Main app flow ────────────────────────────────────────────────────────
  static const String home        = '/home';
  static const String market      = '/market';
  static const String news        = '/news';
  static const String portfolio   = '/portfolio';
  static const String profile     = '/profile';

  // ── Detail screens ────────────────────────────────────────────────────────
  static const String stockDetail = '/stock-detail';
  static const String settings    = '/settings';

  /// The route the app launches into — Login so users authenticate first.
  static const String initial = login;

  /// Route table consumed by [MaterialApp].
  ///
  /// Register a new screen by importing it above and adding a single entry
  /// to this map. Routes not yet implemented are intentionally omitted —
  /// they are handled by [onUnknownRoute] until the screen is built.
  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        // Auth flow.
        login:          (_) => const LoginScreen(),
        register:       (_) => const RegisterScreen(),
        forgotPassword: (_) => const ForgotPasswordScreen(),
        // Main app.
        home:           (_) => const HomeScreen(),
        portfolio:      (_) => const PortfolioPage(),
        profile:        (_) => const ProfileScreen(),
        news:           (_) => const NewsScreen(),
        stockDetail: (ctx) {
          final q = ModalRoute.of(ctx)?.settings.arguments as StockQuote?;
          return StockDetailScreen(quote: q);
        },
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

  /// Opens Profile with no transition animation — instant tab switch.
  static void openProfile(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: profile),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProfileScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// Opens News with no transition animation — instant tab switch.
  static void openNews(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: news),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NewsScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// Pushes Stock Detail screen with [quote] data.
  static void openStockDetail(BuildContext context, StockQuote quote) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: stockDetail),
        builder: (_) => StockDetailScreen(quote: quote),
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

  /// Clears the entire navigation stack (auth flow) and lands on Home.
  ///
  /// Use this after a successful login or registration so the user cannot
  /// press Back to return to an auth screen.
  static void openHomeAndClearStack(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: home),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
      // Remove every route beneath — auth can never be reached via Back.
      (route) => false,
    );
  }

  /// Clears the entire navigation stack and lands on Login.
  ///
  /// Use this when the user taps Logout so they cannot press Back to return
  /// to Home, Portfolio, or Profile.
  static void openLoginAndClearStack(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: login),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
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
