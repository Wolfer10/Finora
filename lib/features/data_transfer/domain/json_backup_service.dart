import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:finora/core/database/app_database.dart';

class JsonBackupService {
  JsonBackupService(this._db);

  final AppDatabase _db;

  static const int schemaVersion = 1;

  Future<String> exportJson() async {
    final accounts = await _db.select(_db.accounts).get();
    final categories = await _db.select(_db.categories).get();
    final transactions = await _db.select(_db.transactions).get();
    final goals = await _db.select(_db.goals).get();
    final contributions = await _db.select(_db.goalContributions).get();
    final predictions = await _db.customSelect(
      '''
      SELECT id, year, month, category_id, predicted_amount, note, created_at, updated_at, is_deleted
      FROM monthly_predictions
      ''',
    ).get();
    final settingsRow = await _db.customSelect(
      '''
      SELECT currency_code, currency_symbol, updated_at
      FROM app_settings
      WHERE id = 1
      LIMIT 1
      ''',
    ).getSingleOrNull();

    final payload = <String, Object?>{
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': accounts
          .map(
            (row) => {
              'id': row.id,
              'name': row.name,
              'type': row.type,
              'initialBalance': row.initialBalance,
              'createdAt': row.createdAt.toIso8601String(),
              'updatedAt': row.updatedAt.toIso8601String(),
              'isDeleted': row.isDeleted,
            },
          )
          .toList(growable: false),
      'categories': categories
          .map(
            (row) => {
              'id': row.id,
              'name': row.name,
              'type': row.type,
              'icon': row.icon,
              'color': row.color,
              'isDefault': row.isDefault,
              'createdAt': row.createdAt.toIso8601String(),
              'updatedAt': row.updatedAt.toIso8601String(),
              'isDeleted': row.isDeleted,
            },
          )
          .toList(growable: false),
      'transactions': transactions
          .map(
            (row) => {
              'id': row.id,
              'accountId': row.accountId,
              'categoryId': row.categoryId,
              'type': row.type,
              'amount': row.amount,
              'date': row.date.toIso8601String(),
              'note': row.note,
              'transferGroupId': row.transferGroupId,
              'recurringRuleId': row.recurringRuleId,
              'createdAt': row.createdAt.toIso8601String(),
              'updatedAt': row.updatedAt.toIso8601String(),
              'isDeleted': row.isDeleted,
            },
          )
          .toList(growable: false),
      'goals': goals
          .map(
            (row) => {
              'id': row.id,
              'name': row.name,
              'targetAmount': row.targetAmount,
              'savedAmount': row.savedAmount,
              'priority': row.priority,
              'completed': row.completed,
              'completedAt': row.completedAt?.toIso8601String(),
              'createdAt': row.createdAt.toIso8601String(),
              'updatedAt': row.updatedAt.toIso8601String(),
              'isDeleted': row.isDeleted,
            },
          )
          .toList(growable: false),
      'goalContributions': contributions
          .map(
            (row) => {
              'id': row.id,
              'goalId': row.goalId,
              'amount': row.amount,
              'date': row.date.toIso8601String(),
              'note': row.note,
              'createdAt': row.createdAt.toIso8601String(),
              'updatedAt': row.updatedAt.toIso8601String(),
              'isDeleted': row.isDeleted,
            },
          )
          .toList(growable: false),
      'predictions': predictions
          .map(
            (row) => {
              'id': row.read<String>('id'),
              'year': row.read<int>('year'),
              'month': row.read<int>('month'),
              'categoryId': row.read<String>('category_id'),
              'predictedAmount': row.read<double>('predicted_amount'),
              'note': row.read<String?>('note'),
              'createdAt': row.read<String>('created_at'),
              'updatedAt': row.read<String>('updated_at'),
              'isDeleted': _toBool(row.data['is_deleted']),
            },
          )
          .toList(growable: false),
      'settings': {
        'currencyCode': settingsRow?.read<String>('currency_code') ?? 'HUF',
        'currencySymbol': settingsRow?.read<String>('currency_symbol') ?? 'Ft',
        'updatedAt':
            settingsRow?.read<String>('updated_at') ?? DateTime.now().toIso8601String(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> importJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Top-level JSON object is required.');
    }
    _validate(decoded);

    final accounts = (decoded['accounts'] as List<dynamic>).cast<Map<String, dynamic>>();
    final categories =
        (decoded['categories'] as List<dynamic>).cast<Map<String, dynamic>>();
    final transactions =
        (decoded['transactions'] as List<dynamic>).cast<Map<String, dynamic>>();
    final goals = (decoded['goals'] as List<dynamic>).cast<Map<String, dynamic>>();
    final contributions =
        (decoded['goalContributions'] as List<dynamic>).cast<Map<String, dynamic>>();
    final predictions =
        (decoded['predictions'] as List<dynamic>).cast<Map<String, dynamic>>();
    final settings = (decoded['settings'] as Map<String, dynamic>);

    await _db.transaction(() async {
      await _db.delete(_db.goalContributions).go();
      await _db.delete(_db.transactions).go();
      await _db.customStatement('DELETE FROM monthly_predictions');
      await _db.delete(_db.goals).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.accounts).go();
      await _db.customStatement('DELETE FROM app_settings');

      for (final row in accounts) {
        await _db.into(_db.accounts).insert(
              AccountsCompanion.insert(
                id: row['id'] as String,
                name: row['name'] as String,
                type: row['type'] as String,
                initialBalance: _toDouble(row['initialBalance']),
                createdAt: DateTime.parse(row['createdAt'] as String),
                updatedAt: DateTime.parse(row['updatedAt'] as String),
                isDeleted: Value(_toBool(row['isDeleted'])),
              ),
            );
      }

      for (final row in categories) {
        await _db.into(_db.categories).insert(
              CategoriesCompanion.insert(
                id: row['id'] as String,
                name: row['name'] as String,
                type: row['type'] as String,
                icon: row['icon'] as String,
                color: row['color'] as String,
                isDefault: Value(_toBool(row['isDefault'])),
                createdAt: DateTime.parse(row['createdAt'] as String),
                updatedAt: DateTime.parse(row['updatedAt'] as String),
                isDeleted: Value(_toBool(row['isDeleted'])),
              ),
            );
      }

      for (final row in goals) {
        await _db.into(_db.goals).insert(
              GoalsCompanion.insert(
                id: row['id'] as String,
                name: row['name'] as String,
                targetAmount: _toDouble(row['targetAmount']),
                savedAmount: Value(_toDouble(row['savedAmount'])),
                priority: row['priority'] as int,
                completed: Value(_toBool(row['completed'])),
                completedAt: Value(
                  row['completedAt'] == null
                      ? null
                      : DateTime.parse(row['completedAt'] as String),
                ),
                createdAt: DateTime.parse(row['createdAt'] as String),
                updatedAt: DateTime.parse(row['updatedAt'] as String),
                isDeleted: Value(_toBool(row['isDeleted'])),
              ),
            );
      }

      for (final row in contributions) {
        await _db.into(_db.goalContributions).insert(
              GoalContributionsCompanion.insert(
                id: row['id'] as String,
                goalId: row['goalId'] as String,
                amount: _toDouble(row['amount']),
                date: DateTime.parse(row['date'] as String),
                note: Value(row['note'] as String?),
                createdAt: DateTime.parse(row['createdAt'] as String),
                updatedAt: DateTime.parse(row['updatedAt'] as String),
                isDeleted: Value(_toBool(row['isDeleted'])),
              ),
            );
      }

      for (final row in transactions) {
        await _db.into(_db.transactions).insert(
              TransactionsCompanion.insert(
                id: row['id'] as String,
                accountId: row['accountId'] as String,
                categoryId: row['categoryId'] as String,
                type: row['type'] as String,
                amount: _toDouble(row['amount']),
                date: DateTime.parse(row['date'] as String),
                note: Value(row['note'] as String?),
                transferGroupId: Value(row['transferGroupId'] as String?),
                recurringRuleId: Value(row['recurringRuleId'] as String?),
                createdAt: DateTime.parse(row['createdAt'] as String),
                updatedAt: DateTime.parse(row['updatedAt'] as String),
                isDeleted: Value(_toBool(row['isDeleted'])),
              ),
            );
      }

      for (final row in predictions) {
        await _db.customStatement(
          '''
          INSERT INTO monthly_predictions (
            id, year, month, category_id, predicted_amount, note, created_at, updated_at, is_deleted
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            row['id'] as String,
            row['year'] as int,
            row['month'] as int,
            row['categoryId'] as String,
            _toDouble(row['predictedAmount']),
            row['note'] as String?,
            row['createdAt'] as String,
            row['updatedAt'] as String,
            _toBool(row['isDeleted']) ? 1 : 0,
          ],
        );
      }

      await _db.customStatement(
        '''
        INSERT INTO app_settings (id, currency_code, currency_symbol, updated_at)
        VALUES (1, ?, ?, ?)
        ''',
        [
          settings['currencyCode'] as String,
          settings['currencySymbol'] as String,
          settings['updatedAt'] as String,
        ],
      );
    });
  }

  void _validate(Map<String, dynamic> payload) {
    if ((payload['schemaVersion'] as int?) != schemaVersion) {
      throw FormatException(
        'Unsupported schemaVersion: ${payload['schemaVersion']}',
      );
    }
    if (payload['exportedAt'] is! String) {
      throw const FormatException('Missing or invalid exportedAt field.');
    }
    final requiredListKeys = const [
      'accounts',
      'categories',
      'transactions',
      'goals',
      'goalContributions',
      'predictions',
    ];
    for (final key in requiredListKeys) {
      if (payload[key] is! List) {
        throw FormatException('Missing or invalid list field: $key');
      }
    }
    if (payload['settings'] is! Map<String, dynamic>) {
      throw const FormatException('Missing or invalid settings object.');
    }
    final settings = payload['settings'] as Map<String, dynamic>;
    if (settings['currencyCode'] is! String ||
        settings['currencySymbol'] is! String ||
        settings['updatedAt'] is! String) {
      throw const FormatException('Settings fields are invalid.');
    }
  }

  static bool _toBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static double _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }
}
