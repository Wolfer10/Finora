import 'package:drift/drift.dart';

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/database/daos/category_dao.dart';
import 'package:finora/core/database/enum_codecs.dart';
import 'package:finora/features/categories/domain/category.dart' as domain;
import 'package:finora/features/categories/domain/category_repository.dart';

class CategoryRepositoryDrift implements CategoryRepository {
  CategoryRepositoryDrift(this._dao);

  final CategoryDao _dao;

  @override
  Future<void> create(domain.Category category) async {
    await _dao.upsert(_toCompanion(category));
  }

  @override
  Future<void> update(domain.Category category) async {
    await _dao.upsert(_toCompanion(category));
  }

  @override
  Future<void> softDelete(String id) async {
    await _dao.softDeleteById(id, DateTime.now());
  }

  @override
  Future<void> seedDefaultsIfEmpty() async {
    await _dao.seedDefaultsIfEmpty();
  }

  @override
  Stream<List<domain.Category>> watchAll({bool activeOnly = true}) {
    return _dao.watchAll(activeOnly: activeOnly).map(
          (rows) => rows.map(_toDomain).toList(growable: false),
        );
  }

  @override
  Stream<List<domain.Category>> watchAllActive() {
    return watchAll(activeOnly: true);
  }

  CategoriesCompanion _toCompanion(domain.Category category) {
    return CategoriesCompanion.insert(
      id: category.id,
      name: category.name,
      type: encodeCategoryType(category.type),
      icon: category.icon,
      color: category.color,
      isDefault: Value(category.isDefault),
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
      isDeleted: Value(category.isDeleted),
    );
  }

  domain.Category _toDomain(Category row) {
    return domain.Category(
      id: row.id,
      name: row.name,
      type: decodeCategoryType(row.type),
      icon: row.icon,
      color: row.color,
      isDefault: row.isDefault,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
    );
  }
}
