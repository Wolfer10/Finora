import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/goals/domain/goal.dart';
import 'package:finora/features/goals/domain/goal_completion_service.dart';

void main() {
  late GoalCompletionService service;
  late Goal goal;

  setUp(() {
    service = GoalCompletionService();
    goal = Goal(
      id: 'goal-1',
      name: 'Emergency Fund',
      targetAmount: 1000,
      savedAmount: 400,
      priority: GoalPriority.high,
      completed: false,
      completedAt: null,
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 2, 1),
      isDeleted: false,
    );
  });

  test('marks completed at equal target', () {
    final now = DateTime(2026, 2, 20);
    final result = service.evaluateCompletion(
      goal: goal,
      savedAmount: 1000,
      now: now,
    );

    expect(result.completed, isTrue);
    expect(result.completedAt, now);
  });

  test('marks completed at over target', () {
    final now = DateTime(2026, 2, 20);
    final result = service.evaluateCompletion(
      goal: goal,
      savedAmount: 1300,
      now: now,
    );

    expect(result.completed, isTrue);
    expect(result.completedAt, now);
  });

  test('keeps uncompleted state under target', () {
    final result = service.evaluateCompletion(
      goal: goal,
      savedAmount: 999.99,
      now: DateTime(2026, 2, 20),
    );

    expect(result.completed, isFalse);
    expect(result.completedAt, isNull);
  });
}
