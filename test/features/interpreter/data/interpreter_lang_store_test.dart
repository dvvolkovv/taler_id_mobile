import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/storage/secure_storage_service.dart';
import 'package:taler_id_mobile/features/interpreter/data/interpreter_lang_store.dart';
import 'package:taler_id_mobile/features/interpreter/domain/interpreter_models.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService storage;
  late InterpreterLangStore store;

  final catalog = InterpreterCatalog(
    enabled: true,
    languages: const [
      InterpreterLanguage(code: 'ru', name: 'Русский'),
      InterpreterLanguage(code: 'en', name: 'English'),
    ],
  );

  setUp(() {
    storage = MockSecureStorageService();
    store = InterpreterLangStore(storage);
  });

  group('initial', () {
    test('returns the stored language when the catalog still supports it',
        () async {
      when(() => storage.read('interpreter_lang'))
          .thenAnswer((_) async => 'en');

      final result = await store.initial(catalog, 'ru');

      expect(result, 'en');
    });

    test(
        'falls back to the app locale when the stored language is no longer supported',
        () async {
      when(() => storage.read('interpreter_lang'))
          .thenAnswer((_) async => 'de');

      final result = await store.initial(catalog, 'ru');

      expect(result, 'ru');
    });

    test('falls back to the app locale when nothing is stored', () async {
      when(() => storage.read('interpreter_lang'))
          .thenAnswer((_) async => null);

      final result = await store.initial(catalog, 'en');

      expect(result, 'en');
    });

    test('falls back to en when neither stored nor app locale is supported',
        () async {
      when(() => storage.read('interpreter_lang'))
          .thenAnswer((_) async => null);

      final result = await store.initial(catalog, 'fr');

      expect(result, 'en');
    });
  });

  group('remember', () {
    test('writes the chosen code under the interpreter_lang key', () async {
      when(() => storage.write('interpreter_lang', 'de'))
          .thenAnswer((_) async {});

      await store.remember('de');

      verify(() => storage.write('interpreter_lang', 'de')).called(1);
    });
  });
}
