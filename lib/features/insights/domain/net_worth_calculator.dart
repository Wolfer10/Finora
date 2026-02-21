import 'package:finora/features/accounts/domain/account.dart';
import 'package:finora/features/transactions/domain/transaction.dart';

class AccountNetWorthItem {
  const AccountNetWorthItem({
    required this.accountId,
    required this.accountName,
    required this.balance,
  });

  final String accountId;
  final String accountName;
  final double balance;
}

class NetWorthResult {
  const NetWorthResult({
    required this.accounts,
    required this.assets,
    required this.liabilities,
  });

  final List<AccountNetWorthItem> accounts;
  final double assets;
  final double liabilities;

  double get netWorth => assets - liabilities;
}

class NetWorthCalculator {
  const NetWorthCalculator();

  NetWorthResult calculate({
    required List<Account> accounts,
    required List<Transaction> transactions,
  }) {
    final activeAccounts = <String, Account>{};
    final balances = <String, double>{};
    for (final account in accounts) {
      if (account.isDeleted) {
        continue;
      }
      activeAccounts[account.id] = account;
      balances[account.id] = account.initialBalance;
    }

    for (final transaction in transactions) {
      if (transaction.isDeleted) {
        continue;
      }
      if (!balances.containsKey(transaction.accountId)) {
        continue;
      }
      switch (transaction.type) {
        case TransactionType.income:
          balances[transaction.accountId] =
              (balances[transaction.accountId] ?? 0) + transaction.amount;
          break;
        case TransactionType.expense:
          balances[transaction.accountId] =
              (balances[transaction.accountId] ?? 0) - transaction.amount;
          break;
        case TransactionType.transfer:
          break;
      }
    }

    final accountResults = balances.entries
        .map(
          (entry) => AccountNetWorthItem(
            accountId: entry.key,
            accountName: activeAccounts[entry.key]?.name ?? entry.key,
            balance: entry.value,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.accountName.compareTo(b.accountName));

    var assets = 0.0;
    var liabilities = 0.0;
    for (final account in accountResults) {
      if (account.balance >= 0) {
        assets += account.balance;
      } else {
        liabilities += -account.balance;
      }
    }

    return NetWorthResult(
      accounts: accountResults,
      assets: assets,
      liabilities: liabilities,
    );
  }
}
