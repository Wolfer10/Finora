import 'package:finora/features/goals/domain/goal.dart';
import 'package:finora/features/goals/domain/goal_contribution.dart';

abstract class GoalRepository {
  Future<void> createGoal(Goal goal);
  Future<void> updateGoal(Goal goal);
  Future<void> softDeleteGoal(String goalId);
  Stream<List<Goal>> watchGoals({bool activeOnly = true});
  Stream<List<Goal>> watchGoalsActive();

  Future<void> addContribution(GoalContribution contribution);
  Future<void> updateContribution(GoalContribution contribution);
  Future<void> softDeleteContribution(String contributionId);
  Stream<List<GoalContribution>> watchContributionsByGoal(
    String goalId, {
    bool activeOnly = true,
  });
}
