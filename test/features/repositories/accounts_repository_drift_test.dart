import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/account_dao.dart';
import 'package:finora/core/errors/repository_error.dart';
import 'package:finora/features/accounts/data/account_repository_drift.dart';
import 'package:finora/features/accounts/domain/account.dart' as domain;

void main() {
  late AppDatabase db;
  late AccountRepositoryDrift repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AccountRepositoryDrift(AccountDao(db));
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  test('create + update + softDelete lifecycle', () async {
    final now = DateTime(2026, 2, 12, 10, 0);
    const id = 'acc-1';

    await repository.create(
      domain.Account(
        id: id,
        name: 'Main Wallet',
        type: domain.AccountType.cash,
        initialBalance: 150.50,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    final afterCreate = await repository.watchAllActive().first;
    expect(afterCreate, hasLength(1));
    expect(afterCreate.first.name, 'Main Wallet');

    await repository.update(
      afterCreate.first.copyWith(
        name: 'Primary Wallet',
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );

    final afterUpdate = await repository.watchAllActive().first;
    expect(afterUpdate, hasLength(1));
    expect(afterUpdate.first.name, 'Primary Wallet');

    await repository.softDelete(id);
    final afterDelete = await repository.watchAllActive().first;
    expect(afterDelete, isEmpty);
  });

  test('create wraps DAO failure as RepositoryError', () async {
    final failingRepository = AccountRepositoryDrift(
      _ThrowingAccountDaoForCreate(db),
    );

    final now = DateTime(2026, 2, 12, 10, 0);
    final call = failingRepository.create(
      domain.Account(
        id: 'acc-fail',
        name: 'Fail',
        type: domain.AccountType.cash,
        initialBalance: 0,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    await expectLater(call, throwsA(isA<RepositoryError>()));
  });

  test('watchAllActive wraps stream failure as RepositoryError', () async {
    final failingRepository = AccountRepositoryDrift(
      _ThrowingAccountDaoForWatch(db),
    );

    await expectLater(
      failingRepository.watchAllActive().first,
      throwsA(isA<RepositoryError>()),
    );
  });
}

class _ThrowingAccountDaoForCreate extends AccountDao {
  _ThrowingAccountDaoForCreate(super.db);

  @override
  Future<void> upsert(AccountsCompanion companion) {
    throw StateError('create failed');
  }
}

class _ThrowingAccountDaoForWatch extends AccountDao {
  _ThrowingAccountDaoForWatch(super.db);

  @override
  Stream<List<Account>> watchAll({bool activeOnly = true}) {
    return Stream<List<Account>>.error(StateError('watch failed'));
  }
}
