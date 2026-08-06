import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase _db;

  SettingsRepositoryImpl(this._db);

  SettingRow _defaultSettings() {
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    return SettingRow(
      id: 'default_settings',
      currency: 'PHP',
      accentTheme: 'ocean',
      themeMode: 0,
      weekStart: 1, // Monday
      compactMode: false,
      homeGreetingEnabled: true,
      biometricLock: false,
      notificationsEnabled: false,
      syncEnabled: false,
      createdAt: nowMs,
      updatedAt: nowMs,
    );
  }

  @override
  Stream<SettingRow> watchSettings() {
    return _db.select(_db.settings).watch().map((rows) {
      if (rows.isEmpty) {
        // We write to DB asynchronously. Drift handles this gracefully.
        _db.into(_db.settings).insertOnConflictUpdate(_defaultSettings());
        return _defaultSettings();
      }
      return rows.first;
    });
  }

  @override
  Future<SettingRow> getSettings() async {
    final rows = await _db.select(_db.settings).get();
    if (rows.isEmpty) {
      final defaultSetting = _defaultSettings();
      await _db.into(_db.settings).insertOnConflictUpdate(defaultSetting);
      return defaultSetting;
    }
    return rows.first;
  }

  @override
  Future<void> updateSettings(SettingRow settings) async {
    await _db.update(_db.settings).replace(settings);
  }
}
