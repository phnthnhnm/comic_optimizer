import '../../core/result.dart';
import '../../domain/models/app_settings.dart';

/// Contract for persisting and loading app settings.
abstract interface class ISettingsService {
  Future<Result<AppSettings>> loadSettings();
  Future<Result<void>> saveSettings(AppSettings settings);
  Future<Result<void>> clearAll();
  Map<String, dynamic> getAllRaw();

  Future<Result<void>> setRawString(String key, String value);
  Future<Result<void>> setRawBool(String key, bool value);
  Future<Result<void>> setRawInt(String key, int value);
  Future<Result<void>> setRawDouble(String key, double value);
  Future<Result<void>> setRawStringList(String key, List<String> value);
}
