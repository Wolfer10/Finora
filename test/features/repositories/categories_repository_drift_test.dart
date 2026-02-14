import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/category_dao.dart';
import 'package:finora/features/categories/data/category_repository_drift.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryDrift repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CategoryRepositoryDrift(CategoryDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('seedDefaultsIfEmpty inserts defaults only once', () async {
    await repository.seedDefaultsIfEmpty();
    final firstSeed = await repository.watchAllActive().first;
    expect(firstSeed.length, greaterThanOrEqualTo(3));

    await repository.seedDefaultsIfEmpty();
    final secondSeed = await repository.watchAllActive().first;
    expect(secondSeed.length, firstSeed.length);
  });
}
