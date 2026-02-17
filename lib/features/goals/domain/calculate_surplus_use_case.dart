import 'package:finora/features/transactions/domain/transaction_repository.dart';

class CalculateSurplusInput {
  const CalculateSurplusInput({
    required this.year,
    required this.month,
    this.accountId,
  });

  final int year;
  final int month;
  final String? accountId;
}

class CalculateSurplusUseCase {
  CalculateSurplusUseCase(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  Future<double> call(CalculateSurplusInput input) async {
    final totals = await _transactionRepository.monthlyTotals(
      input.year,
      input.month,
      accountId: input.accountId,
    );
    return totals.net;
  }
}
