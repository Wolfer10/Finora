class MonthlyPrediction {
  const MonthlyPrediction({
    required this.id,
    required this.year,
    required this.month,
    required this.categoryId,
    required this.predictedAmount,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  final String id;
  final int year;
  final int month;
  final String categoryId;
  final double predictedAmount;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyPrediction copyWith({
    String? id,
    int? year,
    int? month,
    String? categoryId,
    double? predictedAmount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyPrediction(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      categoryId: categoryId ?? this.categoryId,
      predictedAmount: predictedAmount ?? this.predictedAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
