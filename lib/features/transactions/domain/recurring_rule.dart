import 'package:finora/features/transactions/domain/transaction.dart';

enum RecurrenceUnit { daily, weekly, monthly }

class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.type,
    required this.accountId,
    required this.amount,
    required this.startDate,
    required this.nextRunAt,
    required this.recurrenceUnit,
    required this.recurrenceInterval,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    this.categoryId,
    this.toAccountId,
    this.note,
    this.endDate,
  });

  final String id;
  final TransactionType type;
  final String accountId;
  final String? categoryId;
  final String? toAccountId;
  final double amount;
  final String? note;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextRunAt;
  final RecurrenceUnit recurrenceUnit;
  final int recurrenceInterval;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  RecurringRule copyWith({
    String? id,
    TransactionType? type,
    String? accountId,
    String? categoryId,
    String? toAccountId,
    double? amount,
    String? note,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextRunAt,
    RecurrenceUnit? recurrenceUnit,
    int? recurrenceInterval,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      toAccountId: toAccountId ?? this.toAccountId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      recurrenceUnit: recurrenceUnit ?? this.recurrenceUnit,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
