import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/features/data_transfer/domain/json_backup_service.dart';
import 'package:finora/features/settings/data/settings_repository_sql.dart';

void main() {
  late AppDatabase db;
  late JsonBackupService service;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = JsonBackupService(db);

    final now = DateTime(2026, 2, 18, 12);
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: 'acc-main',
            name: 'Main Account',
            type: 'bank',
            initialBalance: 1000,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: 'cat-food',
            name: 'Food',
            type: 'expense',
            icon: 'restaurant',
            color: '#EF6C00',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            id: 'tx-1',
            accountId: 'acc-main',
            categoryId: 'cat-food',
            type: 'expense',
            amount: 200,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.customStatement(
      '''
      INSERT INTO monthly_predictions (
        id, year, month, category_id, predicted_amount, note, created_at, updated_at, is_deleted
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      ['pred-1', 2026, 2, 'cat-food', 300, null, now.toIso8601String(), now.toIso8601String(), 0],
    );
    await SettingsRepositorySql(db).ensureInitialized();
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  test('exports required schema fields', () async {
    final jsonText = await service.exportJson();
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;

    expect(decoded['schemaVersion'], JsonBackupService.schemaVersion);
    expect(decoded['exportedAt'], isNotNull);
    expect(decoded['accounts'], isA<List<dynamic>>());
    expect(decoded['categories'], isA<List<dynamic>>());
    expect(decoded['transactions'], isA<List<dynamic>>());
    expect(decoded['goals'], isA<List<dynamic>>());
    expect(decoded['goalContributions'], isA<List<dynamic>>());
    expect(decoded['predictions'], isA<List<dynamic>>());
    expect(decoded['settings'], isA<Map<String, dynamic>>());
  });

  test('imports and replaces database content', () async {
    final payload = {
      'schemaVersion': JsonBackupService.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': [
        {
          'id': 'acc-new',
          'name': 'Imported',
          'type': 'cash',
          'initialBalance': 50.0,
          'createdAt': DateTime(2026, 1, 1).toIso8601String(),
          'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
          'isDeleted': false,
        },
      ],
      'categories': [
        {
          'id': 'cat-new',
          'name': 'Imported Category',
          'type': 'expense',
          'icon': 'store',
          'color': '#000000',
          'isDefault': false,
          'createdAt': DateTime(2026, 1, 1).toIso8601String(),
          'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
          'isDeleted': false,
        },
      ],
      'transactions': [],
      'goals': [],
      'goalContributions': [],
      'predictions': [],
      'settings': {
        'currencyCode': 'USD',
        'currencySymbol': '\$',
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
      },
    };

    await service.importJson(jsonEncode(payload));

    final accounts = await db.select(db.accounts).get();
    expect(accounts, hasLength(1));
    expect(accounts.single.id, 'acc-new');

    final settings = await SettingsRepositorySql(db).get();
    expect(settings.currencyCode, 'USD');
    expect(settings.currencySymbol, '\$');
  });
}
