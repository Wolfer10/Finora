import 'package:drift/drift.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/tables/accounts_table.dart';
import 'package:finora/core/database/tables/transactions_table.dart';

part 'account_dao.g.dart';

class AccountBalanceRow {
  const AccountBalanceRow({
    required this.accountId,
    required this.balance,
  });

  final String accountId;
  final double balance;
}

@DriftAccessor(tables: [Accounts, Transactions])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<void> upsert(AccountsCompanion companion) async {
    await into(accounts).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteById(String id, DateTime updatedAt) async {
    await (update(accounts)..where((tbl) => tbl.id.equals(id))).write(
      AccountsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Stream<List<Account>> watchAll({bool activeOnly = true}) {
    return (select(accounts)
          ..where((tbl) {
            if (!activeOnly) {
              return const Constant(true);
            }
            return tbl.isDeleted.equals(false);
          })
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }

  Stream<List<Account>> watchAllActive() {
    return watchAll(activeOnly: true);
  }

  Stream<List<AccountBalanceRow>> watchBalances({bool activeOnly = true}) {
    final whereAccount = activeOnly ? 'WHERE a.is_deleted = 0' : '';
    final sql = '''
            SELECT
              a.id AS account_id,
              a.initial_balance + COALESCE(SUM(
                CASE
                  WHEN t.type = 'income' THEN t.amount
                  WHEN t.type = 'expense' THEN -t.amount
                  ELSE 0
                END
              ), 0) AS balance
            FROM accounts a
            LEFT JOIN transactions t
              ON t.account_id = a.id
             AND t.is_deleted = 0
            $whereAccount
            GROUP BY a.id, a.initial_balance
            ORDER BY a.name ASC
            ''';

    return customSelect(
      sql,
      readsFrom: {accounts, transactions},
    ).watch().map(
          (rows) => rows
              .map(
                (row) => AccountBalanceRow(
                  accountId: row.read<String>('account_id'),
                  balance: row.read<double>('balance'),
                ),
              )
              .toList(growable: false),
        );
  }

  Stream<double> watchAccountBalance(String accountId) {
    const sql = '''
                SELECT
                  a.initial_balance + COALESCE(SUM(
                    CASE
                      WHEN t.type = 'income' THEN t.amount
                      WHEN t.type = 'expense' THEN -t.amount
                      ELSE 0
                    END
                  ), 0) AS balance
                FROM accounts a
                LEFT JOIN transactions t
                  ON t.account_id = a.id
                 AND t.is_deleted = 0
                WHERE a.id = ?
                GROUP BY a.id, a.initial_balance
                ''';

    return customSelect(
      sql,
      variables: [Variable.withString(accountId)],
      readsFrom: {accounts, transactions},
    ).watchSingleOrNull().map((row) => row?.read<double>('balance') ?? 0.0);
  }
}
