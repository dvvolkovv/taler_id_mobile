import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// share_plus 10.x on iOS REQUIRES a non-zero `sharePositionOrigin` Rect —
/// without it, iOS throws:
///   `PlatformException: sharePositionOrigin argument must be set ...
///    must be non-zero and within coordinate space of source view`
///
/// The Rect is also used as the popover anchor on iPad. On iPhone any
/// non-zero rect works, but using the originating widget's screen-frame
/// makes the share sheet animate from the right place on iPad.
///
/// Pass the [BuildContext] of the widget that triggered the share (e.g.
/// the share button itself, captured via `Builder`). If the render box
/// has detached (e.g. caller popped a modal sheet first), a 1×1 rect is
/// used as fallback.
Rect shareOriginFromContext(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.attached) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return const Rect.fromLTWH(0, 0, 1, 1);
}

/// Convenience wrapper around [Share.share] that always passes a valid
/// `sharePositionOrigin` derived from [context]. Errors are swallowed
/// (most fire-and-forget callers don't care about user cancellation).
Future<void> shareText(BuildContext context, String text, {String? subject}) async {
  try {
    await Share.share(
      text,
      subject: subject,
      sharePositionOrigin: shareOriginFromContext(context),
    );
  } catch (e) {
    debugPrint('[shareText] error=$e');
  }
}

/// Same as [shareText] but for files via [Share.shareXFiles].
Future<void> shareFiles(
  BuildContext context,
  List<XFile> files, {
  String? text,
  String? subject,
}) async {
  try {
    await Share.shareXFiles(
      files,
      text: text,
      subject: subject,
      sharePositionOrigin: shareOriginFromContext(context),
    );
  } catch (e) {
    debugPrint('[shareFiles] error=$e');
  }
}
