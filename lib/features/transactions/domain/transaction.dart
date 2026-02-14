enum TransactionType { income, expense, transfer }

class Transaction {
  const Transaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    this.note,
    this.transferGroupId,
    this.recurringRuleId,
  });

  final String id;
  final String accountId;
  final String categoryId;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? note;
  final String? transferGroupId;
  final String? recurringRuleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Transaction copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    DateTime? date,
    String? note,
    String? transferGroupId,
    String? recurringRuleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
