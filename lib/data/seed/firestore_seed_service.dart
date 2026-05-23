/// Legacy seed hook — disabled in production (no demo stations).
class FirestoreSeedService {
  FirestoreSeedService._();

  static final FirestoreSeedService instance = FirestoreSeedService._();

  Future<void> ensureDemoStationsSeeded() async {}
}
