import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taler_id_mobile/features/messenger/utils/shared_items.dart';

SharedMediaFile _item(String path, SharedMediaType type, {String? message}) =>
    SharedMediaFile(path: path, type: type, message: message);

void main() {
  test('a document becomes an attachment the server types', () {
    final r = splitSharedItems(
        [_item('/data/user/0/app/cache/Отчёт.pdf', SharedMediaType.file)]);
    expect(r.attachments.single.path, '/data/user/0/app/cache/Отчёт.pdf');
    expect(r.attachments.single.name, 'Отчёт.pdf');
    expect(r.attachments.single.type, isNull);
    expect(r.text, isEmpty);
  });

  test('images and videos are typed by extension, case-insensitively', () {
    final r = splitSharedItems([
      _item('/tmp/IMG_1.HEIC', SharedMediaType.image),
      _item('/tmp/clip.mov', SharedMediaType.video),
    ]);
    expect(r.attachments.map((a) => a.type), ['image', 'video']);
  });

  test('a file:// URI becomes a plain path, spaces decoded', () {
    final r = splitSharedItems([
      _item('file:///private/var/mobile/Shared/My%20Report.pdf',
          SharedMediaType.file),
    ]);
    expect(r.attachments.single.path, '/private/var/mobile/Shared/My Report.pdf');
    expect(r.attachments.single.name, 'My Report.pdf');
  });

  test('text and links go to the input field, with the iOS message', () {
    final r = splitSharedItems([
      _item('https://example.com/a', SharedMediaType.url,
          message: 'Look at this'),
      _item('Просто текст', SharedMediaType.text),
    ]);
    expect(r.attachments, isEmpty);
    expect(r.text, 'https://example.com/a\nLook at this\nПросто текст');
  });

  test('a message equal to the link is not repeated', () {
    final r = splitSharedItems([
      _item('https://example.com/a', SharedMediaType.url,
          message: 'https://example.com/a'),
    ]);
    expect(r.text, 'https://example.com/a');
  });

  test('items with an empty path are skipped', () {
    final r = splitSharedItems([
      _item('', SharedMediaType.file),
      _item('', SharedMediaType.text),
    ]);
    expect(r.attachments, isEmpty);
    expect(r.text, isEmpty);
  });

  test('files and text in one share are split, files keep their order', () {
    final r = splitSharedItems([
      _item('/tmp/a.pdf', SharedMediaType.file),
      _item('caption from the app', SharedMediaType.text),
      _item('/tmp/b.jpg', SharedMediaType.image),
    ]);
    expect(r.attachments.map((a) => a.name), ['a.pdf', 'b.jpg']);
    expect(r.text, 'caption from the app');
  });
}
