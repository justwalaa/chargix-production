enum BookingStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  confirmed('confirmed'),
  active('active'),
  completed('completed'),
  cancelled('cancelled');

  const BookingStatus(this.value);
  final String value;

  bool get isTerminal =>
      this == BookingStatus.completed ||
      this == BookingStatus.cancelled ||
      this == BookingStatus.rejected;

  bool get holdsSlot =>
      this == BookingStatus.pending ||
      this == BookingStatus.approved ||
      this == BookingStatus.confirmed ||
      this == BookingStatus.active;

  static BookingStatus fromValue(String? raw) {
    if (raw == 'confirmed') {
      return BookingStatus.approved;
    }
    return BookingStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => BookingStatus.pending,
    );
  }
}
