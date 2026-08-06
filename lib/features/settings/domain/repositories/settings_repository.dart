import '../../../../core/database/database.dart';

abstract class SettingsRepository {
  Stream<SettingRow> watchSettings();
  Future<SettingRow> getSettings();
  Future<void> updateSettings(SettingRow settings);
}
