import 'package:chargix_production/screens/auth/login_screen.dart';
import 'package:chargix_production/widgets/auth/jordan_phone_field.dart';
import 'package:chargix_production/widgets/auth/otp_six_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication flow integration', () {
    testWidgets('login screen validates phone before OTP', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your phone number'), findsOneWidget);
    });

    testWidgets('Jordan phone E.164 composition accepts valid number', (tester) async {
      expect(JordanPhoneField.composeE164('791234567'), '+962791234567');
      expect(JordanPhoneField.composeE164('123'), isNull);
    });

    testWidgets('OTP widget completes full six-digit entry', (tester) async {
      String? code;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpSixFields(
              onChanged: (_) {},
              onCompleted: (c) => code = c,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      for (var i = 0; i < 6; i++) {
        await tester.enterText(fields.at(i), '9');
        await tester.pump();
      }

      expect(code, '999999');
    });
  });
}
