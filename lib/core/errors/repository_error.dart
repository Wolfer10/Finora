class RepositoryError implements Exception {
  const RepositoryError({
    required this.operation,
    required this.cause,
    required this.stackTrace,
  });

  final String operation;
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => 'RepositoryError(operation: $operation, cause: $cause)';
}

Future<T> guardRepositoryCall<T>(
  String operation,
  Future<T> Function() action,
) async {
  try {
    return await action();
  } on RepositoryError {
    rethrow;
  } catch (error, stackTrace) {
    throw RepositoryError(
      operation: operation,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

Stream<T> guardRepositoryStream<T>(
  String operation,
  Stream<T> Function() streamFactory,
) {
  try {
    return streamFactory().handleError((Object error, StackTrace stackTrace) {
      if (error is RepositoryError) {
        throw error;
      }
      throw RepositoryError(
        operation: operation,
        cause: error,
        stackTrace: stackTrace,
      );
    });
  } on RepositoryError {
    rethrow;
  } catch (error, stackTrace) {
    throw RepositoryError(
      operation: operation,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
