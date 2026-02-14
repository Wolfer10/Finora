import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/category_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = CategoryDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('watchAllActive returns only non-deleted categories ordered by name', () async {
    final now = DateTime(2026, 2, 13, 10, 0);

    await dao.upsert(
      CategoriesCompanion.insert(
        id: 'cat-z',
        name: 'Zoo',
        type: 'expense',
        icon: 'pets',
        color: '#000000',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      CategoriesCompanion.insert(
        id: 'cat-a',
        name: 'Auto',
        type: 'expense',
        icon: 'car',
        color: '#ffffff',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await dao.upsert(
      CategoriesCompanion.insert(
        id: 'cat-deleted',
        name: 'Deleted',
        type: 'income',
        icon: 'block',
        color: '#333333',
        createdAt: now,
        updatedAt: now,
        isDeleted: const Value(true),
      ),
    );

    final rows = await dao.watchAllActive().first;
    expect(rows.map((row) => row.id), ['cat-a', 'cat-z']);
  });

  test('softDeleteById marks row deleted and updates timestamp', () async {
    final createdAt = DateTime(2026, 2, 13, 10, 0);
    final updatedAt = DateTime(2026, 2, 13, 11, 0);

    await dao.upsert(
      CategoriesCompanion.insert(
        id: 'cat-1',
        name: 'Food',
        type: 'expense',
        icon: 'restaurant',
        color: '#EF6C00',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    await dao.softDeleteById('cat-1', updatedAt);

    final row = await (db.select(db.categories)..where((tbl) => tbl.id.equals('cat-1')))
        .getSingle();
    expect(row.isDeleted, isTrue);
    expect(row.updatedAt, updatedAt);
  });

  test('seedDefaultsIfEmpty inserts defaults only when table is empty', () async {
    await dao.seedDefaultsIfEmpty();
    final firstSeedRows = await dao.watchAllActive().first;

    expect(firstSeedRows.map((row) => row.id), contains('cat-income-salary'));
    expect(firstSeedRows.map((row) => row.id), contains('cat-expense-food'));
    expect(firstSeedRows.map((row) => row.id), contains('cat-expense-transport'));

    await dao.seedDefaultsIfEmpty();
    final allRows = await db.select(db.categories).get();
    expect(allRows.length, firstSeedRows.length);
  });

  test('seedDefaultsIfEmpty skips when any row already exists', () async {
    final now = DateTime(2026, 2, 13, 10, 0);

    await dao.upsert(
      CategoriesCompanion.insert(
        id: 'cat-custom',
        name: 'Custom',
        type: 'expense',
        icon: 'star',
        color: '#111111',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await dao.seedDefaultsIfEmpty();

    final allRows = await db.select(db.categories).get();
    expect(allRows, hasLength(1));
    expect(allRows.single.id, 'cat-custom');
  });
}
