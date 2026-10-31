import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../utils/constants.dart';

/// Every location on the navigation stack, including screens pushed over or
/// inside a shell route.
///
/// `currentConfiguration.uri` only follows `go`: after `push` of a call
/// screen — and most call screens are pushed — it still shows the chat
/// underneath (go_router 14.8, checked 2026-10-31). A screen pushed over the
/// shell is its own top-level match; one pushed inside the shell is folded
/// into the shell's match, hence the walk into [ShellRouteMatch.matches].
Iterable<String> stackLocations(RouteMatchList configuration) =>
    _locations(configuration.matches);

Iterable<String> _locations(List<RouteMatchBase> matches) sync* {
  for (final m in matches) {
    yield m.matchedLocation;
    if (m is ShellRouteMatch) yield* _locations(m.matches);
  }
}

/// Whether a share from another app may open the recipient picker over the
/// navigation [stack] (see [stackLocations]).
///
/// Not while one of these screens is anywhere on it — the picker is opened
/// with `go`, which drops them without asking, even with something pushed
/// over them:
/// - a call screen: the conversation runs on it;
/// - mail compose: the typed letter would vanish, bypassing its "save the
///   draft?" question (`go` skips `PopScope`);
/// - the KYC web view: the verification step in progress would be lost.
///
/// The share waits until such a screen is closed — the dashboard checks again
/// on every route change.
bool canOpenSharePicker(Iterable<String> stack) =>
    !stack.any(_holdsSharePicker);

bool _holdsSharePicker(String location) =>
    location.startsWith(RouteConstants.voice) ||
    location.startsWith('/group-call/') ||
    location == '${RouteConstants.mail}/compose' ||
    location == '/kyc/webview';

/// Redirect for the picker route: without shared files there is nothing to
/// show, so back to the chat list.
String? sharePickerRedirect(Object? extra) =>
    extra is List<SharedMediaFile> && extra.isNotEmpty
        ? null
        : RouteConstants.messenger;
