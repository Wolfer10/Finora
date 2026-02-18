import 'package:finora/features/predictions/domain/monthly_prediction.dart';

abstract class PredictionRepository {
  Future<void> upsert(MonthlyPrediction prediction);
  Future<void> softDelete(String id);
  Stream<List<MonthlyPrediction>> watchByMonth(int year, int month);
}
