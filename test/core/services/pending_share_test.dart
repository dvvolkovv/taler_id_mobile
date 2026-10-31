import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taler_id_mobile/core/services/pending_share.dart';

SharedMediaFile _file(String path) =>
    SharedMediaFile(path: path, type: SharedMediaType.file);

void main() {
  test('a share offered before anyone listens is still there to take', () {
    final slot = PendingShare()..offer([_file('/tmp/a.pdf')]);
    expect(slot.take()!.single.path, '/tmp/a.pdf');
  });

  test('take hands the share out exactly once', () {
    final slot = PendingShare()..offer([_file('/tmp/a.pdf')]);
    expect(slot.take(), isNotNull);
    expect(slot.take(), isNull);
  });

  test('a newer share replaces one nobody has taken', () {
    final slot = PendingShare()
      ..offer([_file('/tmp/old.pdf')])
      ..offer([_file('/tmp/new.pdf')]);
    expect(slot.take()!.single.path, '/tmp/new.pdf');
    expect(slot.take(), isNull);
  });

  test('an empty share is not stored', () {
    final slot = PendingShare()..offer(const []);
    expect(slot.files.value, isNull);
  });

  test('listeners hear the share arrive and the slot empty', () {
    final slot = PendingShare();
    final seen = <int?>[];
    slot.files.addListener(() => seen.add(slot.files.value?.length));
    slot.offer([_file('/tmp/a.pdf'), _file('/tmp/b.pdf')]);
    slot.take();
    expect(seen, [2, null]);
  });

  test('replacing a waiting share notifies; taking from an empty slot does not',
      () {
    final slot = PendingShare()..offer([_file('/tmp/old.pdf')]);
    var notified = 0;
    slot.files.addListener(() => notified++);
    slot.offer([_file('/tmp/new.pdf')]);
    expect(notified, 1);
    slot.take();
    expect(notified, 2);
    slot.take();
    expect(notified, 2);
  });

  test('the slot keeps its own unmodifiable copy', () {
    final source = [_file('/tmp/a.pdf')];
    final slot = PendingShare()..offer(source);
    source.add(_file('/tmp/b.pdf'));
    final taken = slot.take()!;
    expect(taken.length, 1);
    expect(() => taken.add(_file('/tmp/c.pdf')), throwsUnsupportedError);
  });
}
