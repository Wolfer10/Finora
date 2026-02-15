import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/errors/repository_error.dart';

void main() {
  test('guardRepositoryCall wraps unknown errors in RepositoryError', () async {
    try {
      await guardRepositoryCall<void>('op.call', () async {
        throw StateError('boom');
      });
      fail('Expected RepositoryError');
    } catch (error) {
      expect(error, isA<RepositoryError>());
      final repositoryError = error as RepositoryError;
      expect(repositoryError.operation, 'op.call');
      expect(repositoryError.cause, isA<StateError>());
    }
  });

  test('guardRepositoryCall rethrows existing RepositoryError', () async {
    final existing = RepositoryError(
      operation: 'op.existing',
      cause: ArgumentError('bad'),
      stackTrace: StackTrace.current,
    );

    try {
      await guardRepositoryCall<void>('op.call', () async {
        throw existing;
      });
      fail('Expected RepositoryError');
    } catch (error) {
      expect(identical(error, existing), isTrue);
    }
  });

  test('guardRepositoryStream wraps stream errors in RepositoryError', () async {
    final stream = guardRepositoryStream<int>('op.stream', () {
      return Stream<int>.error(StateError('stream failed'));
    });

    try {
      await stream.first;
      fail('Expected RepositoryError');
    } catch (error) {
      expect(error, isA<RepositoryError>());
      final repositoryError = error as RepositoryError;
      expect(repositoryError.operation, 'op.stream');
      expect(repositoryError.cause, isA<StateError>());
    }
  });

  test('guardRepositoryStream wraps synchronous factory throws', () async {
    try {
      guardRepositoryStream<int>('op.stream.sync', () {
        throw UnsupportedError('sync fail');
      });
      fail('Expected RepositoryError');
    } catch (error) {
      expect(error, isA<RepositoryError>());
      final repositoryError = error as RepositoryError;
      expect(repositoryError.operation, 'op.stream.sync');
      expect(repositoryError.cause, isA<UnsupportedError>());
    }
  });
}
