import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taler_id_mobile/core/router/share_picker_gate.dart';
import 'package:taler_id_mobile/core/utils/constants.dart';

void main() {
  test('the picker opens over ordinary screens', () {
    for (final location in [
      RouteConstants.assistant,
      RouteConstants.messenger,
      '/dashboard/messenger/c-1',
      RouteConstants.messengerShare,
      RouteConstants.settings,
      RouteConstants.calendar,
    ]) {
      expect(canOpenSharePicker(location), isTrue, reason: location);
    }
  });

  test('the picker waits while a call screen is open', () {
    for (final location in [
      RouteConstants.voice,
      '/group-call/gc-1',
      '/group-call/gc-1/lobby',
    ]) {
      expect(canOpenSharePicker(location), isFalse, reason: location);
    }
  });

  test('the picker route without files goes back to the chat list', () {
    expect(sharePickerRedirect(null), RouteConstants.messenger);
    expect(sharePickerRedirect(const []), RouteConstants.messenger);
    expect(sharePickerRedirect('not a list'), RouteConstants.messenger);
  });

  test('the picker route with files stays', () {
    expect(
      sharePickerRedirect(
          [SharedMediaFile(path: '/tmp/a.pdf', type: SharedMediaType.file)]),
      isNull,
    );
  });
}
