enum GoalPriority { high, medium, low }

const Object _unsetCompletedAt = Object();

class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.priority,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    this.completedAt,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final GoalPriority priority;
  final bool completed;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    GoalPriority? priority,
    bool? completed,
    Object? completedAt = _unsetCompletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      completedAt: completedAt == _unsetCompletedAt
          ? this.completedAt
          : completedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
