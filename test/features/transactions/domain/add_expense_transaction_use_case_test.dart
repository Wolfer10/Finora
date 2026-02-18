import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/transactions/domain/add_expense_transaction_use_case.dart';
import 'package:finora/features/transactions/domain/transaction.dart';
import 'package:finora/features/transactions/domain/transaction_repository.dart';

void main() {
  late _FakeTransactionRepository repository;
  late DateTime fixedNow;

  setUp(() {
    repository = _FakeTransactionRepository();
    fixedNow = DateTime(2026, 2, 16, 10, 30, 0);
  });

  test('rejects amount less than or equal to 0', () async {
    final useCase = AddExpenseTransactionUseCase(
      repository,
      now: () => fixedNow,
      idGenerator: () => 'tx-1',
    );

    final input = AddExpenseTransactionInput(
      accountId: 'acc-1',
      categoryId: 'cat-1',
      amount: 0,
      date: DateTime(2026, 2, 16),
    );

    await expectLater(
      () => useCase(input),
      throwsA(isA<ArgumentError>()),
    );
    expect(repository.createdTransactions, isEmpty);
  });

  test('creates expense transaction with id and timestamps and saves it', () async {
    final useCase = AddExpenseTransactionUseCase(
      repository,
      now: () => fixedNow,
      idGenerator: () => 'tx-expected',
    );

    final input = AddExpenseTransactionInput(
      accountId: 'acc-1',
      categoryId: 'cat-expense',
      amount: 1500.25,
      date: DateTime(2026, 2, 12),
      note: 'Groceries',
    );

    final created = await useCase(input);

    expect(created.id, 'tx-expected');
    expect(created.type, TransactionType.expense);
    expect(created.amount, 1500.25);
    expect(created.accountId, 'acc-1');
    expect(created.categoryId, 'cat-expense');
    expect(created.date, DateTime(2026, 2, 12));
    expect(created.note, 'Groceries');
    expect(created.transferGroupId, isNull);
    expect(created.recurringRuleId, isNull);
    expect(created.createdAt, fixedNow);
    expect(created.updatedAt, fixedNow);
    expect(created.isDeleted, isFalse);

    expect(repository.createdTransactions, hasLength(1));
    final persisted = repository.createdTransactions.single;
    expect(persisted.id, created.id);
    expect(persisted.type, TransactionType.expense);
    expect(persisted.amount, created.amount);
    expect(persisted.createdAt, fixedNow);
    expect(persisted.updatedAt, fixedNow);
  });
}

class _FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> createdTransactions = [];

  @override
  Future<void> create(Transaction transaction) async {
    createdTransactions.add(transaction);
  }

  @override
  Future<void> softDelete(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> softDeleteByTransferGroup(String transferGroupId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Transaction>> listByTransferGroup(String transferGroupId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> update(Transaction transaction) async {
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
