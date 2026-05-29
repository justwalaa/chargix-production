import 'package:chargix_production/widgets/auth/jordan_phone_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_helpers.dart';

void main() {
  group('JordanPhoneField', () {
    testWidgets('renders country code and hint', (tester) async {
      final controller = TextEditingController();
      final focus = FocusNode();

      await pumpChargixWidget(
        tester,
        JordanPhoneField(controller: controller, focusNode: focus),
      );

      expect(find.text('+962'), findsOneWidget);
      expect(find.text('7XXXXXXXX'), findsOneWidget);
      expect(find.text('Mobile number'), findsOneWidget);

      controller.dispose();
      focus.dispose();
    });

    group('composeE164', () {
      test('returns E.164 for valid Jordan mobile', () {
        expect(JordanPhoneField.composeE164('791234567'), '+962791234567');
      });

      test('returns null for invalid length', () {
        expect(JordanPhoneField.composeE164('79123456'), isNull);
        expect(JordanPhoneField.composeE164('891234567'), isNull);
      });

      test('returns null for empty input', () {
        expect(JordanPhoneField.composeE164(''), isNull);
        expect(JordanPhoneField.composeE164('   '), isNull);
      });
    });
  });
}
