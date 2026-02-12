import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';

void main() {
  test('AppDatabase opens and runs a basic query', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    try {
      final result = await db.customSelect('SELECT 1 AS value').getSingle();
      expect(result.read<int>('value'), 1);
      expect(db.schemaVersion, 1);
    } finally {
      await db.close();
    }
  });
}
