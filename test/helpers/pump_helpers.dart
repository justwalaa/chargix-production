import 'package:chargix_production/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in a themed [MaterialApp] for widget tests.
Widget wrapWithMaterialApp(Widget child, {ThemeMode themeMode = ThemeMode.light}) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: themeMode,
    home: Scaffold(body: child),
  );
}

/// Pumps [child] inside a themed scaffold and settles animations.
Future<void> pumpChargixWidget(
  WidgetTester tester,
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.pumpWidget(wrapWithMaterialApp(child, themeMode: themeMode));
  await tester.pumpAndSettle();
}
