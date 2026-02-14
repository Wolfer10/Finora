import 'package:drift/drift.dart';

import 'package:finora/core/database/tables/accounts_table.dart';
import 'package:finora/core/database/tables/categories_table.dart';

@TableIndex(name: 'idx_transactions_date', columns: {#date})
@TableIndex(name: 'idx_transactions_account_id', columns: {#accountId})
@TableIndex(name: 'idx_transactions_category_id', columns: {#categoryId})
@TableIndex(
  name: 'idx_transactions_transfer_group_id',
  columns: {#transferGroupId},
)
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get transferGroupId => text().nullable()();
  TextColumn get recurringRuleId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

}
