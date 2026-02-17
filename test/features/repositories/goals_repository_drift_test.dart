import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/goal_dao.dart';
import 'package:finora/core/errors/repository_error.dart';
import 'package:finora/features/goals/data/goal_repository_drift.dart';
import 'package:finora/features/goals/domain/goal.dart' as domain;
import 'package:finora/features/goals/domain/goal_contribution.dart' as domain;

void main() {
  late AppDatabase db;
  late GoalRepositoryDrift repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = GoalRepositoryDrift(GoalDao(db));
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  test('goal and contribution lifecycle', () async {
    final now = DateTime(2026, 2, 17, 12, 0);
    await repository.createGoal(
      domain.Goal(
        id: 'goal-1',
        name: 'Emergency Fund',
        targetAmount: 5000,
        savedAmount: 0,
        priority: domain.GoalPriority.high,
        completed: false,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    final goals = await repository.watchGoalsActive().first;
    expect(goals, hasLength(1));
    expect(goals.single.name, 'Emergency Fund');

    await repository.addContribution(
      domain.GoalContribution(
        id: 'contrib-1',
        goalId: 'goal-1',
        amount: 250,
        date: now,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    );

    final contributions =
        await repository.watchContributionsByGoal('goal-1').first;
    expect(contributions, hasLength(1));
    expect(contributions.single.amount, 250);

    await repository.softDeleteContribution('contrib-1');
    final afterContributionDelete =
        await repository.watchContributionsByGoal('goal-1').first;
    expect(afterContributionDelete, isEmpty);

    await repository.softDeleteGoal('goal-1');
    final afterGoalDelete = await repository.watchGoalsActive().first;
    expect(afterGoalDelete, isEmpty);
  });

  test('createGoal wraps DAO failure as RepositoryError', () async {
    final failingRepository = GoalRepositoryDrift(
      _ThrowingGoalDaoForCreate(db),
    );
    final now = DateTime(2026, 2, 17, 12, 0);

    await expectLater(
      failingRepository.createGoal(
        domain.Goal(
          id: 'goal-fail',
          name: 'Fail',
          targetAmount: 100,
          savedAmount: 0,
          priority: domain.GoalPriority.medium,
          completed: false,
          completedAt: null,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      ),
      throwsA(isA<RepositoryError>()),
    );
  });

  test('watchGoals wraps stream failure as RepositoryError', () async {
    final failingRepository = GoalRepositoryDrift(
      _ThrowingGoalDaoForWatch(db),
    );

    await expectLater(
      failingRepository.watchGoalsActive().first,
      throwsA(isA<RepositoryError>()),
    );
  });
}

class _ThrowingGoalDaoForCreate extends GoalDao {
  _ThrowingGoalDaoForCreate(super.db);

  @override
  Future<void> upsertGoal(GoalsCompanion companion) {
    throw StateError('create failed');
  }
}

class _ThrowingGoalDaoForWatch extends GoalDao {
  _ThrowingGoalDaoForWatch(super.db);

  @override
  Stream<List<Goal>> watchGoals({bool activeOnly = true}) {
    return Stream<List<Goal>>.error(StateError('watch failed'));
  }
}
