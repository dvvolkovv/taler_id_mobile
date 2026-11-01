/// Extracts the session code from a scanned `talerid://interp/<code>` link.
///
/// Scheme and host are matched case-insensitively (a system camera or a
/// third-party QR reader may hand back the link with whatever casing it
/// decided to normalize to), but the code segment itself is returned exactly
/// as scanned — the backend is the one that normalizes it, not the client.
/// A trailing slash after the code is tolerated. Anything else — a bare
/// `https://` link, a different `talerid://` path (e.g. `talerid://user/x`),
/// not a URI at all, or an empty string — returns `null`.
String? codeFromScan(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  if (uri.scheme.toLowerCase() != 'talerid') return null;
  if (uri.host.toLowerCase() != 'interp') return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 1) return null;
  return segments.first;
}

/// Builds the deep link a host's QR code encodes.
String interpreterLink(String code) => 'talerid://interp/$code';
