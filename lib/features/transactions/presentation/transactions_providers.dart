import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/account_dao.dart';
import 'package:finora/core/database/daos/category_dao.dart';
import 'package:finora/core/database/daos/goal_dao.dart';
import 'package:finora/core/database/daos/transaction_dao.dart';
import 'package:finora/features/accounts/data/account_repository_drift.dart';
import 'package:finora/features/accounts/domain/account.dart' as account_domain;
import 'package:finora/features/accounts/domain/account_repository.dart';
import 'package:finora/features/categories/data/category_repository_drift.dart';
import 'package:finora/features/categories/domain/category.dart'
    as category_domain;
import 'package:finora/features/categories/domain/category_repository.dart';
import 'package:finora/features/data_transfer/domain/json_backup_service.dart';
import 'package:finora/features/goals/data/goal_repository_drift.dart';
import 'package:finora/features/goals/domain/add_goal_contribution_use_case.dart';
import 'package:finora/features/goals/domain/allocate_surplus_use_case.dart';
import 'package:finora/features/goals/domain/calculate_surplus_use_case.dart';
import 'package:finora/features/goals/domain/goal.dart' as goal_domain;
import 'package:finora/features/goals/domain/goal_completion_service.dart';
import 'package:finora/features/goals/domain/goal_contribution.dart'
    as contribution_domain;
import 'package:finora/features/goals/domain/goal_repository.dart';
import 'package:finora/features/predictions/data/prediction_repository_sql.dart';
import 'package:finora/features/predictions/domain/budget_variance_calculator.dart';
import 'package:finora/features/predictions/domain/monthly_prediction.dart'
    as prediction_domain;
import 'package:finora/features/predictions/domain/prediction_repository.dart';
import 'package:finora/features/settings/data/settings_repository_sql.dart';
import 'package:finora/features/settings/domain/app_settings.dart'
    as settings_domain;
import 'package:finora/features/settings/domain/settings_repository.dart';
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

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return GoalRepositoryDrift(GoalDao(db));
});

final goalCompletionServiceProvider = Provider<GoalCompletionService>((ref) {
  return GoalCompletionService();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepositorySql(db);
});

final jsonBackupServiceProvider = Provider<JsonBackupService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return JsonBackupService(db);
});

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PredictionRepositorySql(db);
});

final budgetVarianceCalculatorProvider = Provider<BudgetVarianceCalculator>((ref) {
  return const BudgetVarianceCalculator();
});

final appSettingsProvider = StreamProvider<settings_domain.AppSettings>((ref) {
  ref.watch(dataRefreshTickProvider);
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watch();
});

final calculateSurplusUseCaseProvider = Provider<CalculateSurplusUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return CalculateSurplusUseCase(repository);
});

final allocateSurplusUseCaseProvider = Provider<AllocateSurplusUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  final completionService = ref.watch(goalCompletionServiceProvider);
  return AllocateSurplusUseCase(repository, completionService);
});

final addGoalContributionUseCaseProvider = Provider<AddGoalContributionUseCase>((
  ref,
) {
  final repository = ref.watch(goalRepositoryProvider);
  final completionService = ref.watch(goalCompletionServiceProvider);
  return AddGoalContributionUseCase(repository, completionService);
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

final dataRefreshTickProvider = StateProvider<int>((ref) => 0);

final transactionNotifierProvider =
    NotifierProvider<TransactionNotifier, AsyncValue<void>>(
  TransactionNotifier.new,
);

final accountNotifierProvider = NotifierProvider<AccountNotifier, AsyncValue<void>>(
  AccountNotifier.new,
);

final goalNotifierProvider = NotifierProvider<GoalNotifier, AsyncValue<void>>(
  GoalNotifier.new,
);

final settingsNotifierProvider = NotifierProvider<SettingsNotifier, AsyncValue<void>>(
  SettingsNotifier.new,
);

final dataTransferNotifierProvider =
    NotifierProvider<DataTransferNotifier, AsyncValue<void>>(
  DataTransferNotifier.new,
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

  Future<AllocateSurplusResult> closeMonth(DateTime month) async {
    state = const AsyncLoading();
    try {
      final calculateSurplus = ref.read(calculateSurplusUseCaseProvider);
      final allocateSurplus = ref.read(allocateSurplusUseCaseProvider);
      final surplus = await calculateSurplus(
        CalculateSurplusInput(
          year: month.year,
          month: month.month,
        ),
      );
      final result = await allocateSurplus(
        AllocateSurplusInput(
          surplusAmount: surplus,
          date: DateTime(month.year, month.month, 1),
          note: 'Close month allocation',
        ),
      );
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

class GoalNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createGoal({
    required String name,
    required double targetAmount,
    required goal_domain.GoalPriority priority,
  }) async {
    if (targetAmount <= 0) {
      throw ArgumentError.value(
        targetAmount,
        'targetAmount',
        'must be greater than 0',
      );
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      final normalizedName = name.trim();
      final goal = goal_domain.Goal(
        id: _generateId('goal'),
        name: normalizedName,
        targetAmount: targetAmount,
        savedAmount: 0,
        priority: priority,
        completed: false,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );
      await ref.read(goalRepositoryProvider).createGoal(goal);
    });
  }

  Future<void> updateGoal({
    required goal_domain.Goal goal,
    required String name,
    required double targetAmount,
    required goal_domain.GoalPriority priority,
  }) async {
    if (targetAmount <= 0) {
      throw ArgumentError.value(
        targetAmount,
        'targetAmount',
        'must be greater than 0',
      );
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      final updatedGoal = goal.copyWith(
        name: name.trim(),
        targetAmount: targetAmount,
        priority: priority,
        completed: goal.savedAmount >= targetAmount,
        completedAt: goal.savedAmount >= targetAmount ? now : null,
        updatedAt: now,
      );
      await ref.read(goalRepositoryProvider).updateGoal(updatedGoal);
    });
  }

  Future<void> deleteGoal(String goalId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(goalRepositoryProvider).softDeleteGoal(goalId);
    });
  }

  Future<void> addContribution({
    required String goalId,
    required double amount,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final input = AddGoalContributionInput(
        goalId: goalId,
        amount: amount,
        date: DateTime.now(),
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      );
      await ref.read(addGoalContributionUseCaseProvider)(input);
    });
  }

  static String _generateId(String prefix) {
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$microseconds';
  }
}

class AccountNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createAccount({
    required String name,
    required account_domain.AccountType type,
    required double initialBalance,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      await ref.read(accountRepositoryProvider).create(
            account_domain.Account(
              id: _generateId('acc'),
              name: name.trim(),
              type: type,
              initialBalance: initialBalance,
              createdAt: now,
              updatedAt: now,
              isDeleted: false,
            ),
          );
    });
  }

  Future<void> updateAccount({
    required account_domain.Account account,
    required String name,
    required account_domain.AccountType type,
    required double initialBalance,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).update(
            account.copyWith(
              name: name.trim(),
              type: type,
              initialBalance: initialBalance,
              updatedAt: DateTime.now(),
            ),
          );
    });
  }

  Future<void> deleteAccount(String accountId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).softDelete(accountId);
    });
  }

  static String _generateId(String prefix) {
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$microseconds';
  }
}

class SettingsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> updateCurrency({
    required String currencyCode,
    required String currencySymbol,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(settingsRepositoryProvider);
      final existing = await repository.get();
      await repository.update(
        existing.copyWith(
          currencyCode: currencyCode.trim().toUpperCase(),
          currencySymbol: currencySymbol.trim(),
          updatedAt: DateTime.now(),
        ),
      );
      ref.read(dataRefreshTickProvider.notifier).state++;
    });
  }
}

class DataTransferNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String> exportJson() async {
    state = const AsyncLoading();
    try {
      final service = ref.read(jsonBackupServiceProvider);
      final json = await service.exportJson();
      state = const AsyncData(null);
      return json;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> importJson(String rawJson) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(jsonBackupServiceProvider);
      await service.importJson(rawJson);
      ref.read(dataRefreshTickProvider.notifier).state++;
    });
  }
}

final transactionsByMonthProvider =
    StreamProvider<List<tx_domain.Transaction>>((ref) {
  ref.watch(dataRefreshTickProvider);
  final month = ref.watch(selectedMonthProvider);
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchByMonth(month.year, month.month);
});

final recentTransactionsProvider =
    StreamProvider<List<tx_domain.Transaction>>((ref) {
  ref.watch(dataRefreshTickProvider);
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchRecent(6);
});

final monthlyTotalsProvider = StreamProvider<MonthlyTotals>((ref) {
  ref.watch(dataRefreshTickProvider);
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

final goalsProvider = StreamProvider<List<goal_domain.Goal>>((ref) {
  ref.watch(dataRefreshTickProvider);
  final repository = ref.watch(goalRepositoryProvider);
  return repository.watchGoalsActive();
});

final monthlyPredictionsProvider =
    StreamProvider<List<prediction_domain.MonthlyPrediction>>((ref) {
  ref.watch(dataRefreshTickProvider);
  final month = ref.watch(selectedMonthProvider);
  final repository = ref.watch(predictionRepositoryProvider);
  return repository.watchByMonth(month.year, month.month);
});

final categoryExpenseTotalsProvider =
    Provider<AsyncValue<Map<String, double>>>((ref) {
  final categoriesAsync = ref.watch(expenseCategoriesProvider);
  final transactionsAsync = ref.watch(transactionsByMonthProvider);

  if (categoriesAsync.isLoading || transactionsAsync.isLoading) {
    return const AsyncLoading();
  }
  if (categoriesAsync.hasError) {
    return AsyncError(
      categoriesAsync.error!,
      categoriesAsync.stackTrace ?? StackTrace.current,
    );
  }
  if (transactionsAsync.hasError) {
    return AsyncError(
      transactionsAsync.error!,
      transactionsAsync.stackTrace ?? StackTrace.current,
    );
  }

  final categoryIds = categoriesAsync.value!
      .where((item) => item.type == category_domain.CategoryType.expense)
      .map((item) => item.id)
      .toSet();
  final totals = <String, double>{};
  for (final tx in transactionsAsync.value!) {
    if (tx.type != tx_domain.TransactionType.expense || tx.isDeleted) {
      continue;
    }
    if (!categoryIds.contains(tx.categoryId)) {
      continue;
    }
    totals[tx.categoryId] = (totals[tx.categoryId] ?? 0) + tx.amount;
  }
  return AsyncData(totals);
});

final budgetVarianceProvider = Provider<AsyncValue<BudgetVarianceResult>>((ref) {
  final categoriesAsync = ref.watch(expenseCategoriesProvider);
  final predictionsAsync = ref.watch(monthlyPredictionsProvider);
  final transactionsAsync = ref.watch(transactionsByMonthProvider);

  if (categoriesAsync.isLoading ||
      predictionsAsync.isLoading ||
      transactionsAsync.isLoading) {
    return const AsyncLoading();
  }
  if (categoriesAsync.hasError) {
    return AsyncError(
      categoriesAsync.error!,
      categoriesAsync.stackTrace ?? StackTrace.current,
    );
  }
  if (predictionsAsync.hasError) {
    return AsyncError(
      predictionsAsync.error!,
      predictionsAsync.stackTrace ?? StackTrace.current,
    );
  }
  if (transactionsAsync.hasError) {
    return AsyncError(
      transactionsAsync.error!,
      transactionsAsync.stackTrace ?? StackTrace.current,
    );
  }

  final calculator = ref.watch(budgetVarianceCalculatorProvider);
  final result = calculator.calculate(
    categories: categoriesAsync.value!,
    predictions: predictionsAsync.value!,
    transactions: transactionsAsync.value!,
  );
  return AsyncData(result);
});

final goalContributionsProvider =
    StreamProvider.family<List<contribution_domain.GoalContribution>, String>(
  (ref, goalId) {
    ref.watch(dataRefreshTickProvider);
    final repository = ref.watch(goalRepositoryProvider);
    return repository.watchContributionsByGoal(goalId);
  },
);

final activeAccountsProvider =
    StreamProvider<List<account_domain.Account>>((ref) {
  ref.watch(dataRefreshTickProvider);
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAllActive();
});

final expenseCategoriesProvider =
    StreamProvider<List<category_domain.Category>>((ref) {
  ref.watch(dataRefreshTickProvider);
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
  final settingsRepository = ref.read(settingsRepositoryProvider);

  await categoryRepository.seedDefaultsIfEmpty();
  await settingsRepository.ensureInitialized();

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
