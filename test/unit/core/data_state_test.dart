import 'package:chargix_production/core/result/data_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataState', () {
    test('DataLoading flags', () {
      const state = DataLoading<String>();
      expect(state.isLoading, isTrue);
      expect(state.isSuccess, isFalse);
      expect(state.isError, isFalse);
      expect(state.dataOrNull, isNull);
    });

    test('DataSuccess exposes data', () {
      const state = DataSuccess('hello');
      expect(state.isSuccess, isTrue);
      expect(state.dataOrNull, 'hello');
      expect(state.errorOrNull, isNull);
    });

    test('DataError exposes error', () {
      const state = DataError<int>('boom');
      expect(state.isError, isTrue);
      expect(state.dataOrNull, isNull);
      expect(state.errorOrNull, 'boom');
    });
  });
}
