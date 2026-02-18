import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/goals/domain/allocate_surplus_use_case.dart';
import 'package:finora/features/goals/domain/calculate_surplus_use_case.dart';
import 'package:finora/features/goals/domain/goal.dart';
import 'package:finora/features/goals/domain/goal_completion_service.dart';
import 'package:finora/features/goals/domain/goal_contribution.dart';
import 'package:finora/features/goals/domain/goal_repository.dart';
import 'package:finora/features/transactions/domain/transaction.dart';
import 'package:finora/features/transactions/domain/transaction_repository.dart';

void main() {
  test('CalculateSurplusUseCase returns monthly net', () async {
    final useCase = CalculateSurplusUseCase(
      _FakeTransactionRepository(
        const MonthlyTotals(incomeTotal: 2300, expenseTotal: 1800),
      ),
    );

    final result = await useCase(
      const CalculateSurplusInput(year: 2026, month: 2),
    );

    expect(result, 500);
  });

  test('AllocateSurplusUseCase does nothing when surplus <= 0', () async {
    final repository = _FakeGoalRepository();
    final useCase = AllocateSurplusUseCase(
      repository,
      GoalCompletionService(),
      now: () => DateTime(2026, 2, 17),
      idGenerator: () => 'contrib-x',
    );

    final result = await useCase(
      AllocateSurplusInput(
        surplusAmount: 0,
        date: DateTime(2026, 2, 17),
      ),
    );

    expect(result.allocatedAmount, 0);
    expect(result.createdContributions, isEmpty);
    expect(repository.updatedGoals, isEmpty);
  });

  test('AllocateSurplusUseCase allocates by priority and updates goals', () async {
    final repository = _FakeGoalRepository();
    var idx = 0;
    final ids = ['c-1', 'c-2'];
    final useCase = AllocateSurplusUseCase(
      repository,
      GoalCompletionService(),
      now: () => DateTime(2026, 2, 17, 8),
      idGenerator: () => ids[idx++],
    );

    final result = await useCase(
      AllocateSurplusInput(
        surplusAmount: 600,
        date: DateTime(2026, 2, 17),
      ),
    );

    expect(result.allocatedAmount, 600);
    expect(result.remainingSurplus, 0);
    expect(result.createdContributions.map((c) => c.goalId), ['goal-high', 'goal-medium']);
    expect(result.createdContributions.map((c) => c.amount), [300, 300]);
    expect(repository.updatedGoals, hasLength(2));
    expect(repository.updatedGoals.first.completed, isTrue);
  });
}

class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository(this._totals);

  final MonthlyTotals _totals;

  @override
  Future<MonthlyTotals> monthlyTotals(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  }) async {
    return _totals;
  }

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<double> monthlyExpenseTotal(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<double> monthlyIncomeTotal(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> softDeleteByTransferGroup(String transferGroupId) async {}

  @override
  Future<List<Transaction>> listByTransferGroup(String transferGroupId) async {
    return const [];
  }

  @override
  Future<void> update(Transaction transaction) async {}

  @override
  Stream<List<Transaction>> watchByMonth(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Transaction>> watchRecent(int limit, {String? accountId}) {
    throw UnimplementedError();
  }
}

class _FakeGoalRepository implements GoalRepository {
  _FakeGoalRepository() {
    _goals = [
      Goal(
        id: 'goal-high',
        name: 'Emergency',
        targetAmount: 1000,
        savedAmount: 700,
        priority: GoalPriority.high,
        completed: false,
        completedAt: null,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        isDeleted: false,
      ),
      Goal(
        id: 'goal-medium',
        name: 'Vacation',
        targetAmount: 2000,
        savedAmount: 1200,
        priority: GoalPriority.medium,
        completed: false,
        completedAt: null,
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
        isDeleted: false,
      ),
    ];
  }

  late List<Goal> _goals;
  final List<GoalContribution> createdContributions = [];
  final List<Goal> updatedGoals = [];

  @override
  Future<void> addContribution(GoalContribution contribution) async {
    createdContributions.add(contribution);
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
    updatedGoals.add(goal);
    _goals = _goals.map((item) => item.id == goal.id ? goal : item).toList();
  }

  @override
  Stream<List<GoalContribution>> watchContributionsByGoal(
    String goalId, {
    bool activeOnly = true,
  }) {
    return Stream.value(
      createdContributions.where((item) => item.goalId == goalId).toList(),
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
