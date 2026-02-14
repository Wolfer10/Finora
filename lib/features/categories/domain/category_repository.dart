import 'package:finora/features/categories/domain/category.dart';

abstract class CategoryRepository {
  Future<void> create(Category category);
  Future<void> update(Category category);
  Future<void> softDelete(String id);
  Future<void> seedDefaultsIfEmpty();
  Stream<List<Category>> watchAll({bool activeOnly = true});
  Stream<List<Category>> watchAllActive();
}
