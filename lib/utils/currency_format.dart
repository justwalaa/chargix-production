/// Jordanian Dinar formatting for station pricing UI.
abstract final class CurrencyFormat {
  static const String code = 'JOD';
  static const String symbol = 'د.أ';

  static String perKwh(double amount) =>
      '$symbol ${amount.toStringAsFixed(3)} / kWh';

  static String amount(double value) => '$symbol ${value.toStringAsFixed(3)}';
}
