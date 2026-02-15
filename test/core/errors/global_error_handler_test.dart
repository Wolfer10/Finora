
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/errors/global_error_handler.dart';

void main() {
  late FlutterExceptionHandler? originalFlutterOnError;
  late bool Function(Object, StackTrace)? originalPlatformOnError;

  setUp(() {
    originalFlutterOnError = FlutterError.onError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = originalFlutterOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
  });

  test('installGlobalErrorHandlers forwards FlutterError to reporter', () {
    final reported = <Object>[];

    installGlobalErrorHandlers(
      reporter: (error, _) => reported.add(error),
    );

    FlutterError.onError?.call(
      FlutterErrorDetails(
        exception: StateError('flutter-fail'),
        stack: StackTrace.current,
      ),
    );

    expect(reported, hasLength(1));
    expect(reported.single, isA<StateError>());
  });

  test('installGlobalErrorHandlers forwards PlatformDispatcher errors', () {
    final reported = <Object>[];

    installGlobalErrorHandlers(
      reporter: (error, _) => reported.add(error),
    );

    final handled = PlatformDispatcher.instance.onError?.call(
      ArgumentError('platform-fail'),
      StackTrace.current,
    );

    expect(handled, isTrue);
    expect(reported, hasLength(1));
    expect(reported.single, isA<ArgumentError>());
  });

  test('runWithGlobalErrorGuard reports uncaught zone errors', () async {
    final reported = <Object>[];

    runWithGlobalErrorGuard<void>(
      () {
        Future<void>.microtask(() => throw StateError('zone-fail'));
      },
      reporter: (error, _) => reported.add(error),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(reported, hasLength(1));
    expect(reported.single, isA<StateError>());
  });
}
