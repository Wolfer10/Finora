import 'package:finora/features/transactions/domain/transaction.dart';
import 'package:finora/features/transactions/domain/transaction_repository.dart';

class UpdateExpenseTransactionInput {
  const UpdateExpenseTransactionInput({
    required this.transactionId,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String transactionId;
  final String accountId;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String? note;
}

class UpdateExpenseTransactionUseCase {
  UpdateExpenseTransactionUseCase(
    this._repository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final TransactionRepository _repository;
  final DateTime Function() _now;

  Future<Transaction> call(
    Transaction original,
    UpdateExpenseTransactionInput input,
  ) async {
    if (input.amount <= 0) {
      throw ArgumentError.value(input.amount, 'amount', 'must be greater than 0');
    }
    if (original.id != input.transactionId) {
      throw ArgumentError.value(
        input.transactionId,
        'transactionId',
        'must match original transaction id',
      );
    }
    if (original.type != TransactionType.expense) {
      throw ArgumentError.value(
        original.type,
        'original.type',
        'only expense transactions can be updated by this use case',
      );
    }

    final updated = original.copyWith(
      accountId: input.accountId,
      categoryId: input.categoryId,
      amount: input.amount,
      date: input.date,
      note: input.note,
      updatedAt: _now(),
    );
    await _repository.update(updated);
    return updated;
  }
}
