import 'package:drift/drift.dart' show Variable;

import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/errors/repository_error.dart';
import 'package:finora/features/predictions/domain/monthly_prediction.dart';
import 'package:finora/features/predictions/domain/prediction_repository.dart';

class PredictionRepositorySql implements PredictionRepository {
  PredictionRepositorySql(this._db);

  final AppDatabase _db;

  @override
  Future<void> upsert(MonthlyPrediction prediction) async {
    await guardRepositoryCall('PredictionRepository.upsert', () async {
      await _db.customStatement(
        '''
        INSERT INTO monthly_predictions (
          id, year, month, category_id, predicted_amount, note, created_at, updated_at, is_deleted
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)
        ON CONFLICT(year, month, category_id)
        DO UPDATE SET
          predicted_amount = excluded.predicted_amount,
          note = excluded.note,
          updated_at = excluded.updated_at,
          is_deleted = 0
        ''',
        <Object?>[
          prediction.id,
          prediction.year,
          prediction.month,
          prediction.categoryId,
          prediction.predictedAmount,
          prediction.note,
          prediction.createdAt.toIso8601String(),
          prediction.updatedAt.toIso8601String(),
        ],
      );
    });
  }

  @override
  Future<void> softDelete(String id) async {
    await guardRepositoryCall('PredictionRepository.softDelete', () async {
      await _db.customStatement(
        '''
        UPDATE monthly_predictions
        SET is_deleted = 1, updated_at = ?
        WHERE id = ?
        ''',
        <Object?>[
          DateTime.now().toIso8601String(),
          id,
        ],
      );
    });
  }

  @override
  Stream<List<MonthlyPrediction>> watchByMonth(int year, int month) {
    return guardRepositoryStream('PredictionRepository.watchByMonth', () {
      return _db
          .customSelect(
            '''
            SELECT id, year, month, category_id, predicted_amount, note, created_at, updated_at
            FROM monthly_predictions
            WHERE year = ? AND month = ? AND is_deleted = 0
            ORDER BY category_id ASC
            ''',
            variables: [
              Variable<int>(year),
              Variable<int>(month),
            ],
          )
          .watch()
          .map(
            (rows) => rows
                .map(
                  (row) => MonthlyPrediction(
                    id: row.read<String>('id'),
                    year: row.read<int>('year'),
                    month: row.read<int>('month'),
                    categoryId: row.read<String>('category_id'),
                    predictedAmount: row.read<double>('predicted_amount'),
                    note: row.read<String?>('note'),
                    createdAt: DateTime.parse(row.read<String>('created_at')),
                    updatedAt: DateTime.parse(row.read<String>('updated_at')),
                  ),
                )
                .toList(growable: false),
          );
    });
  }
}
