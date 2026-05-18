import 'package:hive/hive.dart';

class WindowState {
  final double width;
  final double height;
  final double x;
  final double y;
  final bool isMaximized;
  const WindowState({
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.isMaximized,
  });
}

class WindowStatePersistence {
  static const _boxName = 'window_state_v1';
  static const _key = 'state';

  Box<Map>? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  Future<void> save({
    required double width,
    required double height,
    required double x,
    required double y,
    required bool isMaximized,
  }) async {
    await _box!.put(_key, <String, dynamic>{
      'width': width,
      'height': height,
      'x': x,
      'y': y,
      'isMaximized': isMaximized,
    });
  }

  Future<WindowState?> load() async {
    final raw = _box!.get(_key);
    if (raw == null) return null;
    return WindowState(
      width: (raw['width'] as num).toDouble(),
      height: (raw['height'] as num).toDouble(),
      x: (raw['x'] as num).toDouble(),
      y: (raw['y'] as num).toDouble(),
      isMaximized: raw['isMaximized'] as bool,
    );
  }
}
