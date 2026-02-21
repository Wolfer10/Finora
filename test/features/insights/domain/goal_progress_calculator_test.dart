import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/goals/domain/goal.dart';
import 'package:finora/features/insights/domain/goal_progress_calculator.dart';

void main() {
  test('calculates progress and remaining amount and skips archived by default',
      () {
    const calculator = GoalProgressCalculator();
    final now = DateTime(2026, 2, 1);

    final goals = [
      Goal(
        id: 'goal-1',
        name: 'Emergency fund',
        targetAmount: 1000,
        savedAmount: 250,
        priority: GoalPriority.high,
        completed: false,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Goal(
        id: 'goal-2',
        name: 'Vacation',
        targetAmount: 500,
        savedAmount: 700,
        priority: GoalPriority.medium,
        completed: false,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Goal(
        id: 'goal-3',
        name: 'Archived goal',
        targetAmount: 300,
        savedAmount: 100,
        priority: GoalPriority.low,
        completed: false,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: true,
      ),
    ];

    final active = calculator.calculate(goals: goals);
    final all = calculator.calculate(goals: goals, includeArchived: true);

    expect(active, hasLength(2));
    expect(all, hasLength(3));

    final emergency = active.firstWhere((item) => item.goalId == 'goal-1');
    final vacation = active.firstWhere((item) => item.goalId == 'goal-2');

    expect(emergency.progress, 0.25);
    expect(emergency.remainingAmount, 750);
    expect(emergency.completed, false);

    expect(vacation.progress, 1);
    expect(vacation.remainingAmount, 0);
    expect(vacation.completed, true);
  });
}
