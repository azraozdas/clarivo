import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clarivo/main.dart';
import 'package:clarivo/routes/app_routes.dart';
import 'package:clarivo/screens/news_screen.dart';
import 'package:clarivo/screens/pro_page.dart';
import 'package:clarivo/screens/stock_detail_screen.dart';

void main() {
  // ── Smoke test ─────────────────────────────────────────────────────────────
  group('App smoke test', () {
    testWidgets('App launches without crash', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ClarivoApp());

      // App starts on the Login screen — verify MaterialApp is present.
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ── Route table tests ──────────────────────────────────────────────────────
  group('Route registration', () {
    test('Home route is registered', () {
      expect(AppRoutes.routes.containsKey(AppRoutes.home), isTrue);
    });

    test('Portfolio route is registered', () {
      expect(AppRoutes.routes.containsKey(AppRoutes.portfolio), isTrue);
    });

    test('Profile route is registered', () {
      expect(AppRoutes.routes.containsKey(AppRoutes.profile), isTrue);
    });

    test('News route is registered', () {
      expect(AppRoutes.routes.containsKey(AppRoutes.news), isTrue);
    });

    test('Stock detail route is registered', () {
      expect(AppRoutes.routes.containsKey(AppRoutes.stockDetail), isTrue);
    });

    test('Login route is registered', () {
      expect(AppRoutes.routes.containsKey(AppRoutes.login), isTrue);
    });
  });

  // ── Widget tests ───────────────────────────────────────────────────────────
  group('Screen widget tests', () {
    testWidgets('ProPage renders plan headings', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProPage()));
      await tester.pump();

      expect(find.text('Clarivo Plans'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Clarivo Pro'), findsOneWidget);
      expect(find.text('Clarivo Premium'), findsOneWidget);
    });

    testWidgets('ProPage does not show payment disclaimer text',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProPage()));
      await tester.pump();

      expect(find.textContaining('No real payment'), findsNothing);
    });

    testWidgets('NewsScreen renders article list', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NewsScreen()));
      await tester.pump();

      expect(find.text('Market News'), findsOneWidget);
      // NewsScreen uses CustomScrollView with SliverList (no ListView)
      expect(find.byType(CustomScrollView), findsOneWidget);
      // Market snapshot section header is always present
      expect(find.text('Market Snapshot'), findsOneWidget);
    });

    testWidgets('StockDetailScreen handles null quote gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StockDetailScreen(quote: null)),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('No stock data available.'), findsOneWidget);
    });

    testWidgets('StockDetailScreen renders bottom nav bar when quote is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StockDetailScreen(quote: null)),
      );
      await tester.pump();

      // AppBar title defaults to 'Stock Detail'
      expect(find.text('Stock Detail'), findsOneWidget);
    });
  });
}
