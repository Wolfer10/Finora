import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/transactions/domain/delete_transaction_use_case.dart';
import 'package:finora/features/transactions/domain/transaction.dart';
import 'package:finora/features/transactions/domain/transaction_repository.dart';

void main() {
  late _FakeTransactionRepository repository;

  setUp(() {
    repository = _FakeTransactionRepository();
  });

  test('rejects empty transaction id', () async {
    final useCase = DeleteTransactionUseCase(repository);

    await expectLater(
      () => useCase('   '),
      throwsA(isA<ArgumentError>()),
    );
    expect(repository.deletedIds, isEmpty);
  });

  test('soft deletes transaction by id', () async {
    final useCase = DeleteTransactionUseCase(repository);

    await useCase('tx-123');

    expect(repository.deletedIds, ['tx-123']);
  });
}

class _FakeTransactionRepository implements TransactionRepository {
  final List<String> deletedIds = [];

  @override
  Future<void> softDelete(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<void> create(Transaction transaction) async {
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
