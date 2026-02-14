import 'package:finora/features/accounts/domain/account.dart';

abstract class AccountRepository {
  Future<void> create(Account account);
  Future<void> update(Account account);
  Future<void> softDelete(String id);
  Stream<List<Account>> watchAll({bool activeOnly = true});
  Stream<List<Account>> watchAllActive();
}
