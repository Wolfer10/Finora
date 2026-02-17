import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/account_dao.dart';
import 'package:finora/core/database/daos/category_dao.dart';
import 'package:finora/core/database/daos/transaction_dao.dart';
import 'package:finora/features/accounts/data/account_repository_drift.dart';
import 'package:finora/features/accounts/domain/account.dart' as account_domain;
import 'package:finora/features/accounts/domain/account_repository.dart';
import 'package:finora/features/categories/data/category_repository_drift.dart';
import 'package:finora/features/categories/domain/category.dart'
    as category_domain;
import 'package:finora/features/categories/domain/category_repository.dart';
import 'package:finora/features/transactions/data/transaction_repository_drift.dart';
import 'package:finora/features/transactions/domain/add_expense_transaction_use_case.dart';
import 'package:finora/features/transactions/domain/delete_transaction_use_case.dart';
import 'package:finora/features/transactions/domain/transaction.dart' as tx_domain;
import 'package:finora/features/transactions/domain/transaction_repository.dart';
import 'package:finora/features/transactions/domain/update_expense_transaction_use_case.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccountRepositoryDrift(AccountDao(db));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoryRepositoryDrift(CategoryDao(db));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionRepositoryDrift(TransactionDao(db));
});

final addExpenseTransactionUseCaseProvider =
    Provider<AddExpenseTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return AddExpenseTransactionUseCase(repository);
});

final updateExpenseTransactionUseCaseProvider =
    Provider<UpdateExpenseTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return UpdateExpenseTransactionUseCase(repository);
});

final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return DeleteTransactionUseCase(repository);
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final transactionNotifierProvider =
    NotifierProvider<TransactionNotifier, AsyncValue<void>>(
  TransactionNotifier.new,
);

class TransactionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> addExpense(AddExpenseTransactionInput input) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(addExpenseTransactionUseCaseProvider)(input);
    });
  }

  Future<void> updateExpense(
    tx_domain.Transaction original,
    UpdateExpenseTransactionInput input,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(updateExpenseTransactionUseCaseProvider)(original, input);
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deleteTransactionUseCaseProvider)(transactionId);
    });
  }
}

final transactionsByMonthProvider =
    StreamProvider<List<tx_domain.Transaction>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchByMonth(month.year, month.month);
});

final recentTransactionsProvider =
    StreamProvider<List<tx_domain.Transaction>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchRecent(6);
});

final monthlyTotalsProvider = StreamProvider<MonthlyTotals>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchByMonth(month.year, month.month).map((transactions) {
    var income = 0.0;
    var expense = 0.0;
    for (final transaction in transactions) {
      switch (transaction.type) {
        case tx_domain.TransactionType.income:
          income += transaction.amount;
          break;
        case tx_domain.TransactionType.expense:
          expense += transaction.amount;
          break;
        case tx_domain.TransactionType.transfer:
          break;
      }
    }
    return MonthlyTotals(incomeTotal: income, expenseTotal: expense);
  });
});

final activeAccountsProvider =
    StreamProvider<List<account_domain.Account>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAllActive();
});

final expenseCategoriesProvider =
    StreamProvider<List<category_domain.Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchAllActive().map(
        (categories) => categories
            .where(
              (category) =>
                  category.type == category_domain.CategoryType.expense,
            )
            .toList(growable: false),
      );
});

final transactionBootstrapProvider = FutureProvider<void>((ref) async {
  final accountRepository = ref.read(accountRepositoryProvider);
  final categoryRepository = ref.read(categoryRepositoryProvider);

  await categoryRepository.seedDefaultsIfEmpty();

  final accounts = await accountRepository.watchAllActive().first;
  if (accounts.isNotEmpty) {
    return;
  }

  final now = DateTime.now();
  await accountRepository.create(
    account_domain.Account(
      id: 'acc-main',
      name: 'Main Account',
      type: account_domain.AccountType.bank,
      initialBalance: 0,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    ),
  );
});
