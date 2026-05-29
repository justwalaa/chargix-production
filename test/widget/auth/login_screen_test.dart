import 'package:chargix_production/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders welcome header and send button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Send verification code'), findsOneWidget);
      expect(find.text('Station owner portal →'), findsOneWidget);
    });

    testWidgets('validation error when phone is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your phone number'), findsOneWidget);
    });

    testWidgets('validation error when phone is too short', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '12345');
      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();

      expect(find.text('Phone number too short'), findsOneWidget);
    });
  });
}
