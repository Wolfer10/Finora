import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finora/core/database/app_database.dart' as prefix0;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:finora/core/database/daos/account_dao.dart';
import 'package:finora/core/database/daos/category_dao.dart';
import 'package:finora/core/database/daos/transaction_dao.dart';
import 'package:finora/core/database/tables/accounts_table.dart';
import 'package:finora/core/database/tables/categories_table.dart';
import 'package:finora/core/database/tables/transactions_table.dart';

part 'app_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'finora.sqlite'));
    return NativeDatabase(file);
  });
}

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
