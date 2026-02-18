import 'package:drift/drift.dart';
import 'package:finora/core/database/app_database.dart' as prefix0;

import 'package:finora/core/database/daos/account_dao.dart';
import 'package:finora/core/database/daos/category_dao.dart';
import 'package:finora/core/database/daos/goal_dao.dart';
import 'package:finora/core/database/daos/transaction_dao.dart';
import 'package:finora/core/database/database_connection.dart';
import 'package:finora/core/database/tables/accounts_table.dart';
import 'package:finora/core/database/tables/categories_table.dart';
import 'package:finora/core/database/tables/goal_contributions_table.dart';
import 'package:finora/core/database/tables/goals_table.dart';
import 'package:finora/core/database/tables/transactions_table.dart';

part 'app_database.g.dart';

QueryExecutor _openConnection() => openDatabaseConnection();

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, Goals, GoalContributions],
  daos: [AccountDao, CategoryDao, TransactionDao, GoalDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // S5.1: table maintained via SQL to avoid requiring a codegen step.
          await customStatement('''
            CREATE TABLE IF NOT EXISTS monthly_predictions (
              id TEXT PRIMARY KEY,
              year INTEGER NOT NULL,
              month INTEGER NOT NULL,
              category_id TEXT NOT NULL REFERENCES categories(id),
              predicted_amount REAL NOT NULL,
              note TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              is_deleted INTEGER NOT NULL DEFAULT 0,
              UNIQUE(year, month, category_id)
            )
          ''');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_monthly_predictions_year_month ON monthly_predictions(year, month)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_monthly_predictions_category_id ON monthly_predictions(category_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_monthly_predictions_is_deleted ON monthly_predictions(is_deleted)',
          );
          // S17.4: recurring rules storage for manual/scheduled generation.
          await customStatement('''
            CREATE TABLE IF NOT EXISTS recurring_rules (
              id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              account_id TEXT NOT NULL REFERENCES accounts(id),
              category_id TEXT REFERENCES categories(id),
              to_account_id TEXT REFERENCES accounts(id),
              amount REAL NOT NULL,
              note TEXT,
              start_date TEXT NOT NULL,
              end_date TEXT,
              next_run_at TEXT NOT NULL,
              recurrence_unit TEXT NOT NULL,
              recurrence_interval INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              is_deleted INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_recurring_rules_next_run_at ON recurring_rules(next_run_at)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_recurring_rules_is_deleted ON recurring_rules(is_deleted)',
          );
          // S6.1: single-row app settings table.
          await customStatement('''
            CREATE TABLE IF NOT EXISTS app_settings (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              currency_code TEXT NOT NULL,
              currency_symbol TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      );
}
