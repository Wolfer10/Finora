import 'package:finora/features/transactions/domain/recurring_rule.dart';

abstract class RecurringRuleRepository {
  Future<void> create(RecurringRule rule);
  Future<void> update(RecurringRule rule);
  Future<void> softDelete(String id);
  Stream<List<RecurringRule>> watchAllActive();
  Future<List<RecurringRule>> listDue(DateTime until);
}
