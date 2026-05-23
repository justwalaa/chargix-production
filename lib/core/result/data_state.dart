/// UI-friendly loading / success / error wrapper for async Firestore work.
sealed class DataState<T> {
  const DataState();

  bool get isLoading => this is DataLoading<T>;
  bool get isSuccess => this is DataSuccess<T>;
  bool get isError => this is DataError<T>;

  T? get dataOrNull => switch (this) {
        DataSuccess(:final data) => data,
        _ => null,
      };

  Object? get errorOrNull => switch (this) {
        DataError(:final error) => error,
        _ => null,
      };
}

final class DataLoading<T> extends DataState<T> {
  const DataLoading();
}

final class DataSuccess<T> extends DataState<T> {
  const DataSuccess(this.data);
  final T data;
}

final class DataError<T> extends DataState<T> {
  const DataError(this.error, {this.stackTrace});
  final Object error;
  final StackTrace? stackTrace;
}
