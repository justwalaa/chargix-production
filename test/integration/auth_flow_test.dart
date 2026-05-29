import 'package:chargix_production/screens/auth/login_screen.dart';
import 'package:chargix_production/widgets/auth/jordan_phone_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication flow', () {
    testWidgets('login screen blocks empty phone submission', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your phone number'), findsOneWidget);
    });

    test('Jordan E.164 validation accepts 79XXXXXXXX', () {
      expect(JordanPhoneField.composeE164('791234567'), '+962791234567');
    });
  });
}
