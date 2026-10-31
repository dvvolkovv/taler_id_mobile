import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  test('a fractional video duration from iOS still parses', () {
    final file = SharedMediaFile.fromMap({
      'path': '/private/var/mobile/Containers/Shared/AppGroup/x/clip.mov',
      'type': 'video',
      'duration': 10033.333333333334,
    });
    expect(file.duration, 10033);
    expect(file.type, SharedMediaType.video);
  });

  test('a missing duration stays null', () {
    final file =
        SharedMediaFile.fromMap({'path': '/tmp/a.pdf', 'type': 'file'});
    expect(file.duration, isNull);
  });
}
