import 'package:chargix_production/widgets/neon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_helpers.dart';

void main() {
  group('NeonButton', () {
    testWidgets('primary label renders and responds to tap', (tester) async {
      var tapped = false;
      await pumpChargixWidget(
        tester,
        NeonButton.primary(
          label: 'Book now',
          onPressed: () => tapped = true,
        ),
      );

      expect(find.text('Book now'), findsOneWidget);
      await tester.tap(find.text('Book now'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          NeonButton.primary(
            label: 'Loading',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await pumpChargixWidget(
        tester,
        const NeonButton.primary(label: 'Disabled', onPressed: null),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();
      // No exception — button is visually disabled.
      expect(find.text('Disabled'), findsOneWidget);
    });
  });
}
