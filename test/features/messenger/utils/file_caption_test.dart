import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/utils/file_caption.dart';

void main() {
  test('a document shows the comment typed with it', () {
    expect(
        showsFileCaption(
            content: 'Посмотри до пятницы',
            fileName: 'Отчёт.pdf',
            fileType: 'document'),
        isTrue);
  });

  test('a document sent without a comment does not repeat its name', () {
    expect(
        showsFileCaption(
            content: 'Отчёт.pdf', fileName: 'Отчёт.pdf', fileType: 'document'),
        isFalse);
  });

  test('photos and videos show their caption, as before', () {
    expect(
        showsFileCaption(
            content: 'на память', fileName: 'IMG_1.jpg', fileType: 'image'),
        isTrue);
    expect(
        showsFileCaption(
            content: 'на память', fileName: 'clip.mp4', fileType: 'video'),
        isTrue);
  });

  test('an empty text is no caption', () {
    expect(
        showsFileCaption(content: '', fileName: 'IMG_1.jpg', fileType: 'image'),
        isFalse);
  });

  test('audio never shows its text as a caption', () {
    expect(
        showsFileCaption(
            content: 'что-то', fileName: 'voice.m4a', fileType: 'audio'),
        isFalse);
  });
}
