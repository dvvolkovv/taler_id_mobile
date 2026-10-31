import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// A file from another app, ready for the chat's attachment strip.
class SharedAttachment {
  final String path;
  final String name;

  /// 'image' or 'video' when the extension says so; null lets the server
  /// decide, as for any attached file.
  final String? type;

  const SharedAttachment({required this.path, required this.name, this.type});
}

/// What a share turns into in a chat: files for the attachment strip and
/// text for the input field.
class SharedItems {
  final List<SharedAttachment> attachments;

  /// Shared text and links, one per line; empty when there were none.
  final String text;

  const SharedItems({required this.attachments, required this.text});
}

const _imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
const _videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};

/// Splits shared [items] into attachments and text.
///
/// Text and link shares go to the input field rather than being uploaded:
/// a URL string is not a file, and uploading it failed silently (1.0.69).
SharedItems splitSharedItems(List<SharedMediaFile> items) {
  final attachments = <SharedAttachment>[];
  final textParts = <String>[];
  for (final item in items) {
    if (item.type == SharedMediaType.text || item.type == SharedMediaType.url) {
      if (item.path.isNotEmpty) textParts.add(item.path);
      // iOS sometimes sends an accompanying message alongside a URL share.
      final message = item.message;
      if (message != null && message.isNotEmpty && message != item.path) {
        textParts.add(message);
      }
      continue;
    }
    var path = item.path;
    if (path.isEmpty) continue;
    if (path.startsWith('file://')) path = _filePath(path);
    final name = path.split('/').last;
    if (name.isEmpty) continue;
    final dot = name.lastIndexOf('.');
    final ext = dot > 0 ? name.substring(dot + 1).toLowerCase() : '';
    final type = _imageExts.contains(ext)
        ? 'image'
        : _videoExts.contains(ext)
            ? 'video'
            : null;
    attachments.add(SharedAttachment(path: path, name: name, type: type));
  }
  return SharedItems(attachments: attachments, text: textParts.join('\n'));
}

/// `file://` URI → plain path. A name with `#`, `?` or an encoded `/` does
/// not parse back as a URI; then the scheme is simply cut off instead of the
/// whole share failing on one file.
String _filePath(String uri) {
  try {
    return Uri.parse(uri).toFilePath();
  } catch (_) {
    return uri.substring('file://'.length);
  }
}
