import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/transactions/domain/transaction.dart';
import 'package:finora/features/transactions/domain/transaction_repository.dart';
import 'package:finora/features/transactions/domain/update_expense_transaction_use_case.dart';

void main() {
  late _FakeTransactionRepository repository;
  late DateTime fixedNow;

  setUp(() {
    repository = _FakeTransactionRepository();
    fixedNow = DateTime(2026, 2, 17, 11, 0, 0);
  });

  test('rejects amount less than or equal to 0', () async {
    final useCase = UpdateExpenseTransactionUseCase(
      repository,
      now: () => fixedNow,
    );
    final original = _expenseTransaction();
    final input = UpdateExpenseTransactionInput(
      transactionId: original.id,
      accountId: original.accountId,
      categoryId: original.categoryId,
      amount: 0,
      date: original.date,
    );

    await expectLater(
      () => useCase(original, input),
      throwsA(isA<ArgumentError>()),
    );
    expect(repository.updatedTransactions, isEmpty);
  });

  test('rejects id mismatch between original and input', () async {
    final useCase = UpdateExpenseTransactionUseCase(
      repository,
      now: () => fixedNow,
    );
    final original = _expenseTransaction();
    final input = UpdateExpenseTransactionInput(
      transactionId: 'another-id',
      accountId: original.accountId,
      categoryId: original.categoryId,
      amount: 10,
      date: original.date,
    );

    await expectLater(
      () => useCase(original, input),
      throwsA(isA<ArgumentError>()),
    );
    expect(repository.updatedTransactions, isEmpty);
  });

  test('updates expense transaction and persists it', () async {
    final useCase = UpdateExpenseTransactionUseCase(
      repository,
      now: () => fixedNow,
    );
    final original = _expenseTransaction();
    final input = UpdateExpenseTransactionInput(
      transactionId: original.id,
      accountId: 'acc-2',
      categoryId: 'cat-2',
      amount: 321.5,
      date: DateTime(2026, 2, 15),
      note: 'Updated note',
    );

    final updated = await useCase(original, input);

    expect(updated.id, original.id);
    expect(updated.type, TransactionType.expense);
    expect(updated.accountId, 'acc-2');
    expect(updated.categoryId, 'cat-2');
    expect(updated.amount, 321.5);
    expect(updated.date, DateTime(2026, 2, 15));
    expect(updated.note, 'Updated note');
    expect(updated.createdAt, original.createdAt);
    expect(updated.updatedAt, fixedNow);
    expect(updated.isDeleted, isFalse);

    expect(repository.updatedTransactions, hasLength(1));
    expect(repository.updatedTransactions.single.id, original.id);
    expect(repository.updatedTransactions.single.updatedAt, fixedNow);
  });
}

Transaction _expenseTransaction() {
  final createdAt = DateTime(2026, 2, 10, 8, 30, 0);
  return Transaction(
    id: 'tx-1',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    type: TransactionType.expense,
    amount: 123,
    date: DateTime(2026, 2, 12),
    note: 'Original note',
    createdAt: createdAt,
    updatedAt: createdAt,
    isDeleted: false,
  );
}

class _FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> updatedTransactions = [];

  @override
  Future<void> update(Transaction transaction) async {
    updatedTransactions.add(transaction);
  }

  @override
  Future<void> create(Transaction transaction) async {
    throw UnimplementedError();
  }

  @override
  Future<void> softDelete(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<double> monthlyExpenseTotal(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<double> monthlyIncomeTotal(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<MonthlyTotals> monthlyTotals(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  }) async {
    throw UnimplementedError();
  }

  @override
  Stream<List<Transaction>> watchByMonth(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Transaction>> watchRecent(int limit, {String? accountId}) {
    throw UnimplementedError();
  }
}
