import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/presentation/controllers/recording_dialect.dart';

void main() {
  group('распознавание дублёра', () {
    test('пакет с поднятой пометкой — дублёр', () {
      expect(RecordingDialect.isTwin({'type': 'recording_approved', 'srvRec': true}), isTrue);
    });

    test('обычный пакет без пометки — не дублёр', () {
      expect(RecordingDialect.isTwin({'type': 'recording_approved'}), isFalse);
    });

    test('пометка засчитывается только как настоящее true', () {
      // Пакет приходит из JSON от другого клиента, поле может оказаться чем
      // угодно. Строка 'true' или единица не должны глушить обработку: лучше
      // показать диалог дважды, чем не показать вовсе.
      expect(RecordingDialect.isTwin({'srvRec': 'true'}), isFalse);
      expect(RecordingDialect.isTwin({'srvRec': 1}), isFalse);
      expect(RecordingDialect.isTwin({'srvRec': null}), isFalse);
    });
  });

  group('сведение типов серверной записи к обработчикам', () {
    test('каждый тип серверной записи сводится к своему обработчику', () {
      expect(RecordingDialect.legacyTypeFor('srv_rec_consent_request'), 'recording_consent_request');
      expect(RecordingDialect.legacyTypeFor('srv_rec_consent_response'), 'recording_consent_response');
      expect(RecordingDialect.legacyTypeFor('srv_rec_approved'), 'recording_approved');
      expect(RecordingDialect.legacyTypeFor('srv_rec_denied'), 'recording_denied');
      expect(RecordingDialect.legacyTypeFor('srv_rec_ended'), 'recording_ended');
    });

    test('чужие типы не сводятся никуда', () {
      expect(RecordingDialect.legacyTypeFor('chat_message'), isNull);
      expect(RecordingDialect.legacyTypeFor('recording_approved'), isNull);
      expect(RecordingDialect.legacyTypeFor('recording_denied_late'), isNull);
    });
  });

  group('подъём прежнего типа до родного', () {
    test('у каждого прежнего типа есть родной', () {
      expect(RecordingDialect.serverTypeFor('recording_consent_request'), 'srv_rec_consent_request');
      expect(RecordingDialect.serverTypeFor('recording_consent_response'), 'srv_rec_consent_response');
      expect(RecordingDialect.serverTypeFor('recording_approved'), 'srv_rec_approved');
      expect(RecordingDialect.serverTypeFor('recording_denied'), 'srv_rec_denied');
      expect(RecordingDialect.serverTypeFor('recording_ended'), 'srv_rec_ended');
    });

    test('у типов без пары родного нет', () {
      // recording_denied_late — уход участника, отклонившего уже идущую
      // запись; в веб-диалекте такого пакета нет вовсе, поднимать нечего.
      expect(RecordingDialect.serverTypeFor('recording_denied_late'), isNull);
      expect(RecordingDialect.serverTypeFor('transcription_status'), isNull);
      expect(RecordingDialect.serverTypeFor('srv_rec_approved'), isNull);
    });

    test('подъём и сведение обратны друг другу', () {
      for (final legacy in [
        'recording_consent_request',
        'recording_consent_response',
        'recording_approved',
        'recording_denied',
        'recording_ended',
      ]) {
        final native = RecordingDialect.serverTypeFor(legacy)!;
        expect(RecordingDialect.legacyTypeFor(native), legacy);
      }
    });
  });

  group('сборка дублёра', () {
    test('дублёр несёт тот же груз под другим типом и с пометкой', () {
      final twin = RecordingDialect.twinFor({
        'type': 'srv_rec_consent_request',
        'initiatorId': 'guest-1',
        'initiatorName': 'Инициатор',
      })!;

      expect(twin['type'], 'recording_consent_request');
      expect(twin['srvRec'], isTrue);
      expect(twin['initiatorId'], 'guest-1');
      expect(twin['initiatorName'], 'Инициатор');
    });

    test('дублёр не уносит msgId оригинала', () {
      // Главная ловушка: отправка проставляет msgId прямо в переданную карту.
      // Дублёр с тем же идентификатором приёмная сторона отбросит как повтор,
      // и запрос согласия молча не доедет — ровно тот отказ, который эта
      // правка и чинит. Поэтому идентификатора в дублёре быть не должно:
      // отправка выдаст ему свой.
      final twin = RecordingDialect.twinFor({
        'type': 'srv_rec_approved',
        'initiatorId': 'guest-1',
        'msgId': 'abc_7',
      })!;

      expect(twin.containsKey('msgId'), isFalse);
    });

    test('оригинал при сборке дублёра не меняется', () {
      final original = <String, dynamic>{
        'type': 'srv_rec_ended',
        'initiatorId': 'guest-1',
      };

      RecordingDialect.twinFor(original);

      expect(original['type'], 'srv_rec_ended');
      expect(original.containsKey('srvRec'), isFalse);
    });

    test('у пакета не про серверную запись дублёра нет', () {
      expect(RecordingDialect.twinFor({'type': 'recording_approved'}), isNull);
      expect(RecordingDialect.twinFor({'type': 'chat_message'}), isNull);
    });

    test('дублёр у дублёра не собирается', () {
      // Защита от петли: пришедший дублёр не должен породить ещё один.
      expect(
        RecordingDialect.twinFor({'type': 'recording_approved', 'srvRec': true}),
        isNull,
      );
    });
  });
}
