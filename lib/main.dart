import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'routes/app_routes.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
      ]
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF0F1E2E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ClarivoApp());
}

class ClarivoApp extends StatelessWidget {
  const ClarivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clarivo',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
      onUnknownRoute: AppRoutes.onUnknownRoute,
    );
  }

  ThemeData _buildTheme() {
    const background = Color(0xFF07111F);
    const card = Color(0xFF0F1E2E);
    const accent = Color(0xFF00E096);
    const primaryText = Color(0xFFFFFFFF);
    const secondaryText = Color(0xFFA8B3C7);

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: accent,
        secondary: accent,
        surface: card,
        onPrimary: background,
        onSurface: primaryText,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: primaryText,
        displayColor: primaryText,
      ),
      iconTheme: const IconThemeData(color: secondaryText),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
