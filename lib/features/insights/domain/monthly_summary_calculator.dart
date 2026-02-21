import 'package:finora/features/transactions/domain/transaction.dart';
import 'package:finora/features/transactions/domain/transaction_repository.dart';

class MonthlySummaryCalculator {
  const MonthlySummaryCalculator();

  MonthlyTotals calculate({
    required List<Transaction> transactions,
  }) {
    var income = 0.0;
    var expense = 0.0;

    for (final transaction in transactions) {
      if (transaction.isDeleted) {
        continue;
      }
      switch (transaction.type) {
        case TransactionType.income:
          income += transaction.amount;
          break;
        case TransactionType.expense:
          expense += transaction.amount;
          break;
        case TransactionType.transfer:
          break;
      }
    }

    return MonthlyTotals(incomeTotal: income, expenseTotal: expense);
  }
}
