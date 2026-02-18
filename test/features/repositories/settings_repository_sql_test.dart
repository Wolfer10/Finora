import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/features/settings/data/settings_repository_sql.dart';

void main() {
  late AppDatabase db;
  late SettingsRepositorySql repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SettingsRepositorySql(db);
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  test('initializes and updates app settings', () async {
    await repository.ensureInitialized();
    final initial = await repository.get();
    expect(initial.currencyCode, 'HUF');
    expect(initial.currencySymbol, 'Ft');

    await repository.update(
      initial.copyWith(
        currencyCode: 'USD',
        currencySymbol: '\$',
        updatedAt: DateTime(2026, 2, 18, 12),
      ),
    );

    final updated = await repository.get();
    expect(updated.currencyCode, 'USD');
    expect(updated.currencySymbol, '\$');
  });
}
