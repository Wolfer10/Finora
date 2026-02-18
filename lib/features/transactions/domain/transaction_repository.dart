import 'package:finora/features/transactions/domain/transaction.dart';

class MonthlyTotals {
  const MonthlyTotals({
    required this.incomeTotal,
    required this.expenseTotal,
  });

  final double incomeTotal;
  final double expenseTotal;

  double get net => incomeTotal - expenseTotal;
}

abstract class TransactionRepository {
  Future<void> create(Transaction transaction);
  Future<void> update(Transaction transaction);
  Future<void> softDelete(String id);
  Future<void> softDeleteByTransferGroup(String transferGroupId);
  Future<List<Transaction>> listByTransferGroup(String transferGroupId);
  Stream<List<Transaction>> watchRecent(int limit, {String? accountId});
  Stream<List<Transaction>> watchByMonth(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  });
  Future<double> monthlyIncomeTotal(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  });
  Future<double> monthlyExpenseTotal(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  });
  Future<MonthlyTotals> monthlyTotals(
    int year,
    int month, {
    String? accountId,
    String? categoryId,
    TransactionType? type,
  });
}
