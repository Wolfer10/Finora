# Error Handling Strategy (S2.6)

This document defines the Finora error handling strategy for:
- AsyncValue UI flows
- Repository safety
- Global uncaught error handling

## 1. AsyncValue Conventions

When using Riverpod providers that return `AsyncValue<T>`:
- `loading`: show a deterministic loading UI (spinner/skeleton), no silent waits.
- `error`: show a friendly generic message and a retry action.
- `data`: render content only from resolved data state.

Rules:
- No stack traces in user-facing UI.
- Keep detailed error information in logs only.
- Always provide retry for recoverable read operations.

## 2. Repository-Level Safety

Repositories are the error boundary around DAO calls.

Policy:
- Wrap every repository `Future` operation with `guardRepositoryCall(...)`.
- Wrap every repository `Stream` operation with `guardRepositoryStream(...)`.
- Convert unknown failures into `RepositoryError` with:
  - operation name
  - original cause
  - stack trace

This keeps provider and UI layers consistent because repository failures have a stable type.

Implementation:
- `lib/core/errors/repository_error.dart`
- Drift repositories in:
  - `lib/features/accounts/data/account_repository_drift.dart`
  - `lib/features/categories/data/category_repository_drift.dart`
  - `lib/features/transactions/data/transaction_repository_drift.dart`

## 3. Global Error Handler Decision

Decision: enabled.

Global handlers are installed at app startup to catch uncaught framework and zone errors:
- `FlutterError.onError`
- `PlatformDispatcher.instance.onError`
- `runZonedGuarded(...)`

Implementation:
- `lib/core/errors/global_error_handler.dart`
- wired in `lib/main.dart`

## 4. Notes

- This strategy does not swallow errors; it standardizes them.
- Logging currently uses `debugPrint`; can be replaced with Crashlytics/Sentry later.
