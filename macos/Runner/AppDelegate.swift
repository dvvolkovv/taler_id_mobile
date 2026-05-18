import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // Do NOT terminate when the last window closes — we hide-to-tray on close
  // and the tray icon stays alive. Returning false keeps the process around
  // so the tray menu's "Открыть Taler ID" can show the window again.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  // Disable Apple's automatic window state restoration. WindowStatePersistence
  // (Hive-backed) handles size + position itself. Apple's restoration was also
  // restoring the "hidden" state (when the user previously closed-to-tray),
  // which fought with our explicit windowManager.show() and produced a
  // confusing "menu bar shows the app but no window visible" symptom on
  // re-launch.
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return false
  }
}
