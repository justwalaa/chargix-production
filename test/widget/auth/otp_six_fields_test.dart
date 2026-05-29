import 'package:chargix_production/widgets/auth/otp_six_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_helpers.dart';

void main() {
  group('OtpSixFields', () {
    testWidgets('typing six digits triggers onCompleted', (tester) async {
      String? completed;
      await pumpChargixWidget(
        tester,
        OtpSixFields(
          onChanged: (_) {},
          onCompleted: (code) => completed = code,
        ),
      );

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(6));

      for (var i = 0; i < 6; i++) {
        await tester.enterText(fields.at(i), '${i + 1}');
        await tester.pump();
      }

      expect(completed, '123456');
    });

    testWidgets('clear resets all fields', (tester) async {
      final key = GlobalKey<OtpSixFieldsState>();
      await pumpChargixWidget(
        tester,
        OtpSixFields(
          key: key,
          onChanged: (_) {},
          onCompleted: (_) {},
        ),
      );

      await tester.enterText(find.byType(TextField).first, '1');
      await tester.pump();
      key.currentState!.clear();
      await tester.pump();

      expect(find.byType(TextField).first, findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('disabled state prevents input', (tester) async {
      await pumpChargixWidget(
        tester,
        OtpSixFields(
          enabled: false,
          onChanged: (_) {},
          onCompleted: (_) {},
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.enabled, isFalse);
    });
  });
}
