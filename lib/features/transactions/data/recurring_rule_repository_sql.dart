import 'package:drift/drift.dart'
    show QueryRow, TableUpdate, TableUpdateQuery, Variable;

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/enum_codecs.dart';
import 'package:finora/core/errors/repository_error.dart';
import 'package:finora/features/transactions/domain/recurring_rule.dart';
import 'package:finora/features/transactions/domain/recurring_rule_repository.dart';

class RecurringRuleRepositorySql implements RecurringRuleRepository {
  RecurringRuleRepositorySql(this._db);

  final AppDatabase _db;

  @override
  Future<void> create(RecurringRule rule) async {
    await guardRepositoryCall('RecurringRuleRepository.create', () async {
      await _db.customStatement(
        '''
        INSERT INTO recurring_rules (
          id,
          type,
          account_id,
          category_id,
          to_account_id,
          amount,
          note,
          start_date,
          end_date,
          next_run_at,
          recurrence_unit,
          recurrence_interval,
          created_at,
          updated_at,
          is_deleted
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
        ''',
        <Object?>[
          rule.id,
          encodeTransactionType(rule.type),
          rule.accountId,
          rule.categoryId,
          rule.toAccountId,
          rule.amount,
          rule.note,
          rule.startDate.toIso8601String(),
          rule.endDate?.toIso8601String(),
          rule.nextRunAt.toIso8601String(),
          _encodeRecurrenceUnit(rule.recurrenceUnit),
          rule.recurrenceInterval,
          rule.createdAt.toIso8601String(),
          rule.updatedAt.toIso8601String(),
        ],
      );
      _db.notifyUpdates({const TableUpdate('recurring_rules')});
    });
  }

  @override
  Future<List<RecurringRule>> listDue(DateTime until) async {
    return guardRepositoryCall('RecurringRuleRepository.listDue', () async {
      final rows = await _db.customSelect(
        '''
        SELECT
          id, type, account_id, category_id, to_account_id,
          amount, note, start_date, end_date, next_run_at,
          recurrence_unit, recurrence_interval, created_at, updated_at, is_deleted
        FROM recurring_rules
        WHERE is_deleted = 0 AND next_run_at <= ?
        ORDER BY next_run_at ASC
        ''',
        variables: [Variable<String>(until.toIso8601String())],
      ).get();
      return rows
          .map<RecurringRule>((row) => _mapRow(row))
          .toList(growable: false);
    });
  }

  @override
  Future<void> softDelete(String id) async {
    await guardRepositoryCall('RecurringRuleRepository.softDelete', () async {
      await _db.customStatement(
        '''
        UPDATE recurring_rules
        SET is_deleted = 1, updated_at = ?
        WHERE id = ?
        ''',
        <Object?>[DateTime.now().toIso8601String(), id],
      );
      _db.notifyUpdates({const TableUpdate('recurring_rules')});
    });
  }

  @override
  Future<void> update(RecurringRule rule) async {
    await guardRepositoryCall('RecurringRuleRepository.update', () async {
      await _db.customStatement(
        '''
        UPDATE recurring_rules
        SET
          type = ?,
          account_id = ?,
          category_id = ?,
          to_account_id = ?,
          amount = ?,
          note = ?,
          start_date = ?,
          end_date = ?,
          next_run_at = ?,
          recurrence_unit = ?,
          recurrence_interval = ?,
          updated_at = ?,
          is_deleted = ?
        WHERE id = ?
        ''',
        <Object?>[
          encodeTransactionType(rule.type),
          rule.accountId,
          rule.categoryId,
          rule.toAccountId,
          rule.amount,
          rule.note,
          rule.startDate.toIso8601String(),
          rule.endDate?.toIso8601String(),
          rule.nextRunAt.toIso8601String(),
          _encodeRecurrenceUnit(rule.recurrenceUnit),
          rule.recurrenceInterval,
          rule.updatedAt.toIso8601String(),
          rule.isDeleted ? 1 : 0,
          rule.id,
        ],
      );
      _db.notifyUpdates({const TableUpdate('recurring_rules')});
    });
  }

  @override
  Stream<List<RecurringRule>> watchAllActive() {
    return guardRepositoryStream('RecurringRuleRepository.watchAllActive', () {
      return (() async* {
        yield await _listAllActive();
        await for (final _ in _db.tableUpdates(
          const TableUpdateQuery.onTableName('recurring_rules'),
        )) {
          yield await _listAllActive();
        }
      })();
    });
  }

  Future<List<RecurringRule>> _listAllActive() async {
    final rows = await _db.customSelect(
      '''
      SELECT
        id, type, account_id, category_id, to_account_id,
        amount, note, start_date, end_date, next_run_at,
        recurrence_unit, recurrence_interval, created_at, updated_at, is_deleted
      FROM recurring_rules
      WHERE is_deleted = 0
      ORDER BY next_run_at ASC, created_at ASC
      ''',
    ).get();
    return rows
        .map<RecurringRule>((row) => _mapRow(row))
        .toList(growable: false);
  }

  RecurringRule _mapRow(QueryRow row) {
    return RecurringRule(
      id: row.read<String>('id'),
      type: decodeTransactionType(row.read<String>('type')),
      accountId: row.read<String>('account_id'),
      categoryId: row.read<String?>('category_id'),
      toAccountId: row.read<String?>('to_account_id'),
      amount: row.read<double>('amount'),
      note: row.read<String?>('note'),
      startDate: DateTime.parse(row.read<String>('start_date')),
      endDate: row.read<String?>('end_date') == null
          ? null
          : DateTime.parse(row.read<String>('end_date')),
      nextRunAt: DateTime.parse(row.read<String>('next_run_at')),
      recurrenceUnit: _decodeRecurrenceUnit(row.read<String>('recurrence_unit')),
      recurrenceInterval: row.read<int>('recurrence_interval'),
      createdAt: DateTime.parse(row.read<String>('created_at')),
      updatedAt: DateTime.parse(row.read<String>('updated_at')),
      isDeleted: row.read<int>('is_deleted') == 1,
    );
  }

  String _encodeRecurrenceUnit(RecurrenceUnit unit) => unit.name;

  RecurrenceUnit _decodeRecurrenceUnit(String raw) {
    return RecurrenceUnit.values.firstWhere((value) => value.name == raw);
  }
}
