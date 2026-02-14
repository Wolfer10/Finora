import 'package:drift/drift.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/account_dao.dart';
import 'package:finora/core/database/enum_codecs.dart';
import 'package:finora/features/accounts/domain/account.dart' as domain;
import 'package:finora/features/accounts/domain/account_repository.dart';

class AccountRepositoryDrift implements AccountRepository {
  AccountRepositoryDrift(this._dao);

  final AccountDao _dao;

  @override
  Future<void> create(domain.Account account) async {
    await _dao.upsert(_toCompanion(account));
  }

  @override
  Future<void> update(domain.Account account) async {
    await _dao.upsert(_toCompanion(account));
  }

  @override
  Future<void> softDelete(String id) async {
    await _dao.softDeleteById(id, DateTime.now());
  }

  @override
  Stream<List<domain.Account>> watchAll({bool activeOnly = true}) {
    return _dao.watchAll(activeOnly: activeOnly).map(
          (rows) => rows.map(_toDomain).toList(growable: false),
        );
  }

  @override
  Stream<List<domain.Account>> watchAllActive() {
    return watchAll(activeOnly: true);
  }

  AccountsCompanion _toCompanion(domain.Account account) {
    return AccountsCompanion.insert(
      id: account.id,
      name: account.name,
      type: encodeAccountType(account.type),
      initialBalance: account.initialBalance,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
      isDeleted: Value(account.isDeleted),
    );
  }

  domain.Account _toDomain(Account row) {
    return domain.Account(
      id: row.id,
      name: row.name,
      type: decodeAccountType(row.type),
      initialBalance: row.initialBalance,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
    );
  }
}
