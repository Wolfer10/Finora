import 'package:drift/drift.dart';

import 'package:finora/core/database/tables/goals_table.dart';

@TableIndex(name: 'idx_goal_contributions_goal_id', columns: {#goalId})
@TableIndex(name: 'idx_goal_contributions_date', columns: {#date})
@TableIndex(name: 'idx_goal_contributions_is_deleted', columns: {#isDeleted})
class GoalContributions extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
