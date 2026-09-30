// Instructions for the assistant's translator mode (OpenAI Realtime session).
//
// The language pair is part of the instructions. It used to live only in the
// badge flags while the session was told to "auto-detect the two languages":
// the model then rendered everything into English — Russian and even Slovak
// speech alike — and a spoken "выбери язык словацкий" was answered as chat
// instead of changing anything. Now the pair is fixed up front and changed
// by voice through the `set_translator_languages` tool.

/// English names the model understands; keys are ISO 639-1 codes.
const Map<String, String> translatorLanguageNames = {
  'af': 'Afrikaans', 'ar': 'Arabic', 'az': 'Azerbaijani', 'be': 'Belarusian',
  'bg': 'Bulgarian', 'bn': 'Bengali', 'bs': 'Bosnian', 'ca': 'Catalan',
  'cs': 'Czech', 'cy': 'Welsh', 'da': 'Danish', 'de': 'German',
  'el': 'Greek', 'en': 'English', 'es': 'Spanish', 'et': 'Estonian',
  'eu': 'Basque', 'fa': 'Persian', 'fi': 'Finnish', 'fr': 'French',
  'ga': 'Irish', 'gl': 'Galician', 'gu': 'Gujarati', 'ha': 'Hausa',
  'he': 'Hebrew', 'hi': 'Hindi', 'hr': 'Croatian', 'hu': 'Hungarian',
  'hy': 'Armenian', 'id': 'Indonesian', 'is': 'Icelandic', 'it': 'Italian',
  'ja': 'Japanese', 'ka': 'Georgian', 'kk': 'Kazakh', 'km': 'Khmer',
  'kn': 'Kannada', 'ko': 'Korean', 'ky': 'Kyrgyz', 'lo': 'Lao',
  'lt': 'Lithuanian', 'lv': 'Latvian', 'mk': 'Macedonian', 'ml': 'Malayalam',
  'mn': 'Mongolian', 'mr': 'Marathi', 'ms': 'Malay', 'mt': 'Maltese',
  'my': 'Burmese', 'ne': 'Nepali', 'nl': 'Dutch', 'no': 'Norwegian',
  'pa': 'Punjabi', 'pl': 'Polish', 'ps': 'Pashto', 'pt': 'Portuguese',
  'ro': 'Romanian', 'ru': 'Russian', 'si': 'Sinhala', 'sk': 'Slovak',
  'sl': 'Slovenian', 'so': 'Somali', 'sq': 'Albanian', 'sr': 'Serbian',
  'sv': 'Swedish', 'sw': 'Swahili', 'ta': 'Tamil', 'te': 'Telugu',
  'tg': 'Tajik', 'th': 'Thai', 'tl': 'Filipino', 'tr': 'Turkish',
  'uk': 'Ukrainian', 'ur': 'Urdu', 'uz': 'Uzbek', 'vi': 'Vietnamese',
  'yo': 'Yoruba', 'zh': 'Chinese', 'zu': 'Zulu',
};

/// Lower-cased ISO 639-1 code if the model sent one we know, else null
/// ("SK", " sk " → "sk"; "slovak", "" → null).
String? normalizeLangCode(Object? raw) {
  if (raw is! String) return null;
  final code = raw.trim().toLowerCase();
  return translatorLanguageNames.containsKey(code) ? code : null;
}

/// The translator's pair once the assistant's `enter_translator_mode` args are
/// read, or null when the other person's language is unknown and the user has
/// to be asked first. [locale] is the owner's language when the model left
/// lang_a out. A lone language that is not the owner's ("на словацкий" →
/// lang_a: "sk") is taken as the other person's language.
({String a, String b})? translatorPairFromArgs(
  Map<String, dynamic> args,
  String locale,
) {
  var a = normalizeLangCode(args['lang_a']);
  var b = normalizeLangCode(args['lang_b']);
  final owner = normalizeLangCode(locale) ?? 'ru';
  if (b == null && a != null && a != owner) {
    b = a;
    a = owner;
  }
  a ??= owner;
  if (b == null || b == a) return null;
  return (a: a, b: b);
}

/// Session instructions for translator mode. [target] null means the other
/// person's language has not been chosen yet (should not normally happen —
/// the assistant asks before switching).
String translatorInstructions({required String owner, String? target}) {
  final a = translatorLanguageNames[owner] ?? owner;
  final b = target == null ? null : (translatorLanguageNames[target] ?? target);
  final ask = owner == 'ru'
      ? '"На какой язык переводить?"'
      : '"Which language should I translate into?"';
  final languages = b == null
      ? 'LANGUAGES: the owner speaks $a. The second language is NOT chosen yet.\n'
          'Until it is chosen, whatever anyone says, say ONLY this, in $a: $ask\n\n'
      : 'YOU ARE A LIVE INTERPRETER BETWEEN ${a.toUpperCase()} AND ${b.toUpperCase()}.\n\n'
          'The phone lies on the table between two people. One speaks $a, the '
          'other speaks $b. Neither of them understands the other\'s language AT ALL.\n\n'
          'For EVERY utterance:\n'
          '- $a speech → say the whole utterance in $b.\n'
          '- $b speech → say the whole utterance in $a.\n'
          '- Any other language → say it in $a.\n\n'
          'Translate the ENTIRE utterance — every sentence, every word. Your output '
          'must be 100% in the target language: not a single word left in the '
          'original language, even when the two languages are related and words '
          'look alike. Never repeat the original. Never output both languages.\n\n';
  return 'YOU ARE A LIVE TRANSLATION MACHINE. NOT AN ASSISTANT. NOT A CHATBOT.\n\n'
      '$languages'
      'RULES:\n'
      '1. Just the translation, as if you were the speaker. No commentary, no '
      '"the speaker said".\n'
      '2. You are INVISIBLE. Do not answer questions, do not offer help, do not '
      'ask anything, no filler like "got it". Questions and requests are part of '
      'the conversation — translate them.\n'
      '3. Silence, noise, unintelligible audio → output NOTHING.\n'
      '4. Tone: match the speaker. Keep names, numbers, places exact.\n\n'
      'COMMANDS FROM THE OWNER (do NOT translate these, say nothing, just call the tool):\n'
      '- Choosing or changing the language: "выбери язык X", "переводи на X", '
      '"переключи на X", "язык X", "translate into X", "switch to X", or just the '
      'name of a language said on its own ("словацкий") → call '
      'set_translator_languages with the ISO 639-1 code of X.\n'
      '  A question or sentence that merely mentions a language ("вы говорите '
      'по-словацки?") is conversation — translate it.\n'
      '- Exit: "Ассистент, стоп", "выйди из роли", "хватит переводить", '
      '"stop translator", "exit translator" → call exit_translator_mode.\n\n'
      'Begin listening. Say nothing until someone speaks.';
}
