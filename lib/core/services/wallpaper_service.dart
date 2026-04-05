import 'dart:async';
import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import '../storage/secure_storage_service.dart';

/// Keeps track of the user's chosen app-wide wallpaper.
///
/// The value is stored as a short id (e.g. `"bg_1"`) that corresponds to an
/// asset under `assets/backgrounds/`. `null` means "no wallpaper — use the
/// plain themed background".
///
/// [current] is a [ValueNotifier] so any widget above a [ValueListenableBuilder]
/// rebuilds instantly when the user picks a new wallpaper.
class WallpaperService {
  WallpaperService._();
  static final WallpaperService instance = WallpaperService._();

  final ValueNotifier<String?> current = ValueNotifier<String?>(null);

  /// Call once at app startup (after SecureStorageService is registered).
  Future<void> loadFromStorage() async {
    try {
      final id = await sl<SecureStorageService>().getWallpaper();
      current.value = id;
      // Warm up the image cache immediately so the wallpaper shows on the
      // very first frame — otherwise Image.asset would kick off an async
      // decode and the user would briefly see the plain background.
      if (id != null && id.isNotEmpty) {
        try {
          final completer = Completer<void>();
          final stream = AssetImage(assetFor(id))
              .resolve(ImageConfiguration.empty);
          late final ImageStreamListener listener;
          listener = ImageStreamListener(
            (_, __) {
              if (!completer.isCompleted) completer.complete();
              stream.removeListener(listener);
            },
            onError: (_, __) {
              if (!completer.isCompleted) completer.complete();
              stream.removeListener(listener);
            },
          );
          stream.addListener(listener);
          await completer.future.timeout(
            const Duration(seconds: 2),
            onTimeout: () {},
          );
        } catch (_) {}
      }
    } catch (_) {
      current.value = null;
    }
  }

  /// Persists + broadcasts a new selection. Pass `null` to clear.
  Future<void> set(String? id) async {
    current.value = id;
    try {
      await sl<SecureStorageService>().saveWallpaper(id);
    } catch (_) {
      // storage briefly unavailable — in-memory value still updates
    }
  }

  /// Available preset *image* wallpapers bundled with the app.
  static const List<String> imagePresets = [
    'bg_1', 'bg_2', 'bg_3', 'bg_4', 'bg_5', 'bg_6',
  ];

  static String assetFor(String id) => 'assets/backgrounds/$id.jpg';
  static String thumbFor(String id) => 'assets/backgrounds/${id}_thumb.jpg';

  /// Is this id a procedural pattern wallpaper (rendered via CustomPainter)?
  static bool isPatternId(String? id) => id != null && id.startsWith('pat_');
  static bool isImageId(String? id) => id != null && id.startsWith('bg_');
}
