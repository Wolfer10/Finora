import 'package:finora/features/goals/domain/goal.dart';

class GoalCompletionEvaluation {
  const GoalCompletionEvaluation({
    required this.completed,
    required this.completedAt,
  });

  final bool completed;
  final DateTime? completedAt;
}

class GoalCompletionService {
  GoalCompletionEvaluation evaluateCompletion({
    required Goal goal,
    required double savedAmount,
    required DateTime now,
  }) {
    if (savedAmount >= goal.targetAmount) {
      return GoalCompletionEvaluation(
        completed: true,
        completedAt: goal.completedAt ?? now,
      );
    }
    return const GoalCompletionEvaluation(
      completed: false,
      completedAt: null,
    );
  }
}
