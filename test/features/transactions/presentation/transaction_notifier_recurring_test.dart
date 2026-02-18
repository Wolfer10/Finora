import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/features/categories/domain/category.dart' as category_domain;
import 'package:finora/features/categories/domain/category_repository.dart';
import 'package:finora/features/transactions/domain/recurring_rule.dart';
import 'package:finora/features/transactions/domain/recurring_rule_repository.dart';
import 'package:finora/features/transactions/domain/transaction.dart' as tx_domain;
import 'package:finora/features/transactions/domain/transaction_repository.dart';
import 'package:finora/features/transactions/presentation/transactions_providers.dart';

void main() {
  test('runRecurringGeneration creates due expense transaction and advances next run', () async {
    final transactionRepository = _FakeTransactionRepository();
    final recurringRepository = _FakeRecurringRuleRepository(
      dueRules: [
        RecurringRule(
          id: 'rule-1',
          type: tx_domain.TransactionType.expense,
          accountId: 'acc-1',
          categoryId: 'cat-expense-1',
          toAccountId: null,
          amount: 85,
          note: 'Subscription',
          startDate: DateTime(2026, 2, 1),
          endDate: null,
          nextRunAt: DateTime(2026, 2, 1),
          recurrenceUnit: RecurrenceUnit.monthly,
          recurrenceInterval: 1,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          isDeleted: false,
        ),
      ],
    );
    final categoryRepository = _FakeCategoryRepository();

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
        recurringRuleRepositoryProvider.overrideWithValue(recurringRepository),
        categoryRepositoryProvider.overrideWithValue(categoryRepository),
      ],
    );
    addTearDown(container.dispose);

    final created = await container
        .read(transactionNotifierProvider.notifier)
        .runRecurringGeneration(until: DateTime(2026, 2, 20));

    expect(created, 1);
    expect(transactionRepository.created, hasLength(1));
    expect(transactionRepository.created.single.recurringRuleId, 'rule-1');
    expect(recurringRepository.updated, hasLength(1));
    expect(recurringRepository.updated.single.nextRunAt, DateTime(2026, 3, 1));
  });
}

class _FakeRecurringRuleRepository implements RecurringRuleRepository {
  _FakeRecurringRuleRepository({
    required List<RecurringRule> dueRules,
  }) : _dueRules = dueRules;

  final List<RecurringRule> _dueRules;
  final List<RecurringRule> updated = [];

  @override
  Future<void> create(RecurringRule rule) async {}

  @override
  Future<List<RecurringRule>> listDue(DateTime until) async {
    return _dueRules.where((rule) => !rule.nextRunAt.isAfter(until)).toList();
  }

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> update(RecurringRule rule) async {
    updated.add(rule);
  }

  @override
  Stream<List<RecurringRule>> watchAllActive() {
    return Stream.value(_dueRules);
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  final List<tx_domain.Transaction> created = [];

  @override
  Future<void> create(tx_domain.Transaction transaction) async {
    created.add(transaction);
  }

  @override
  Future<List<tx_domain.Transaction>> listByTransferGroup(String transferGroupId) async {
    return const [];
  }

  @override
  Future<double> monthlyExpenseTotal(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    tx_domain.TransactionType? type,
  }) async {
    return 0;
  }

  @override
  Future<double> monthlyIncomeTotal(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    tx_domain.TransactionType? type,
  }) async {
    return 0;
  }

  @override
  Future<MonthlyTotals> monthlyTotals(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    tx_domain.TransactionType? type,
  }) async {
    return const MonthlyTotals(incomeTotal: 0, expenseTotal: 0);
  }

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> softDeleteByTransferGroup(String transferGroupId) async {}

  @override
  Future<void> update(tx_domain.Transaction transaction) async {}

  @override
  Stream<List<tx_domain.Transaction>> watchByMonth(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    tx_domain.TransactionType? type,
  }) {
    return const Stream<List<tx_domain.Transaction>>.empty();
  }

  @override
  Stream<List<tx_domain.Transaction>> watchRecent(int limit, {String? accountId}) {
    return const Stream<List<tx_domain.Transaction>>.empty();
  }
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<void> create(category_domain.Category category) async {}

  @override
  Future<void> seedDefaultsIfEmpty() async {}

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> update(category_domain.Category category) async {}

  @override
  Stream<List<category_domain.Category>> watchAll({bool activeOnly = true}) {
    return const Stream<List<category_domain.Category>>.empty();
  }

  @override
  Stream<List<category_domain.Category>> watchAllActive() {
    return const Stream<List<category_domain.Category>>.empty();
  }
}
