import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../utils/constants.dart';

/// Every location on the navigation stack, pushed screens included.
///
/// `currentConfiguration.uri` only follows `go`: after `push` of a call
/// screen — and most call screens are pushed — it still shows the chat
/// underneath (go_router 14.8, checked 2026-10-31). Each pushed screen is its
/// own match here.
Iterable<String> stackLocations(RouteMatchList configuration) =>
    configuration.matches.map((m) => m.matchedLocation);

/// Whether a share from another app may open the recipient picker over the
/// navigation [stack] (see [stackLocations]).
///
/// Not while a call screen is anywhere on it: the picker is opened with `go`,
/// which would drop the screen the conversation runs on, even with something
/// pushed over it. The share waits until the call is minimised or over — the
/// dashboard checks again on every route change.
bool canOpenSharePicker(Iterable<String> stack) => !stack.any(_isCallScreen);

bool _isCallScreen(String location) =>
    location.startsWith(RouteConstants.voice) ||
    location.startsWith('/group-call/');

/// Redirect for the picker route: without shared files there is nothing to
/// show, so back to the chat list.
String? sharePickerRedirect(Object? extra) =>
    extra is List<SharedMediaFile> && extra.isNotEmpty
        ? null
        : RouteConstants.messenger;
