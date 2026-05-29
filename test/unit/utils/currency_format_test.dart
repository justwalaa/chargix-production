import 'package:chargix_production/utils/currency_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormat', () {
    test('perKwh formats Jordanian dinar with three decimals', () {
      expect(CurrencyFormat.perKwh(0.35), 'د.أ 0.350 / kWh');
    });

    test('amount formats value with symbol', () {
      expect(CurrencyFormat.amount(12.5), 'د.أ 12.500');
    });

    test('code and symbol constants', () {
      expect(CurrencyFormat.code, 'JOD');
      expect(CurrencyFormat.symbol, 'د.أ');
    });
  });
}
