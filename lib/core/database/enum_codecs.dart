import 'package:finora/features/accounts/domain/account.dart';
import 'package:finora/features/categories/domain/category.dart';
import 'package:finora/features/goals/domain/goal.dart';
import 'package:finora/features/transactions/domain/transaction.dart';

String encodeAccountType(AccountType value) => value.name;

AccountType decodeAccountType(String raw) {
  return AccountType.values.firstWhere((value) => value.name == raw);
}

String encodeCategoryType(CategoryType value) => value.name;

CategoryType decodeCategoryType(String raw) {
  return CategoryType.values.firstWhere((value) => value.name == raw);
}

String encodeTransactionType(TransactionType value) => value.name;

TransactionType decodeTransactionType(String raw) {
  return TransactionType.values.firstWhere((value) => value.name == raw);
}

int encodeGoalPriority(GoalPriority value) {
  switch (value) {
    case GoalPriority.high:
      return 0;
    case GoalPriority.medium:
      return 1;
    case GoalPriority.low:
      return 2;
  }
}

GoalPriority decodeGoalPriority(int raw) {
  switch (raw) {
    case 0:
      return GoalPriority.high;
    case 1:
      return GoalPriority.medium;
    case 2:
      return GoalPriority.low;
    default:
      throw ArgumentError.value(raw, 'raw', 'Unknown goal priority code');
  }
}
