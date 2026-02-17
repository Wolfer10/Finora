import 'package:finora/features/goals/domain/goal.dart';
import 'package:finora/features/goals/domain/goal_completion_service.dart';
import 'package:finora/features/goals/domain/goal_contribution.dart';
import 'package:finora/features/goals/domain/goal_repository.dart';

class AllocateSurplusInput {
  const AllocateSurplusInput({
    required this.surplusAmount,
    required this.date,
    this.note,
  });

  final double surplusAmount;
  final DateTime date;
  final String? note;
}

class AllocateSurplusResult {
  const AllocateSurplusResult({
    required this.createdContributions,
    required this.allocatedAmount,
    required this.remainingSurplus,
  });

  final List<GoalContribution> createdContributions;
  final double allocatedAmount;
  final double remainingSurplus;
}

class AllocateSurplusUseCase {
  AllocateSurplusUseCase(
    this._repository,
    this._completionService, {
    DateTime Function()? now,
    String Function()? idGenerator,
  })  : _now = now ?? DateTime.now,
        _idGenerator = idGenerator ?? _defaultIdGenerator;

  final GoalRepository _repository;
  final GoalCompletionService _completionService;
  final DateTime Function() _now;
  final String Function() _idGenerator;

  Future<AllocateSurplusResult> call(AllocateSurplusInput input) async {
    if (input.surplusAmount <= 0) {
      return const AllocateSurplusResult(
        createdContributions: [],
        allocatedAmount: 0,
        remainingSurplus: 0,
      );
    }

    final now = _now();
    var remaining = input.surplusAmount;
    final createdContributions = <GoalContribution>[];

    final activeGoals = await _repository.watchGoalsActive().first;
    final goals = activeGoals
        .where((goal) => !goal.completed && goal.targetAmount > goal.savedAmount)
        .toList()
      ..sort((a, b) {
        final priorityCompare = _priorityOrder(a.priority).compareTo(
          _priorityOrder(b.priority),
        );
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        return a.createdAt.compareTo(b.createdAt);
      });

    for (final goal in goals) {
      if (remaining <= 0) {
        break;
      }

      final missingAmount = goal.targetAmount - goal.savedAmount;
      if (missingAmount <= 0) {
        continue;
      }

      final allocation = remaining < missingAmount ? remaining : missingAmount;
      final contribution = GoalContribution(
        id: _idGenerator(),
        goalId: goal.id,
        amount: allocation,
        date: input.date,
        note: input.note,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );
      await _repository.addContribution(contribution);

      final newSavedAmount = goal.savedAmount + allocation;
      final completion = _completionService.evaluateCompletion(
        goal: goal,
        savedAmount: newSavedAmount,
        now: now,
      );
      final updatedGoal = goal.copyWith(
        savedAmount: newSavedAmount,
        completed: completion.completed,
        completedAt: completion.completedAt,
        updatedAt: now,
      );
      await _repository.updateGoal(updatedGoal);

      remaining -= allocation;
      createdContributions.add(contribution);
    }

    final allocated = input.surplusAmount - remaining;
    return AllocateSurplusResult(
      createdContributions: List.unmodifiable(createdContributions),
      allocatedAmount: allocated,
      remainingSurplus: remaining,
    );
  }

  static int _priorityOrder(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.high:
        return 0;
      case GoalPriority.medium:
        return 1;
      case GoalPriority.low:
        return 2;
    }
  }

  static String _defaultIdGenerator() {
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    return 'goal-contrib-$microseconds';
  }
}
