import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/domain/room_chat_text.dart';

/// Разбор аргумента `text` инструмента `send_room_chat`.
///
/// Инструмент объявлен дважды — у ассистента на экране звонка
/// (`VoiceCallScreen._configureAssistantSession`) и у отдельного
/// (`assistantToolSchemas`), — но проверяют они текст этой одной функцией,
/// поэтому правила покрыты здесь один раз.
void main() {
  group('parseRoomChatText — отказы', () {
    test('пустая строка', () {
      final res = parseRoomChatText('');

      expect(res.isValid, isFalse);
      expect(res.text, isNull);
      expect(res.refusal!.toLowerCase(), contains('empty'));
    });

    test('одни пробелы и переводы строк считаются пустотой', () {
      final res = parseRoomChatText('   \n\t  ');

      expect(res.isValid, isFalse);
      expect(res.refusal!.toLowerCase(), contains('empty'));
    });

    test('аргумента нет вовсе', () {
      final res = parseRoomChatText(null);

      expect(res.isValid, isFalse);
      expect(res.refusal!.toLowerCase(), contains('empty'));
    });

    test('не строка — отказ, а не TypeError', () {
      // Модель регулярно присылает число там, где объявлена строка. Приведение
      // `args['text'] as String?` бросило бы TypeError, внешний catch у обоих
      // вызывающих превратил бы его в «что-то сломалось».
      final res = parseRoomChatText(42);

      expect(res.isValid, isFalse);
      expect(res.refusal!.toLowerCase(), contains('empty'));
      expect(res.refusal!.toLowerCase(), isNot(contains('subtype')));
    });

    test('длиннее потолка — отказ, а не обрезка', () {
      final res = parseRoomChatText('а' * (kRoomChatMaxLength + 1));

      expect(res.isValid, isFalse);
      expect(res.text, isNull);
      expect(res.refusal!.toLowerCase(), contains('too long'));
      expect(res.refusal, contains('$kRoomChatMaxLength'));
    });

    test('длина меряется после обрезки пробелов', () {
      // Ровно потолок плюс окружающие пробелы: человеку за полем ввода такое
      // тоже позволено, отказывать здесь было бы строже.
      final res = parseRoomChatText('  ${'а' * kRoomChatMaxLength}  ');

      expect(res.isValid, isTrue);
      expect(res.text!.length, kRoomChatMaxLength);
    });
  });

  group('parseRoomChatText — нормальный случай', () {
    test('текст проходит и приходит обрезанным', () {
      final res = parseRoomChatText('  встречаемся в 18:00  ');

      expect(res.isValid, isTrue);
      expect(res.text, 'встречаемся в 18:00');
      expect(res.refusal, isNull);
    });

    test('ровно на потолке проходит', () {
      final res = parseRoomChatText('a' * kRoomChatMaxLength);

      expect(res.isValid, isTrue);
      expect(res.text!.length, kRoomChatMaxLength);
    });

    test('внутренние переводы строк сохраняются', () {
      final res = parseRoomChatText('строка\nвторая');

      expect(res.text, 'строка\nвторая');
    });

    test('потолок тот же, что у поля ввода человека', () {
      // room_chat_panel.dart: maxLength: 500.
      expect(kRoomChatMaxLength, 500);
    });
  });
}
