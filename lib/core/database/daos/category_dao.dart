import 'package:drift/drift.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/enum_codecs.dart';
import 'package:finora/core/database/tables/categories_table.dart';
import 'package:finora/features/categories/domain/category.dart' as domain;

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<void> upsert(CategoriesCompanion companion) async {
    await into(categories).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteById(String id, DateTime updatedAt) async {
    await (update(categories)..where((tbl) => tbl.id.equals(id))).write(
      CategoriesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Stream<List<Category>> watchAll({bool activeOnly = true}) {
    return (select(categories)
          ..where((tbl) {
            if (!activeOnly) {
              return const Constant(true);
            }
            return tbl.isDeleted.equals(false);
          })
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }

  Stream<List<Category>> watchAllActive() {
    return watchAll(activeOnly: true);
  }

  Future<void> seedDefaultsIfEmpty() async {
    final hasAny = await (select(categories)..limit(1)).getSingleOrNull();
    if (hasAny != null) {
      return;
    }

    final now = DateTime.now();
    final defaults = <CategoriesCompanion>[
      CategoriesCompanion.insert(
        id: 'cat-income-salary',
        name: 'Salary',
        type: encodeCategoryType(domain.CategoryType.income),
        icon: 'attach_money',
        color: '#2E7D32',
        isDefault: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'cat-expense-food',
        name: 'Food',
        type: encodeCategoryType(domain.CategoryType.expense),
        icon: 'restaurant',
        color: '#EF6C00',
        isDefault: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
      CategoriesCompanion.insert(
        id: 'cat-expense-transport',
        name: 'Transport',
        type: encodeCategoryType(domain.CategoryType.expense),
        icon: 'directions_car',
        color: '#1565C0',
        isDefault: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await batch((batch) {
      batch.insertAll(categories, defaults);
    });
  }
}
