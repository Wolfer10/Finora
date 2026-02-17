import 'package:finora/features/transactions/domain/transaction_repository.dart';

class DeleteTransactionUseCase {
  DeleteTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<void> call(String transactionId) async {
    if (transactionId.trim().isEmpty) {
      throw ArgumentError.value(transactionId, 'transactionId', 'must not be empty');
    }
    await _repository.softDelete(transactionId);
  }
}
