import 'package:finora/features/goals/domain/goal.dart';

class GoalProgressItem {
  const GoalProgressItem({
    required this.goalId,
    required this.goalName,
    required this.targetAmount,
    required this.savedAmount,
    required this.remainingAmount,
    required this.progress,
    required this.completed,
    required this.archived,
  });

  final String goalId;
  final String goalName;
  final double targetAmount;
  final double savedAmount;
  final double remainingAmount;
  final double progress;
  final bool completed;
  final bool archived;
}

class GoalProgressCalculator {
  const GoalProgressCalculator();

  List<GoalProgressItem> calculate({
    required List<Goal> goals,
    bool includeArchived = false,
  }) {
    final items = <GoalProgressItem>[];

    for (final goal in goals) {
      if (!includeArchived && goal.isDeleted) {
        continue;
      }

      final normalizedTarget = goal.targetAmount <= 0 ? 0.0 : goal.targetAmount;
      final normalizedSaved = goal.savedAmount < 0 ? 0.0 : goal.savedAmount;
      final remaining = normalizedTarget - normalizedSaved;
      final clampedRemaining = remaining > 0 ? remaining : 0.0;
      final computedCompleted = goal.completed ||
          (normalizedTarget > 0 && normalizedSaved >= normalizedTarget);
      final progress = normalizedTarget <= 0
          ? (computedCompleted ? 1.0 : 0.0)
          : (normalizedSaved / normalizedTarget).clamp(0.0, 1.0);

      items.add(
        GoalProgressItem(
          goalId: goal.id,
          goalName: goal.name,
          targetAmount: goal.targetAmount,
          savedAmount: goal.savedAmount,
          remainingAmount: clampedRemaining,
          progress: progress,
          completed: computedCompleted,
          archived: goal.isDeleted,
        ),
      );
    }

    return items;
  }
}
