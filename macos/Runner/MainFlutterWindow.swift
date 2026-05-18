import Cocoa
import FlutterMacOS
import AVFoundation

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Native AV permission channel — permission_handler 11.x/12.x does not
    // support macOS, so we expose AVCaptureDevice.requestAccess directly.
    let permChannel = FlutterMethodChannel(
      name: "tirol.taler.talerIdMobile/av_permission",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    permChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "requestMicrophone":
        AVCaptureDevice.requestAccess(for: .audio) { granted in
          DispatchQueue.main.async { result(granted) }
        }
      case "requestCamera":
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.async { result(granted) }
        }
      case "checkMicrophone":
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        // 0=notDetermined, 1=restricted, 2=denied, 3=authorized
        result(status.rawValue)
      case "checkCamera":
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        result(status.rawValue)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
