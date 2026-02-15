import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/category_dao.dart';
import 'package:finora/core/errors/repository_error.dart';
import 'package:finora/features/categories/data/category_repository_drift.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryDrift repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CategoryRepositoryDrift(CategoryDao(db));
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  test('seedDefaultsIfEmpty inserts defaults only once', () async {
    await repository.seedDefaultsIfEmpty();
    final firstSeed = await repository.watchAllActive().first;
    expect(firstSeed.length, greaterThanOrEqualTo(3));

    await repository.seedDefaultsIfEmpty();
    final secondSeed = await repository.watchAllActive().first;
    expect(secondSeed.length, firstSeed.length);
  });

  test('seedDefaultsIfEmpty wraps DAO failure as RepositoryError', () async {
    final failingRepository = CategoryRepositoryDrift(
      _ThrowingCategoryDaoForSeed(db),
    );

    await expectLater(
      failingRepository.seedDefaultsIfEmpty(),
      throwsA(isA<RepositoryError>()),
    );
  });

  test('watchAllActive wraps stream failure as RepositoryError', () async {
    final failingRepository = CategoryRepositoryDrift(
      _ThrowingCategoryDaoForWatch(db),
    );

    await expectLater(
      failingRepository.watchAllActive().first,
      throwsA(isA<RepositoryError>()),
    );
  });
}

class _ThrowingCategoryDaoForSeed extends CategoryDao {
  _ThrowingCategoryDaoForSeed(super.db);

  @override
  Future<void> seedDefaultsIfEmpty() {
    throw StateError('seed failed');
  }
}

class _ThrowingCategoryDaoForWatch extends CategoryDao {
  _ThrowingCategoryDaoForWatch(super.db);

  @override
  Stream<List<Category>> watchAll({bool activeOnly = true}) {
    return Stream<List<Category>>.error(StateError('watch failed'));
  }
}
