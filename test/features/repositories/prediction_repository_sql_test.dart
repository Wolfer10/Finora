import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/features/predictions/data/prediction_repository_sql.dart';
import 'package:finora/features/predictions/domain/monthly_prediction.dart';

void main() {
  late AppDatabase db;
  late PredictionRepositorySql repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PredictionRepositorySql(db);
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  test('upsert respects unique (year,month,category) and updates amount', () async {
    final now = DateTime(2026, 2, 18, 10, 0);

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

    await repository.upsert(
      MonthlyPrediction(
        id: 'pred-1',
        year: 2026,
        month: 2,
        categoryId: 'cat-food',
        predictedAmount: 300,
        note: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.upsert(
      MonthlyPrediction(
        id: 'pred-2',
        year: 2026,
        month: 2,
        categoryId: 'cat-food',
        predictedAmount: 420,
        note: 'updated',
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );

    final items = await repository.watchByMonth(2026, 2).first;
    expect(items, hasLength(1));
    expect(items.single.predictedAmount, 420);
    expect(items.single.note, 'updated');
  });
}
