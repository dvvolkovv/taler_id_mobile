import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import AVFoundation

/// ShareViewController compatible with receive_sharing_intent package format.
/// Saves shared files to App Group container and redirects to host app via URL scheme.
/// Uses UIViewController (not SLComposeServiceViewController) for instant redirect.
class ShareViewController: UIViewController {

    private let appGroupId = "group.tirol.taler.talerIdMobile"
    private let kUserDefaultsKey = "ShareKey"
    private let kUserDefaultsMessageKey = "ShareMessageKey"
    private var sharedMedia: [SharedMediaItem] = []

    private let spinner = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        spinner.startAnimating()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let content = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = content.attachments else {
            close()
            return
        }

        let group = DispatchGroup()

        for (index, attachment) in attachments.enumerated() {
            group.enter()
            processAttachment(attachment, index: index) {
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.saveAndRedirect(message: nil)
        }
    }

    // MARK: - Process attachments

    private func processAttachment(_ attachment: NSItemProvider, index: Int, completion: @escaping () -> Void) {
        if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                self?.handleImageItem(data, completion: completion)
            }
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.movie.identifier) { [weak self] data, _ in
                self?.handleFileItem(data, type: .video, completion: completion)
            }
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { [weak self] data, _ in
                self?.handleFileItem(data, type: .file, completion: completion)
            }
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] data, _ in
                if let url = data as? URL {
                    self?.sharedMedia.append(SharedMediaItem(path: url.absoluteString, type: .url))
                }
                completion()
            }
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.text.identifier) { [weak self] data, _ in
                if let text = data as? String {
                    self?.sharedMedia.append(SharedMediaItem(path: text, mimeType: "text/plain", type: .text))
                }
                completion()
            }
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.data.identifier) { [weak self] data, _ in
                self?.handleFileItem(data, type: .file, completion: completion)
            }
        } else {
            completion()
        }
    }

    private func handleImageItem(_ data: Any?, completion: @escaping () -> Void) {
        if let url = data as? URL {
            if let newPath = copyToContainer(url: url) {
                let decoded = newPath.absoluteString.removingPercentEncoding ?? newPath.absoluteString
                sharedMedia.append(SharedMediaItem(path: decoded, mimeType: mimeType(for: url), type: .image))
            }
            completion()
        } else if let image = data as? UIImage {
            if let pngData = image.pngData() {
                let fileName = UUID().uuidString + ".png"
                if let savedPath = saveToContainer(data: pngData, fileName: fileName) {
                    let decoded = savedPath.absoluteString.removingPercentEncoding ?? savedPath.absoluteString
                    sharedMedia.append(SharedMediaItem(path: decoded, mimeType: "image/png", type: .image))
                }
            }
            completion()
        } else {
            completion()
        }
    }

    private func handleFileItem(_ data: Any?, type: SharedMediaType, completion: @escaping () -> Void) {
        guard let url = data as? URL else {
            completion()
            return
        }

        guard let newPath = copyToContainer(url: url) else {
            completion()
            return
        }

        let decoded = newPath.absoluteString.removingPercentEncoding ?? newPath.absoluteString

        if type == .video {
            let asset = AVAsset(url: url)
            let duration = CMTimeGetSeconds(asset.duration) * 1000
            let thumbnailPath = generateVideoThumbnail(from: url)
            sharedMedia.append(SharedMediaItem(
                path: decoded,
                mimeType: mimeType(for: url),
                thumbnail: thumbnailPath,
                duration: duration,
                type: .video
            ))
        } else {
            sharedMedia.append(SharedMediaItem(path: decoded, mimeType: mimeType(for: url), type: .file))
        }
        completion()
    }

    // MARK: - File operations

    private func containerURL() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    private func copyToContainer(url: URL) -> URL? {
        guard let container = containerURL() else { return nil }
        let dest = container.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: url, to: dest)
            return dest
        } catch {
            print("[ShareExtension] Copy failed: \(error)")
            return nil
        }
    }

    private func saveToContainer(data: Data, fileName: String) -> URL? {
        guard let container = containerURL() else { return nil }
        let dest = container.appendingPathComponent(fileName)
        do {
            try data.write(to: dest)
            return dest
        } catch {
            print("[ShareExtension] Save failed: \(error)")
            return nil
        }
    }

    private func generateVideoThumbnail(from url: URL) -> String? {
        guard let container = containerURL() else { return nil }
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 360, height: 360)

        let thumbName = Data(url.lastPathComponent.utf8).base64EncodedString()
            .replacingOccurrences(of: "==", with: "") + ".jpg"
        let thumbPath = container.appendingPathComponent(thumbName)

        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            try UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.7)?.write(to: thumbPath)
            return thumbPath.absoluteString.removingPercentEncoding
        } catch {
            return nil
        }
    }

    private func mimeType(for url: URL) -> String {
        if let utType = UTType(filenameExtension: url.pathExtension),
           let mime = utType.preferredMIMEType {
            return mime
        }
        return "application/octet-stream"
    }

    // MARK: - Save and redirect

    private func saveAndRedirect(message: String? = nil) {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        let encoded = try? JSONEncoder().encode(sharedMedia)
        userDefaults?.set(encoded, forKey: kUserDefaultsKey)
        userDefaults?.set(message, forKey: kUserDefaultsMessageKey)
        userDefaults?.synchronize()

        redirectToHostApp()
    }

    private func redirectToHostApp() {
        let extBundleId = Bundle.main.bundleIdentifier ?? ""
        let hostBundleId: String
        if let lastDot = extBundleId.lastIndex(of: ".") {
            hostBundleId = String(extBundleId[..<lastDot])
        } else {
            hostBundleId = extBundleId
        }

        let urlString = "ShareMedia-\(hostBundleId):share"
        guard let url = URL(string: urlString) else {
            close()
            return
        }

        // Method 1: responder chain (works on most iOS versions)
        var found = false
        var responder: UIResponder? = self
        while responder != nil {
            if let app = responder as? UIApplication {
                app.open(url, options: [:]) { _ in }
                found = true
                break
            }
            responder = responder?.next
        }

        // Method 2: performSelector on shared UIApplication (fallback)
        if !found {
            let selector = NSSelectorFromString("openURL:")
            responder = self
            while responder != nil {
                if responder!.responds(to: selector) {
                    responder!.perform(selector, with: url)
                    found = true
                    break
                }
                responder = responder?.next
            }
        }

        // Method 3: NSExtensionContext open URL
        if !found {
            extensionContext?.open(url) { _ in
                self.close()
            }
            return
        }

        // Small delay to let the URL open before closing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.close()
        }
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

// MARK: - Data models (must match receive_sharing_intent format)

enum SharedMediaType: String, Codable, CaseIterable {
    case image
    case video
    case text
    case file
    case url
}

struct SharedMediaItem: Codable {
    var path: String
    var mimeType: String?
    var thumbnail: String?
    var duration: Double?
    var message: String?
    var type: SharedMediaType

    init(path: String, mimeType: String? = nil, thumbnail: String? = nil,
         duration: Double? = nil, message: String? = nil, type: SharedMediaType) {
        self.path = path
        self.mimeType = mimeType
        self.thumbnail = thumbnail
        self.duration = duration
        self.message = message
        self.type = type
    }
}
