import 'package:finora/features/goals/domain/goal.dart';
import 'package:finora/features/goals/domain/goal_completion_service.dart';
import 'package:finora/features/goals/domain/goal_contribution.dart';
import 'package:finora/features/goals/domain/goal_repository.dart';

class AddGoalContributionInput {
  const AddGoalContributionInput({
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String goalId;
  final double amount;
  final DateTime date;
  final String? note;
}

class AddGoalContributionResult {
  const AddGoalContributionResult({
    required this.contribution,
    required this.updatedGoal,
  });

  final GoalContribution contribution;
  final Goal updatedGoal;
}

class AddGoalContributionUseCase {
  AddGoalContributionUseCase(
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

  Future<AddGoalContributionResult> call(AddGoalContributionInput input) async {
    if (input.amount <= 0) {
      throw ArgumentError.value(input.amount, 'amount', 'must be greater than 0');
    }

    final goals = await _repository.watchGoalsActive().first;
    Goal? goal;
    for (final item in goals) {
      if (item.id == input.goalId) {
        goal = item;
        break;
      }
    }
    if (goal == null) {
      throw StateError('Goal not found: ${input.goalId}');
    }

    final timestamp = _now();
    final contribution = GoalContribution(
      id: _idGenerator(),
      goalId: input.goalId,
      amount: input.amount,
      date: input.date,
      note: input.note,
      createdAt: timestamp,
      updatedAt: timestamp,
      isDeleted: false,
    );
    await _repository.addContribution(contribution);

    final savedAmount = goal.savedAmount + input.amount;
    final completion = _completionService.evaluateCompletion(
      goal: goal,
      savedAmount: savedAmount,
      now: timestamp,
    );
    final updatedGoal = goal.copyWith(
      savedAmount: savedAmount,
      completed: completion.completed,
      completedAt: completion.completedAt,
      updatedAt: timestamp,
    );
    await _repository.updateGoal(updatedGoal);

    return AddGoalContributionResult(
      contribution: contribution,
      updatedGoal: updatedGoal,
    );
  }

  static String _defaultIdGenerator() {
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    return 'goal-contrib-$microseconds';
  }
}
