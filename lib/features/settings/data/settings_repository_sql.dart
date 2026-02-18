import 'package:finora/core/database/app_database.dart';
import 'package:finora/core/errors/repository_error.dart';
import 'package:finora/features/settings/domain/app_settings.dart';
import 'package:finora/features/settings/domain/settings_repository.dart';

class SettingsRepositorySql implements SettingsRepository {
  SettingsRepositorySql(this._db);

  final AppDatabase _db;

  static const _defaultCurrencyCode = 'HUF';
  static const _defaultCurrencySymbol = 'Ft';

  @override
  Future<void> ensureInitialized() async {
    await guardRepositoryCall('SettingsRepository.ensureInitialized', () async {
      final rows = await _db.customSelect(
        'SELECT id FROM app_settings WHERE id = 1 LIMIT 1',
      ).get();
      if (rows.isNotEmpty) {
        return;
      }

      final now = DateTime.now().toIso8601String();
      await _db.customStatement(
        '''
        INSERT INTO app_settings (id, currency_code, currency_symbol, updated_at)
        VALUES (1, ?, ?, ?)
        ''',
        [_defaultCurrencyCode, _defaultCurrencySymbol, now],
      );
    });
  }

  @override
  Future<AppSettings> get() async {
    await ensureInitialized();
    return guardRepositoryCall('SettingsRepository.get', () async {
      final row = await _db.customSelect(
        '''
        SELECT currency_code, currency_symbol, updated_at
        FROM app_settings
        WHERE id = 1
        LIMIT 1
        ''',
      ).getSingle();
      return _mapRow(
        currencyCode: row.read<String>('currency_code'),
        currencySymbol: row.read<String>('currency_symbol'),
        updatedAt: row.read<String>('updated_at'),
      );
    });
  }

  @override
  Stream<AppSettings> watch() {
    return guardRepositoryStream('SettingsRepository.watch', () {
      return _db
          .customSelect(
            '''
            SELECT currency_code, currency_symbol, updated_at
            FROM app_settings
            WHERE id = 1
            LIMIT 1
            ''',
          )
          .watchSingleOrNull()
          .asyncMap((row) async {
        if (row == null) {
          await ensureInitialized();
          final fallback = await get();
          return fallback;
        }
        return _mapRow(
          currencyCode: row.read<String>('currency_code'),
          currencySymbol: row.read<String>('currency_symbol'),
          updatedAt: row.read<String>('updated_at'),
        );
      });
    });
  }

  @override
  Future<void> update(AppSettings settings) async {
    await ensureInitialized();
    await guardRepositoryCall('SettingsRepository.update', () async {
      await _db.customStatement(
        '''
        UPDATE app_settings
        SET currency_code = ?, currency_symbol = ?, updated_at = ?
        WHERE id = 1
        ''',
        [
          settings.currencyCode,
          settings.currencySymbol,
          settings.updatedAt.toIso8601String(),
        ],
      );
    });
  }

  AppSettings _mapRow({
    required String currencyCode,
    required String currencySymbol,
    required String updatedAt,
  }) {
    return AppSettings(
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
