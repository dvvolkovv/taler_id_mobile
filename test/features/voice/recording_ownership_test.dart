import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/presentation/controllers/recording_ownership.dart';

/// Встреча 17.11.2026 записалась наполовину: запись начали из веба, через
/// полчаса владелец комнаты зашёл с телефона, а уходя с него, остановил
/// запись всем — встреча шла ещё полчаса без неё. Телефон считал запись своей
/// только потому, что застал рекордер в комнате при входе.
///
/// Экран звонка в тесте не поднять, поэтому здесь закреплены сами правила:
/// чья запись и когда уход из звонка вправе её остановить.
void main() {
  const me = 'u1#dev1';
  const other = 'guest-web';

  bool stop({
    String? localId = me,
    String? initiatorId = me,
    bool active = true,
    bool roomConnected = true,
    List<String> remote = const [],
  }) =>
      RecordingOwnership.stopOnLeave(
        localId: localId,
        initiatorId: initiatorId,
        active: active,
        roomConnected: roomConnected,
        remoteIdentities: remote,
      );

  group('stopOnLeave', () {
    test('the initiator leaving last stops the recording', () {
      expect(stop(remote: const ['meeting-recorder']), isTrue);
    });

    test('the initiator leaving while people remain keeps it running', () {
      expect(stop(remote: const ['meeting-recorder', other]), isFalse);
    });

    test('someone who joined mid-recording never stops it on leaving', () {
      // Тот самый случай 17.11: инициатор неизвестен, остальные на месте.
      expect(
        stop(initiatorId: null, remote: const ['meeting-recorder', other]),
        isFalse,
      );
      // И даже оставшись последним — тогда запись закроет сам рекордер.
      expect(stop(initiatorId: null, remote: const ['meeting-recorder']), isFalse);
    });

    test('a bystander of somebody else\'s recording never stops it', () {
      expect(stop(initiatorId: other, remote: const ['meeting-recorder']), isFalse);
    });

    test('service participants do not count as people staying behind', () {
      expect(
        stop(remote: const ['meeting-recorder', 'ai-assistant', 'voice-translator']),
        isTrue,
      );
    });

    test('a dropped connection does not stop it — who is left is unknown', () {
      // После обрыва список участников пуст или устарел, и «никого не
      // осталось» здесь значит лишь «мы больше не видим комнату».
      expect(stop(roomConnected: false, remote: const []), isFalse);
    });

    test('nothing to stop when no recording is running', () {
      expect(stop(active: false), isFalse);
    });

    test('an unknown local identity stops nothing', () {
      expect(stop(localId: null, initiatorId: null), isFalse);
    });
  });

  group('resetWhenRecorderLeft', () {
    test('someone who joined mid-recording lets go once the recorder is gone', () {
      expect(
        RecordingOwnership.resetWhenRecorderLeft(localId: me, initiatorId: null),
        isTrue,
      );
    });

    test('a bystander of somebody else\'s recording lets go too', () {
      expect(
        RecordingOwnership.resetWhenRecorderLeft(localId: me, initiatorId: other),
        isTrue,
      );
    });

    test('the initiator keeps its state and can still press stop', () {
      expect(
        RecordingOwnership.resetWhenRecorderLeft(localId: me, initiatorId: me),
        isFalse,
      );
    });
  });
}
