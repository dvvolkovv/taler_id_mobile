import '../../../core/storage/secure_storage_service.dart';
import '../domain/interpreter_models.dart';

/// Remembers the last language chosen on the start screen, on-device only —
/// nothing is written to the profile.
class InterpreterLangStore {
  static const _key = 'interpreter_lang';

  final SecureStorageService storage;

  InterpreterLangStore(this.storage);

  /// The language the start screen should preselect: the stored choice if
  /// the catalog still supports it, else the app's own locale if supported,
  /// else `'en'`.
  Future<String> initial(
      InterpreterCatalog catalog, String appLocaleCode) async {
    final supported = catalog.languages.map((l) => l.code).toSet();

    final stored = await storage.read(_key);
    if (stored != null && supported.contains(stored)) return stored;

    if (supported.contains(appLocaleCode)) return appLocaleCode;

    return 'en';
  }

  Future<void> remember(String code) => storage.write(_key, code);
}
