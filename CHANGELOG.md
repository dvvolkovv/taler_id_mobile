# Changelog

## 1.0.74+168 — 2026-05-18 — Desktop hotfix: SecureStorage path

**Critical fix** for 1.0.74+167 — the production desktop app crashed on startup with `PathAccessException: Cannot open file /Users/<user>/Documents/secure_box_v2.hive (errno=1)` because `Hive.initFlutter()` resolves to `~/Documents/` on macOS, which is blocked by File Access Privacy / TCC. Switched to `getApplicationSupportDirectory()` which returns `~/Library/Application Support/<bundle>/` on macOS, `~/.local/share/<binary>/` on Linux, `%APPDATA%\<binary>\` on Windows — all sandbox- and TCC-safe without extra entitlements.

## 1.0.74+167 — 2026-05-18 — Desktop First Release

First end-user desktop release of Taler ID. Available on macOS, Windows, and Linux.

### Desktop platform features (Project 1 Phase 1 + 2 + Project 2 Phase 2A)

- **Cross-platform support**: macOS (DMG, signed by GsmSoft GmbH + notarized), Windows (ZIP), Linux (tar.gz)
- **Modern desktop shell**: Discord-style left activity bar with 5 sections (Messenger, Calls, Assistant, Calendar, Settings); hybrid title bar (macOS keeps native traffic-lights, Win/Linux gets custom controls)
- **Window state persistence**: app remembers size, position, maximized state between launches
- **Theme toggle**: Dark / Light / System (Settings → Внешний вид)
- **Tray icon + hide-to-tray**: close button hides app to tray; tray menu has "Открыть Taler ID" + "Выйти"; unread badge swaps tray icon
- **Native OS notifications**: new message + incoming call toasts via `flutter_local_notifications` (macOS + Linux; Windows is a no-op due to current package limitation)
- **Custom `talerid://` URL scheme**: deep-link sharing for chats (`talerid://chat/<id>`), profiles, calendar, assistant, OAuth callback
- **KYC verification**: embedded Sumsub Web SDK on macOS / Linux (Windows shows "use mobile" message — `webview_windows` integration coming later)
- **OAuth desktop client support**: RFC 8252 loopback HTTP server for OAuth flows (infrastructure ready; UI button to initiate flow ships in a follow-up release)
- **Keyboard shortcuts**: Cmd/Ctrl+1..5 (switch sections), Cmd/Ctrl+, (Settings), Esc (close modal)
- **Responsive layout**: window minimum 800px width; layout adapts to wider monitors (chat list at 1100px, info panel at 1300px)

### Mobile parity

- All mesh networking features (Bluetooth/Wi-Fi Direct/Bonjour), CallKit, VoIP push, Sumsub Mobile SDK, FCM, biometric auth remain mobile-only (gated by platform).
- Mobile iOS / Android users are unaffected — no regressions.

### Backend changes (deployed to PROD 2026-05-16)

- `POST /kyc/start?platform=desktop` returns Sumsub Web SDK URL for embedded WebView
- `OAuthClient.isDesktopClient` field added (Prisma migration) — desktop OAuth clients may use `http://127.0.0.1:<any port>/cb` redirect URIs per RFC 8252

### Known limitations

- **Windows notifications**: no-op (`flutter_local_notifications` 18.x has no Windows backend yet)
- **Windows KYC**: stub message (real `webview_windows` integration deferred)
- **Linux URL scheme**: requires manual `xdg-mime default taler_id_mobile.desktop x-scheme-handler/talerid` once per user
- **Desktop OAuth UI**: no active "Connect via Taler ID" button yet (infrastructure ready, awaits use-case)
- **Auto-updater**: not yet — manually download new DMG/ZIP/tar.gz for updates
