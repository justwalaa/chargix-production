enum ChargingSessionStatus {
  idle('idle'),
  charging('charging'),
  paused('paused'),
  completed('completed'),
  failed('failed');

  const ChargingSessionStatus(this.value);
  final String value;

  static ChargingSessionStatus fromValue(String? raw) {
    return ChargingSessionStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ChargingSessionStatus.idle,
    );
  }
}
