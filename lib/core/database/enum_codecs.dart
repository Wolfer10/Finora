import 'package:finora/features/accounts/domain/account.dart';
import 'package:finora/features/categories/domain/category.dart';
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
