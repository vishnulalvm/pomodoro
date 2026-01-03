import '../models/app_settings.dart';
import '../services/hive_service.dart';

class SettingsRepository {
  final HiveService _hiveService;

  SettingsRepository(this._hiveService);

  Future<AppSettings> getSettings() async {
    final box = _hiveService.settings;
    if (box.isEmpty) {
      final defaultSettings = AppSettings();
      await box.put('settings', defaultSettings);
      return defaultSettings;
    }
    return box.get('settings')!;
  }

  Future<void> updateSettings(AppSettings settings) async {
    final box = _hiveService.settings;
    await box.put('settings', settings);
  }

  Future<void> resetToDefaults() async {
    final box = _hiveService.settings;
    await box.put('settings', AppSettings());
  }

  Stream<AppSettings?> watchSettings() async* {
    final box = _hiveService.settings;
    // Emit current value immediately
    if (box.isNotEmpty) {
      yield box.get('settings');
    } else {
      // Should rely on getSettings to init default
      yield AppSettings();
    }

    await for (final _ in box.watch(key: 'settings')) {
      yield box.get('settings');
    }
  }
}
