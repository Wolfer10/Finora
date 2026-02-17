import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/goals/domain/add_goal_contribution_use_case.dart';
import 'package:finora/features/goals/domain/goal.dart';
import 'package:finora/features/goals/domain/goal_completion_service.dart';
import 'package:finora/features/goals/domain/goal_contribution.dart';
import 'package:finora/features/goals/domain/goal_repository.dart';

void main() {
  late _FakeGoalRepository repository;
  late AddGoalContributionUseCase useCase;
  late DateTime fixedNow;

  setUp(() {
    repository = _FakeGoalRepository();
    fixedNow = DateTime(2026, 2, 17, 13, 0, 0);
    useCase = AddGoalContributionUseCase(
      repository,
      GoalCompletionService(),
      now: () => fixedNow,
      idGenerator: () => 'contrib-1',
    );
  });

  test('rejects amount <= 0', () async {
    await expectLater(
      () => useCase(
        AddGoalContributionInput(
          goalId: 'goal-1',
          amount: 0,
          date: DateTime(2026, 2, 17),
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(repository.contributionsAdded, isEmpty);
  });

  test('inserts contribution and updates goal completion', () async {
    final result = await useCase(
      AddGoalContributionInput(
        goalId: 'goal-1',
        amount: 200,
        date: DateTime(2026, 2, 17),
        note: 'Manual top-up',
      ),
    );

    expect(result.contribution.id, 'contrib-1');
    expect(result.contribution.amount, 200);
    expect(result.updatedGoal.savedAmount, 1000);
    expect(result.updatedGoal.completed, isTrue);
    expect(result.updatedGoal.completedAt, fixedNow);

    expect(repository.contributionsAdded, hasLength(1));
    expect(repository.goalsUpdated, hasLength(1));
    expect(repository.goalsUpdated.single.completed, isTrue);
  });
}

class _FakeGoalRepository implements GoalRepository {
  _FakeGoalRepository() {
    _goals = [
      Goal(
        id: 'goal-1',
        name: 'Emergency Fund',
        targetAmount: 1000,
        savedAmount: 800,
        priority: GoalPriority.high,
        completed: false,
        completedAt: null,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        isDeleted: false,
      ),
    ];
  }

  late List<Goal> _goals;
  final List<GoalContribution> contributionsAdded = [];
  final List<Goal> goalsUpdated = [];

  @override
  Future<void> addContribution(GoalContribution contribution) async {
    contributionsAdded.add(contribution);
  }

  @override
  Future<void> createGoal(Goal goal) async {}

  @override
  Future<void> softDeleteContribution(String contributionId) async {}

  @override
  Future<void> softDeleteGoal(String goalId) async {}

  @override
  Future<void> updateContribution(GoalContribution contribution) async {}

  @override
  Future<void> updateGoal(Goal goal) async {
    goalsUpdated.add(goal);
    _goals = _goals.map((item) => item.id == goal.id ? goal : item).toList();
  }

  @override
  Stream<List<GoalContribution>> watchContributionsByGoal(
    String goalId, {
    bool activeOnly = true,
  }) {
    return Stream.value(
      contributionsAdded.where((item) => item.goalId == goalId).toList(),
    );
  }

  @override
  Stream<List<Goal>> watchGoals({bool activeOnly = true}) {
    return Stream.value(_goals);
  }

  @override
  Stream<List<Goal>> watchGoalsActive() {
    return Stream.value(_goals.where((item) => !item.isDeleted).toList());
  }
}
