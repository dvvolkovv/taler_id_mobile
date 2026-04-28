# Call Details: Tap Participant Opens User Profile

**Date:** 2026-04-28
**Status:** Approved
**Scope:** Mobile (Flutter) only — no backend, API, or routing changes

## Summary

In the Call Details screen (`/dashboard/call-history` → tap a call), each row in the Participants list is currently a static text item. This design makes those rows tappable: tapping a participant opens that user's profile (existing `UserProfileScreen` at `/dashboard/user/:userId`), from which the user can write a message or place a call via the existing "Message" / "Call" buttons.

The current user's own row in the list is rendered with a localized `(You)` / `(Вы)` suffix and is not tappable.

## Motivation

Today, after a call, to message a participant you have to leave the call details screen, find the person in Contacts or Messenger, and tap them there. This adds friction to a very common follow-up action. The Call Details screen already has all the participant data; a one-tap shortcut to their profile (and from there to chat/call) is the natural UX.

## Architecture

A single point of change: [lib/features/call_history/presentation/screens/call_history_screen.dart](lib/features/call_history/presentation/screens/call_history_screen.dart).

No changes to:
- Backend or API
- Routes or `app_router.dart` (target route `/dashboard/user/:userId` already exists)
- Domain entities, repositories, or BLoC
- `UserProfileScreen` itself — it already renders all peer states (contact, blocked, pending request, not-a-contact) and exposes the "Message" / "Call" actions

## Components

### `_ParticipantTile` (new private widget, same file)

Stateless widget extracted from the existing inline `participants.map((p) { return Padding(Row(...)) })` block at [call_history_screen.dart:1682-1734](lib/features/call_history/presentation/screens/call_history_screen.dart#L1682-L1734).

Constructor:

```dart
const _ParticipantTile({
  required Map<String, dynamic> data,
  required String? currentUserId,
  required AppColors colors,
  required String youSuffix,
});
```

Behavior:

- Parses `displayName`, `userId` from `data` (string fields, may be missing).
- Renders the existing rainbow-ring avatar (the IIFE at lines 1690-1725) and the name `Text`.
- Decision tree:
  - If `data['userId'] == null` → render static `Padding(Row(...))`, no tap.
  - Else if `data['userId'] == currentUserId` → render static `Padding(Row(...))` with name as `"$displayName $youSuffix"`, no tap.
  - Else → wrap the same `Padding(Row(...))` in `InkWell(onTap: () => context.push('/dashboard/user/${data['userId']}'))`. No chevron, no color change — just the default ripple (per design decision c1).

### `_CallDetailScreenState` changes

- Add field `String? _currentUserId`.
- In `initState`, read it from `AuthBloc`:
  ```dart
  final authState = context.read<AuthBloc>().state;
  _currentUserId = authState is Authenticated ? authState.user.id : null;
  ```
  (Exact `AuthBloc` state class name to be confirmed during implementation; if `AuthBloc` is not provided in this route's widget tree, fall back to `getIt<SecureStorageService>().getUserId()` in an async init and call `setState(() => _currentUserId = ...)` after resolution. Until resolution, all tiles are tappable — acceptable transient state.)
- Replace the inline `participants.map((p) { return Padding(Row(...)) })` with:
  ```dart
  participants.map((p) => _ParticipantTile(
    data: p,
    currentUserId: _currentUserId,
    colors: colors,
    youSuffix: l10n.callDetailYouSuffix,
  )).toList()
  ```

### Localization

New ARB key `callDetailYouSuffix`:

- `lib/l10n/app_ru.arb`: `"callDetailYouSuffix": "(Вы)"`
- `lib/l10n/app_en.arb`: `"callDetailYouSuffix": "(You)"`
- Description in metadata block: "Suffix appended to the current user's name in the call details participants list."

`AppLocalizations` is regenerated via `flutter gen-l10n` (auto-runs on next build).

## Data Flow

```
CallDetailScreen.build
  ├─ participants: List<Map<String, dynamic>> from _data['participants']
  ├─ _currentUserId: String? from AuthBloc (or SecureStorage fallback)
  └─ AppCard → Column → [_ParticipantTile, ...]
       └─ tap (only if userId != null && userId != currentUserId)
            → context.push('/dashboard/user/${userId}')
                 └─ existing UserProfileScreen
                      ├─ "Message" button → opens or creates DIRECT conversation
                      └─ "Call" button → initiates LiveKit call
```

## Edge Cases

- **`userId` missing in `data`** — render static (non-tappable) tile. Defensive: avoids navigating to `/dashboard/user/null`.
- **`currentUserId == null`** (AuthBloc not yet hydrated, or fallback failed) — every tile is tappable, no `(You)` suffix shown. Tapping one's own row in this case opens `UserProfileScreen` viewing self-as-other, which is a valid (if slightly odd) state — `UserProfileScreen` handles "not a contact" / "this is you" via existing logic.
- **Blocked / removed peer** — `UserProfileScreen` already handles these states (shows "You are blocked" / "Add to Contacts" / etc.). No new logic needed in the call details screen.
- **AI-twin participant** — if a future AI-twin agent appears in `participants` with a non-user identity (e.g., `agent-xyz`), the navigation will hit the user route. Out of scope: AI-twin agents are not currently included in `participants` in the call-history API response. If that changes, a follow-up will filter them.

## Testing

### 1. Unit test (new file: `test/features/call_history/participant_tile_test.dart`)

Cases:
- `userId != currentUserId` → finds `InkWell` ancestor, tap triggers expected route push (use `goRouter` mock or `MockGoRouter`).
- `userId == currentUserId` → no `InkWell`, displayed text contains the `youSuffix` value.
- `userId` missing → no `InkWell`, displayed text equals `displayName`.
- `displayName` missing → falls back to localized "Unknown" (existing behavior preserved).

### 2. Integration test (extend `integration_test/app_test.dart`)

Add a step: navigate to Call History → tap any past call → in details, tap a non-self participant → assert `UserProfileScreen` is shown (find by widget type or unique key on the screen). The existing test already covers Call History opening, so this is a small additive step.

### 3. Manual smoke

- Run dev flavor on emulator: `flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol`
- Open Call History → any call with multiple participants → tap each participant → verify profile opens for non-self, no navigation for self, "(Вы)" / "(You)" suffix on self row.
- Verify both languages by switching device locale.

## Branch & Commit

- Branch: `dev` (per project rule — never commit to `main`)
- One commit, message: `feat(call-history): tap participant in call details opens user profile`

## Out of Scope

- Visual chevron / color tint on tappable rows (decided c1 — default ripple only)
- Bottom sheet with action menu on participant tap (decided against in favor of profile-first flow B)
- Filtering AI-twin or bot participants from the list
- Changes to `UserProfileScreen` itself
- Any backend or API changes

## References

- Existing peer profile route: [app_router.dart](lib/core/router/app_router.dart) — `/dashboard/user/:userId` builds `UserProfileScreen`
- Existing peer profile screen: [user_profile_screen.dart](lib/features/messenger/presentation/screens/user_profile_screen.dart)
- Current participants render: [call_history_screen.dart:1673-1737](lib/features/call_history/presentation/screens/call_history_screen.dart#L1673-L1737)
- Existing tap-on-contact navigation pattern: [contacts_screen.dart:354](lib/features/contacts/presentation/screens/contacts_screen.dart#L354)
