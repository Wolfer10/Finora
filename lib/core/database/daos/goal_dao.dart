import 'package:drift/drift.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/tables/goal_contributions_table.dart';
import 'package:finora/core/database/tables/goals_table.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals, GoalContributions])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Future<void> upsertGoal(GoalsCompanion companion) async {
    await into(goals).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteGoalById(String id, DateTime updatedAt) async {
    await (update(goals)..where((tbl) => tbl.id.equals(id))).write(
      GoalsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Stream<List<Goal>> watchGoals({bool activeOnly = true}) {
    return (select(goals)
          ..where((tbl) {
            if (!activeOnly) {
              return const Constant(true);
            }
            return tbl.isDeleted.equals(false);
          })
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.priority),
            (tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .watch();
  }

  Future<void> upsertContribution(GoalContributionsCompanion companion) async {
    await into(goalContributions).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteContributionById(String id, DateTime updatedAt) async {
    await (update(goalContributions)..where((tbl) => tbl.id.equals(id))).write(
      GoalContributionsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Stream<List<GoalContribution>> watchContributionsByGoal(
    String goalId, {
    bool activeOnly = true,
  }) {
    return (select(goalContributions)
          ..where((tbl) {
            var predicate = tbl.goalId.equals(goalId);
            if (activeOnly) {
              predicate = predicate & tbl.isDeleted.equals(false);
            }
            return predicate;
          })
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.date),
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .watch();
  }
}
