import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:taler_id_mobile/features/assistant/data/assistant_draft_storage.dart';

void main() {
  late Directory tmp;
  late Box<String> box;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('draft_test');
    Hive.init(tmp.path);
    box = await Hive.openBox<String>('assistant_draft_test');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tmp.delete(recursive: true);
  });

  test('save/read/clear draft', () {
    final s = AssistantDraftStorage(box);
    expect(s.read(), isNull);
    s.save('недописанный текст');
    expect(s.read(), 'недописанный текст');
    s.clear();
    expect(s.read(), isNull);
  });

  test('empty string clears draft', () {
    final s = AssistantDraftStorage(box);
    s.save('x');
    s.save('');
    expect(s.read(), isNull);
  });
}
