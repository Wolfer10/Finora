import 'package:finora/features/settings/domain/app_settings.dart';

abstract class SettingsRepository {
  Future<void> ensureInitialized();
  Future<AppSettings> get();
  Stream<AppSettings> watch();
  Future<void> update(AppSettings settings);
}
