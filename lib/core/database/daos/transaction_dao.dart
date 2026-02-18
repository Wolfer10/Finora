import 'package:drift/drift.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/tables/transactions_table.dart';

part 'transaction_dao.g.dart';

class MonthlyTotalsRow {
  const MonthlyTotalsRow({
    required this.incomeTotal,
    required this.expenseTotal,
  });

  final double incomeTotal;
  final double expenseTotal;

  double get net => incomeTotal - expenseTotal;
}

class MonthlyTotalsPoint {
  const MonthlyTotalsPoint({
    required this.year,
    required this.month,
    required this.incomeTotal,
    required this.expenseTotal,
  });

  final int year;
  final int month;
  final double incomeTotal;
  final double expenseTotal;

  double get net => incomeTotal - expenseTotal;
}

class CategoryExpenseTotalRow {
  const CategoryExpenseTotalRow({
    required this.categoryId,
    required this.totalExpense,
  });

  final String categoryId;
  final double totalExpense;
}

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<void> upsert(TransactionsCompanion companion) async {
    await into(transactions).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteById(String id, DateTime updatedAt) async {
    await (update(transactions)..where((tbl) => tbl.id.equals(id))).write(
      TransactionsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> softDeleteByTransferGroupId(
    String transferGroupId,
    DateTime updatedAt,
  ) async {
    await (update(transactions)
          ..where((tbl) => tbl.transferGroupId.equals(transferGroupId)))
        .write(
      TransactionsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<List<Transaction>> listByTransferGroupId(String transferGroupId) {
    return (select(transactions)
          ..where(
            (tbl) =>
                tbl.transferGroupId.equals(transferGroupId) &
                tbl.isDeleted.equals(false),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Stream<List<Transaction>> watchRecent(int limit, {String? accountId}) {
    return (select(transactions)
          ..where((tbl) {
            var predicate = tbl.isDeleted.equals(false);
            if (accountId != null) {
              predicate = predicate & tbl.accountId.equals(accountId);
            }
            return predicate;
          })
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.date),
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ])
          ..limit(limit))
        .watch();
  }

  Stream<List<Transaction>> watchByMonth(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    String? type,
  }) {
    final start = DateTime(year, month);
    final end = month == 12 ? DateTime(year + 1, 1) : DateTime(year, month + 1);
    return (select(transactions)
          ..where((tbl) {
            var predicate =
                tbl.isDeleted.equals(false) &
                tbl.date.isBiggerOrEqualValue(start) &
                tbl.date.isSmallerThanValue(end);
            if (accountId != null) {
              predicate = predicate & tbl.accountId.equals(accountId);
            }
            if (categoryId != null) {
              predicate = predicate & tbl.categoryId.equals(categoryId);
            }
            if (type != null) {
              predicate = predicate & tbl.type.equals(type);
            }
            return predicate;
          })
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.date),
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .watch();
  }

  Stream<List<Transaction>> watchTransfersByMonth(int year, int month) {
    return watchByMonth(year, month, type: 'transfer');
  }

  Future<MonthlyTotalsRow> monthlyTotals(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    String? type,
  }) async {
    final incomeTotal = await _monthlyTotalByType(
      year,
      month,
      accountId: accountId,
      categoryId: categoryId,
      type: 'income',
      requestedType: type,
    );
    final expenseTotal = await _monthlyTotalByType(
      year,
      month,
      accountId: accountId,
      categoryId: categoryId,
      type: 'expense',
      requestedType: type,
    );

    return MonthlyTotalsRow(
      incomeTotal: incomeTotal,
      expenseTotal: expenseTotal,
    );
  }

  Stream<List<MonthlyTotalsPoint>> monthlyTotalsRange(
    int startYear,
    int startMonth,
    int endYear,
    int endMonth, {
    String? accountId,
  }) {
    final start = DateTime(startYear, startMonth);
    final end = DateTime(endYear, endMonth);

    return (select(transactions)
          ..where((tbl) {
            var predicate =
                tbl.isDeleted.equals(false) &
                tbl.date.isBiggerOrEqualValue(start) &
                tbl.date.isSmallerThanValue(end) &
                tbl.type.isNotValue('transfer');
            if (accountId != null) {
              predicate = predicate & tbl.accountId.equals(accountId);
            }
            return predicate;
          }))
        .watch()
        .map((rows) {
          final grouped = <String, MonthlyTotalsPoint>{};
          for (final row in rows) {
            final key = '${row.date.year}-${row.date.month}';
            final existing = grouped[key] ??
                MonthlyTotalsPoint(
                  year: row.date.year,
                  month: row.date.month,
                  incomeTotal: 0,
                  expenseTotal: 0,
                );
            final income = row.type == 'income'
                ? existing.incomeTotal + row.amount
                : existing.incomeTotal;
            final expense = row.type == 'expense'
                ? existing.expenseTotal + row.amount
                : existing.expenseTotal;
            grouped[key] = MonthlyTotalsPoint(
              year: existing.year,
              month: existing.month,
              incomeTotal: income,
              expenseTotal: expense,
            );
          }

          final result = grouped.values.toList(growable: false)
            ..sort((a, b) {
              final yearCompare = a.year.compareTo(b.year);
              if (yearCompare != 0) {
                return yearCompare;
              }
              return a.month.compareTo(b.month);
            });
          return result;
        });
  }

  Stream<List<CategoryExpenseTotalRow>> categoryTotals(
    int year,
    int month, {
    String? accountId,
  }) {
    final start = DateTime(year, month);
    final end = month == 12 ? DateTime(year + 1, 1) : DateTime(year, month + 1);

    return (select(transactions)
          ..where((tbl) {
            var predicate =
                tbl.isDeleted.equals(false) &
                tbl.date.isBiggerOrEqualValue(start) &
                tbl.date.isSmallerThanValue(end) &
                tbl.type.equals('expense');
            if (accountId != null) {
              predicate = predicate & tbl.accountId.equals(accountId);
            }
            return predicate;
          }))
        .watch()
        .map((rows) {
          final totals = <String, double>{};
          for (final row in rows) {
            totals[row.categoryId] = (totals[row.categoryId] ?? 0) + row.amount;
          }

          final result = totals.entries
              .map(
                (entry) => CategoryExpenseTotalRow(
                  categoryId: entry.key,
                  totalExpense: entry.value,
                ),
              )
              .toList(growable: false)
            ..sort((a, b) => b.totalExpense.compareTo(a.totalExpense));
          return result;
        });
  }

  Future<double> _monthlyTotalByType(
    int year,
    int month, {
    required String type,
    String? accountId,
    String? categoryId,
    String? requestedType,
  }) async {
    if (requestedType != null && requestedType != type) {
      return 0.0;
    }
    return monthlyTotalByType(
      year,
      month,
      type: type,
      accountId: accountId,
      categoryId: categoryId,
    );
  }

  Future<double> monthlyTotalByType(
    int year,
    int month, {
    required String type,
    String? accountId,
    String? categoryId,
  }) async {
    final start = DateTime(year, month);
    final end = month == 12 ? DateTime(year + 1, 1) : DateTime(year, month + 1);
    final amountSum = transactions.amount.sum();
    Expression<bool> predicate =
        transactions.isDeleted.equals(false) &
        transactions.date.isBiggerOrEqualValue(start) &
        transactions.date.isSmallerThanValue(end) &
        transactions.type.equals(type);
    if (accountId != null) {
      predicate = predicate & transactions.accountId.equals(accountId);
    }
    if (categoryId != null) {
      predicate = predicate & transactions.categoryId.equals(categoryId);
    }

    final query = selectOnly(transactions)
      ..addColumns([amountSum])
      ..where(predicate);

    final row = await query.getSingleOrNull();
    return row?.read(amountSum) ?? 0.0;
  }

  Future<MonthlyTotalsRow> monthlyTotalsForAccount(
    int year,
    int month, {
    required String accountId,
  }) {
    return monthlyTotals(year, month, accountId: accountId);
  }

  Stream<List<Transaction>> watchAccountTransactionsByMonth(
    int year,
    int month, {
    required String accountId,
  }) {
    return watchByMonth(year, month, accountId: accountId);
  }

  Stream<List<MonthlyTotalsPoint>> monthlyTotalsRangeForAccount(
    int startYear,
    int startMonth,
    int endYear,
    int endMonth, {
    required String accountId,
  }) {
    return monthlyTotalsRange(
      startYear,
      startMonth,
      endYear,
      endMonth,
      accountId: accountId,
    );
  }
}
