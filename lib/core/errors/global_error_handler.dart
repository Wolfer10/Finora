import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef ErrorReporter = void Function(Object error, StackTrace stackTrace);

void installGlobalErrorHandlers({
  ErrorReporter reporter = _reportUnhandledError,
}) {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    final stack = details.stack ?? StackTrace.current;
    reporter(details.exception, stack);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    reporter(error, stackTrace);
    return true;
  };
}

R? runWithGlobalErrorGuard<R>(
  R Function() body, {
  ErrorReporter reporter = _reportUnhandledError,
}) {
  return runZonedGuarded<R>(
    body,
    (Object error, StackTrace stackTrace) {
      reporter(error, stackTrace);
    },
  );
}

void _reportUnhandledError(Object error, StackTrace stackTrace) {
  debugPrint('Unhandled error: $error');
  debugPrint(stackTrace.toString());
}
