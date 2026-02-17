import 'package:drift/drift.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/goal_dao.dart';
import 'package:finora/core/database/enum_codecs.dart';
import 'package:finora/core/errors/repository_error.dart';
import 'package:finora/features/goals/domain/goal.dart' as domain;
import 'package:finora/features/goals/domain/goal_contribution.dart' as domain;
import 'package:finora/features/goals/domain/goal_repository.dart';

class GoalRepositoryDrift implements GoalRepository {
  GoalRepositoryDrift(this._dao);

  final GoalDao _dao;

  @override
  Future<void> createGoal(domain.Goal goal) async {
    await guardRepositoryCall('GoalRepository.createGoal', () {
      return _dao.upsertGoal(_toGoalCompanion(goal));
    });
  }

  @override
  Future<void> updateGoal(domain.Goal goal) async {
    await guardRepositoryCall('GoalRepository.updateGoal', () {
      return _dao.upsertGoal(_toGoalCompanion(goal));
    });
  }

  @override
  Future<void> softDeleteGoal(String goalId) async {
    await guardRepositoryCall('GoalRepository.softDeleteGoal', () {
      return _dao.softDeleteGoalById(goalId, DateTime.now());
    });
  }

  @override
  Stream<List<domain.Goal>> watchGoals({bool activeOnly = true}) {
    return guardRepositoryStream('GoalRepository.watchGoals', () {
      return _dao.watchGoals(activeOnly: activeOnly).map(
            (rows) => rows.map(_toGoalDomain).toList(growable: false),
          );
    });
  }

  @override
  Stream<List<domain.Goal>> watchGoalsActive() {
    return watchGoals(activeOnly: true);
  }

  @override
  Future<void> addContribution(domain.GoalContribution contribution) async {
    await guardRepositoryCall('GoalRepository.addContribution', () {
      return _dao.upsertContribution(_toContributionCompanion(contribution));
    });
  }

  @override
  Future<void> updateContribution(domain.GoalContribution contribution) async {
    await guardRepositoryCall('GoalRepository.updateContribution', () {
      return _dao.upsertContribution(_toContributionCompanion(contribution));
    });
  }

  @override
  Future<void> softDeleteContribution(String contributionId) async {
    await guardRepositoryCall('GoalRepository.softDeleteContribution', () {
      return _dao.softDeleteContributionById(contributionId, DateTime.now());
    });
  }

  @override
  Stream<List<domain.GoalContribution>> watchContributionsByGoal(
    String goalId, {
    bool activeOnly = true,
  }) {
    return guardRepositoryStream('GoalRepository.watchContributionsByGoal', () {
      return _dao
          .watchContributionsByGoal(goalId, activeOnly: activeOnly)
          .map((rows) => rows.map(_toContributionDomain).toList(growable: false));
    });
  }

  GoalsCompanion _toGoalCompanion(domain.Goal goal) {
    return GoalsCompanion.insert(
      id: goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      savedAmount: Value(goal.savedAmount),
      priority: encodeGoalPriority(goal.priority),
      completed: Value(goal.completed),
      completedAt: Value(goal.completedAt),
      createdAt: goal.createdAt,
      updatedAt: goal.updatedAt,
      isDeleted: Value(goal.isDeleted),
    );
  }

  GoalContributionsCompanion _toContributionCompanion(
    domain.GoalContribution contribution,
  ) {
    return GoalContributionsCompanion.insert(
      id: contribution.id,
      goalId: contribution.goalId,
      amount: contribution.amount,
      date: contribution.date,
      note: Value(contribution.note),
      createdAt: contribution.createdAt,
      updatedAt: contribution.updatedAt,
      isDeleted: Value(contribution.isDeleted),
    );
  }

  domain.Goal _toGoalDomain(Goal row) {
    return domain.Goal(
      id: row.id,
      name: row.name,
      targetAmount: row.targetAmount,
      savedAmount: row.savedAmount,
      priority: decodeGoalPriority(row.priority),
      completed: row.completed,
      completedAt: row.completedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
    );
  }

  domain.GoalContribution _toContributionDomain(GoalContribution row) {
    return domain.GoalContribution(
      id: row.id,
      goalId: row.goalId,
      amount: row.amount,
      date: row.date,
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
    );
  }
}
