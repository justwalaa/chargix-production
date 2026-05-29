import 'package:chargix_production/core/firebase/firestore_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreHelpers', () {
    test('requireString returns non-empty string or empty fallback', () {
      expect(
        FirestoreHelpers.requireString({'name': 'Chargix'}, 'name'),
        'Chargix',
      );
      expect(FirestoreHelpers.requireString({}, 'name'), '');
      expect(FirestoreHelpers.requireString({'n': 42}, 'n'), '42');
    });

    test('optionalString returns null for missing or empty', () {
      expect(FirestoreHelpers.optionalString(null, 'k'), isNull);
      expect(FirestoreHelpers.optionalString({'k': ''}, 'k'), isNull);
      expect(FirestoreHelpers.optionalString({'k': 'x'}, 'k'), 'x');
    });

    test('requireInt parses int, num, and string', () {
      expect(FirestoreHelpers.requireInt({'n': 3}, 'n'), 3);
      expect(FirestoreHelpers.requireInt({'n': 3.9}, 'n'), 3);
      expect(FirestoreHelpers.requireInt({'n': '7'}, 'n'), 7);
      expect(FirestoreHelpers.requireInt({}, 'n', fallback: 9), 9);
    });

    test('requireDouble parses double, num, and string', () {
      expect(FirestoreHelpers.requireDouble({'n': 1.5}, 'n'), 1.5);
      expect(FirestoreHelpers.requireDouble({'n': 2}, 'n'), 2.0);
      expect(FirestoreHelpers.requireDouble({'n': '0.35'}, 'n'), 0.35);
    });

    test('requireBool parses bool and string true', () {
      expect(FirestoreHelpers.requireBool({'f': true}, 'f'), isTrue);
      expect(FirestoreHelpers.requireBool({'f': 'true'}, 'f'), isTrue);
      expect(FirestoreHelpers.requireBool({}, 'f'), isFalse);
    });

    test('stringList maps list elements to strings', () {
      expect(
        FirestoreHelpers.stringList({'tags': ['a', 1]}, 'tags'),
        ['a', '1'],
      );
      expect(FirestoreHelpers.stringList({}, 'tags'), isEmpty);
    });

    test('timestampToDateTime handles Timestamp and DateTime', () {
      final dt = DateTime.utc(2026, 5, 30);
      final fromTimestamp =
          FirestoreHelpers.timestampToDateTime(Timestamp.fromDate(dt));
      expect(fromTimestamp?.toUtc(), dt);
      expect(FirestoreHelpers.timestampToDateTime(dt), dt);
      expect(FirestoreHelpers.timestampToDateTime('bad'), isNull);
    });

    test('geoPoint helpers round-trip lat/lng', () {
      final point = FirestoreHelpers.geoPointFromMap({
        'latitude': 31.9,
        'longitude': 35.9,
      });
      expect(point.latitude, 31.9);
      expect(
        FirestoreHelpers.geoPointToLatLngMap(point),
        {'latitude': 31.9, 'longitude': 35.9},
      );
    });

    test('serverTimestampsOnWrite includes create fields', () {
      final create = FirestoreHelpers.serverTimestampsOnWrite(isCreate: true);
      expect(create.containsKey('createdAt'), isTrue);
      expect(create.containsKey('updatedAt'), isTrue);

      final update = FirestoreHelpers.serverTimestampsOnWrite(isCreate: false);
      expect(update.containsKey('createdAt'), isFalse);
    });
  });
}
