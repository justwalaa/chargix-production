/// Partner station lifecycle + operational state (Firestore `stations.status`).
enum StationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  active('active'),
  maintenance('maintenance'),
  offline('offline');

  const StationStatus(this.value);
  final String value;

  /// Visible on the public map and accepts bookings.
  bool get isPublicOnMap =>
      this == StationStatus.approved || this == StationStatus.active;

  bool get isPendingApproval => this == StationStatus.pending;

  bool get isRejected => this == StationStatus.rejected;

  static StationStatus fromValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return StationStatus.pending;
    }
    final normalized = raw.trim();
    if (normalized == 'pendingApproval' || normalized == 'pending_approval') {
      return StationStatus.pending;
    }
    return StationStatus.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => StationStatus.pending,
    );
  }
}
