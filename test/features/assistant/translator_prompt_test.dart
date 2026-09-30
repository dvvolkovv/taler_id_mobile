import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_schema.dart';
import 'package:taler_id_mobile/features/assistant/tools/translator_prompt.dart';

void main() {
  group('translatorInstructions', () {
    test('names the pair and both directions', () {
      final s = translatorInstructions(owner: 'ru', target: 'sk');
      expect(s, contains('BETWEEN RUSSIAN AND SLOVAK'));
      expect(s, contains('Russian speech → say the whole utterance in Slovak'));
      expect(s, contains('Slovak speech → say the whole utterance in Russian'));
    });

    test('no longer tells the model to auto-detect languages', () {
      // Auto-detection is what rendered everything into English.
      expect(translatorInstructions(owner: 'ru', target: 'sk'),
          isNot(contains('Auto-detect')));
    });

    test('mentions both voice commands', () {
      final s = translatorInstructions(owner: 'ru', target: 'de');
      expect(s, contains('set_translator_languages'));
      expect(s, contains('exit_translator_mode'));
      expect(s, contains('выбери язык X'));
    });

    test('without a target asks for the language in the owner\'s language', () {
      expect(translatorInstructions(owner: 'ru'),
          contains('"На какой язык переводить?"'));
      expect(translatorInstructions(owner: 'en'),
          contains('"Which language should I translate into?"'));
      expect(translatorInstructions(owner: 'ru'), isNot(contains('BETWEEN')));
    });
  });

  group('normalizeLangCode', () {
    test('accepts known codes in any case/spacing', () {
      expect(normalizeLangCode('SK'), 'sk');
      expect(normalizeLangCode(' de '), 'de');
    });
    test('rejects names, empties and non-strings', () {
      expect(normalizeLangCode('slovak'), isNull);
      expect(normalizeLangCode(''), isNull);
      expect(normalizeLangCode(null), isNull);
      expect(normalizeLangCode(42), isNull);
    });
  });

  group('translatorPairFromArgs', () {
    test('explicit pair', () {
      expect(translatorPairFromArgs({'lang_a': 'ru', 'lang_b': 'sk'}, 'ru'),
          (a: 'ru', b: 'sk'));
    });
    test('owner language defaults to the app locale', () {
      expect(translatorPairFromArgs({'lang_b': 'sk'}, 'ru'), (a: 'ru', b: 'sk'));
    });
    test('a lone foreign language is the other person\'s', () {
      expect(translatorPairFromArgs({'lang_a': 'sk'}, 'ru'), (a: 'ru', b: 'sk'));
    });
    test('unknown other language means "ask first"', () {
      expect(translatorPairFromArgs({}, 'ru'), isNull);
      expect(translatorPairFromArgs({'lang_a': 'ru'}, 'ru'), isNull);
      expect(translatorPairFromArgs({'lang_b': 'slovak'}, 'ru'), isNull);
      expect(translatorPairFromArgs({'lang_a': 'ru', 'lang_b': 'ru'}, 'ru'), isNull);
    });
  });

  group('translator tool schemas', () {
    final translatorTools = assistantToolSchemas(translatorMode: true);
    final names = translatorTools.map((t) => t['name']).toList();

    test('translator mode has exactly exit + set language', () {
      expect(names, unorderedEquals(['exit_translator_mode', 'set_translator_languages']));
    });

    test('set_translator_languages requires lang', () {
      final t = translatorTools.singleWhere((t) => t['name'] == 'set_translator_languages');
      expect((t['parameters'] as Map)['required'], ['lang']);
    });

    test('enter_translator_mode requires the other person\'s language', () {
      final t = assistantToolSchemas(translatorMode: false)
          .singleWhere((t) => t['name'] == 'enter_translator_mode');
      expect((t['parameters'] as Map)['required'], ['lang_b']);
      expect(t['description'] as String, contains('ask'));
    });
  });
}
