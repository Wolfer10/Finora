import 'package:drift/drift.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/transaction_dao.dart';
import 'package:finora/core/database/enum_codecs.dart';
import 'package:finora/core/errors/repository_error.dart';
import 'package:finora/features/transactions/domain/transaction.dart' as domain;
import 'package:finora/features/transactions/domain/transaction_repository.dart';

class TransactionRepositoryDrift implements TransactionRepository {
  TransactionRepositoryDrift(this._dao);

  final TransactionDao _dao;

  @override
  Future<void> create(domain.Transaction transaction) async {
    await guardRepositoryCall('TransactionRepository.create', () {
      return _dao.upsert(_toCompanion(transaction));
    });
  }

  @override
  Future<void> update(domain.Transaction transaction) async {
    await guardRepositoryCall('TransactionRepository.update', () {
      return _dao.upsert(_toCompanion(transaction));
    });
  }

  @override
  Future<void> softDelete(String id) async {
    await guardRepositoryCall('TransactionRepository.softDelete', () {
      return _dao.softDeleteById(id, DateTime.now());
    });
  }

  @override
  Future<void> softDeleteByTransferGroup(String transferGroupId) async {
    await guardRepositoryCall(
      'TransactionRepository.softDeleteByTransferGroup',
      () {
        return _dao.softDeleteByTransferGroupId(transferGroupId, DateTime.now());
      },
    );
  }

  @override
  Future<List<domain.Transaction>> listByTransferGroup(String transferGroupId) {
    return guardRepositoryCall('TransactionRepository.listByTransferGroup', () async {
      final rows = await _dao.listByTransferGroupId(transferGroupId);
      return rows.map(_toDomain).toList(growable: false);
    });
  }

  @override
  Stream<List<domain.Transaction>> watchRecent(int limit, {String? accountId}) {
    return guardRepositoryStream('TransactionRepository.watchRecent', () {
      return _dao.watchRecent(limit, accountId: accountId).map(
            (rows) => rows.map(_toDomain).toList(growable: false),
          );
    });
  }

  @override
  Stream<List<domain.Transaction>> watchByMonth(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    domain.TransactionType? type,
  }) {
    return guardRepositoryStream('TransactionRepository.watchByMonth', () {
      return _dao
          .watchByMonth(
            year,
            month,
            accountId: accountId,
            categoryId: categoryId,
            type: type == null ? null : encodeTransactionType(type),
          )
          .map(
            (rows) => rows.map(_toDomain).toList(growable: false),
          );
    });
  }

  @override
  Future<double> monthlyIncomeTotal(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    domain.TransactionType? type,
  }) async {
    return guardRepositoryCall('TransactionRepository.monthlyIncomeTotal', () async {
      final totals = await monthlyTotals(
        year,
        month,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
      );
      return totals.incomeTotal;
    });
  }

  @override
  Future<double> monthlyExpenseTotal(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    domain.TransactionType? type,
  }) async {
    return guardRepositoryCall('TransactionRepository.monthlyExpenseTotal', () async {
      final totals = await monthlyTotals(
        year,
        month,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
      );
      return totals.expenseTotal;
    });
  }

  @override
  Future<MonthlyTotals> monthlyTotals(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    domain.TransactionType? type,
  }) async {
    return guardRepositoryCall('TransactionRepository.monthlyTotals', () async {
      final row = await _dao.monthlyTotals(
        year,
        month,
        accountId: accountId,
        categoryId: categoryId,
        type: type == null ? null : encodeTransactionType(type),
      );
      return MonthlyTotals(
        incomeTotal: row.incomeTotal,
        expenseTotal: row.expenseTotal,
      );
    });
  }

  TransactionsCompanion _toCompanion(domain.Transaction transaction) {
    return TransactionsCompanion.insert(
      id: transaction.id,
      accountId: transaction.accountId,
      categoryId: transaction.categoryId,
      type: encodeTransactionType(transaction.type),
      amount: transaction.amount,
      date: transaction.date,
      note: Value(transaction.note),
      transferGroupId: Value(transaction.transferGroupId),
      recurringRuleId: Value(transaction.recurringRuleId),
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      isDeleted: Value(transaction.isDeleted),
    );
  }

  domain.Transaction _toDomain(Transaction row) {
    return domain.Transaction(
      id: row.id,
      accountId: row.accountId,
      categoryId: row.categoryId,
      type: decodeTransactionType(row.type),
      amount: row.amount,
      date: row.date,
      note: row.note,
      transferGroupId: row.transferGroupId,
      recurringRuleId: row.recurringRuleId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
    );
  }
}
