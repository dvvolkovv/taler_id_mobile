import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/features/calendar/data/datasources/calendar_local_datasource.dart';
import 'package:taler_id_mobile/features/calendar/domain/entities/calendar_event_entity.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override Future<String?> getApplicationDocumentsPath() async => dir;
  @override Future<String?> getApplicationSupportPath() async => dir;
  @override Future<String?> getTemporaryPath() async => dir;
}

CalendarEventEntity ev(String id, {DateTime? startAt, DateTime? updatedAt}) =>
    CalendarEventEntity(
      id: id,
      title: 'T-$id',
      startAt: startAt ?? DateTime.parse('2026-05-14T10:00:00Z'),
      createdAt: DateTime.parse('2026-05-14T09:00:00Z'),
      updatedAt: updatedAt ?? DateTime.parse('2026-05-14T09:00:00Z'),
    );

void main() {
  late Directory tempDir;

  setUpAll(() { TestWidgetsFlutterBinding.ensureInitialized(); });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cal_local_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(CalendarLocalDataSource.boxName);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('upsert + getAll returns events in startAt-asc order', () async {
    final ds = CalendarLocalDataSource();
    await ds.upsert(ev('a', startAt: DateTime.parse('2026-05-14T12:00:00Z')));
    await ds.upsert(ev('b', startAt: DateTime.parse('2026-05-14T09:00:00Z')));
    final list = await ds.getAll();
    expect(list.map((e) => e.id).toList(), ['b', 'a']);
  });

  test('remove drops the entry', () async {
    final ds = CalendarLocalDataSource();
    await ds.upsert(ev('a'));
    await ds.remove('a');
    expect((await ds.getAll()).isEmpty, true);
  });

  test('upsert replaces existing by id', () async {
    final ds = CalendarLocalDataSource();
    await ds.upsert(ev('a'));
    await ds.upsert(ev('a').copyWith(title: 'updated'));
    final list = await ds.getAll();
    expect(list.length, 1);
    expect(list[0].title, 'updated');
  });

  test('watchAll emits on changes', () async {
    final ds = CalendarLocalDataSource();
    final emissions = <int>[];
    final sub = ds.watchAll().listen((events) => emissions.add(events.length));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(ev('a'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ds.upsert(ev('b'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, contains(1));
    expect(emissions, contains(2));
    await sub.cancel();
  });
}
