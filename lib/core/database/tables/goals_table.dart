import 'package:drift/drift.dart';

@TableIndex(name: 'idx_goals_priority', columns: {#priority})
@TableIndex(name: 'idx_goals_completed', columns: {#completed})
@TableIndex(name: 'idx_goals_is_deleted', columns: {#isDeleted})
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0))();
  IntColumn get priority => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
