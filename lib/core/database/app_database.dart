import 'package:drift/drift.dart';
import 'package:finora/core/database/app_database.dart' as prefix0;

import 'package:finora/core/database/daos/account_dao.dart';
import 'package:finora/core/database/daos/category_dao.dart';
import 'package:finora/core/database/daos/transaction_dao.dart';
import 'package:finora/core/database/database_connection.dart';
import 'package:finora/core/database/tables/accounts_table.dart';
import 'package:finora/core/database/tables/categories_table.dart';
import 'package:finora/core/database/tables/transactions_table.dart';

part 'app_database.g.dart';

QueryExecutor _openConnection() => openDatabaseConnection();

@DriftDatabase(
  tables: [Accounts, Categories, Transactions],
  daos: [AccountDao, CategoryDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;
}
