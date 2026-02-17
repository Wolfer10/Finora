import 'package:finora/features/transactions/domain/transaction.dart';
import 'package:finora/features/transactions/domain/transaction_repository.dart';

class AddExpenseTransactionInput {
  const AddExpenseTransactionInput({
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String accountId;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String? note;
}

class AddExpenseTransactionUseCase {
  AddExpenseTransactionUseCase(
    this._repository, {
    DateTime Function()? now,
    String Function()? idGenerator,
  })  : _now = now ?? DateTime.now,
        _idGenerator = idGenerator ?? _defaultIdGenerator;

  final TransactionRepository _repository;
  final DateTime Function() _now;
  final String Function() _idGenerator;

  Future<Transaction> call(AddExpenseTransactionInput input) async {
    if (input.amount <= 0) {
      throw ArgumentError.value(input.amount, 'amount', 'must be greater than 0');
    }

    final timestamp = _now();
    final transaction = Transaction(
      id: _idGenerator(),
      accountId: input.accountId,
      categoryId: input.categoryId,
      type: TransactionType.expense,
      amount: input.amount,
      date: input.date,
      note: input.note,
      transferGroupId: null,
      recurringRuleId: null,
      createdAt: timestamp,
      updatedAt: timestamp,
      isDeleted: false,
    );

    await _repository.create(transaction);
    return transaction;
  }

  static String _defaultIdGenerator() {
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    return 'tx-$microseconds';
  }
}
