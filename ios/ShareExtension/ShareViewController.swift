import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import AVFoundation

/// ShareViewController compatible with receive_sharing_intent package format.
/// Saves shared files to App Group container and redirects to host app via URL scheme.
class ShareViewController: SLComposeServiceViewController {

    private let appGroupId = "group.tirol.taler.talerIdMobile"
    private let kUserDefaultsKey = "ShareKey"
    private let kUserDefaultsMessageKey = "ShareMessageKey"
    private var sharedMedia: [SharedMediaItem] = []

    override func isContentValid() -> Bool {
        return true
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
            self?.saveAndRedirect(message: self?.contentText)
        }
    }

    override func didSelectPost() {
        saveAndRedirect(message: contentText)
    }

    override func configurationItems() -> [Any]! {
        return []
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
        // Derive host app bundle ID from extension bundle ID
        // e.g. tirol.taler.talerIdMobile.ShareExtension -> tirol.taler.talerIdMobile
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

        var responder: UIResponder? = self
        if #available(iOS 18.0, *) {
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(url, options: [:], completionHandler: nil)
                }
                responder = responder?.next
            }
        } else {
            let selectorOpenURL = sel_registerName("openURL:")
            while responder != nil {
                if (responder?.responds(to: selectorOpenURL)) == true {
                    _ = responder?.perform(selectorOpenURL, with: url)
                }
                responder = responder?.next
            }
        }

        close()
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
