import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    private var sharedItems: [NSExtensionItem] = []

    override func isContentValid() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Redirect to the host app immediately
        handleSharedItems()
    }

    private func handleSharedItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeRequest()
            return
        }

        let group = DispatchGroup()
        var urls: [URL] = []

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                group.enter()
                handleProvider(provider) { url in
                    if let url = url {
                        urls.append(url)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            if !urls.isEmpty {
                self.saveAndRedirect(urls: urls)
            } else {
                self.completeRequest()
            }
        }
    }

    private func handleProvider(_ provider: NSItemProvider, completion: @escaping (URL?) -> Void) {
        let types: [UTType] = [.image, .movie, .data, .fileURL]

        for type in types {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                    if let url = item as? URL {
                        // Copy to shared container
                        let sharedURL = self.copyToSharedContainer(url: url)
                        completion(sharedURL)
                    } else if let data = item as? Data {
                        let sharedURL = self.saveDataToSharedContainer(data: data, ext: "dat")
                        completion(sharedURL)
                    } else if let image = item as? UIImage {
                        if let data = image.jpegData(compressionQuality: 0.9) {
                            let sharedURL = self.saveDataToSharedContainer(data: data, ext: "jpg")
                            completion(sharedURL)
                        } else {
                            completion(nil)
                        }
                    } else {
                        completion(nil)
                    }
                }
                return
            }
        }
        completion(nil)
    }

    private func copyToSharedContainer(url: URL) -> URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.tirol.taler.talerIdMobile"
        ) else { return nil }

        let shareDir = containerURL.appendingPathComponent("share", isDirectory: true)
        try? FileManager.default.createDirectory(at: shareDir, withIntermediateDirectories: true)

        let dest = shareDir.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: url, to: dest)
        return dest
    }

    private func saveDataToSharedContainer(data: Data, ext: String) -> URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.tirol.taler.talerIdMobile"
        ) else { return nil }

        let shareDir = containerURL.appendingPathComponent("share", isDirectory: true)
        try? FileManager.default.createDirectory(at: shareDir, withIntermediateDirectories: true)

        let fileName = UUID().uuidString + "." + ext
        let dest = shareDir.appendingPathComponent(fileName)
        try? data.write(to: dest)
        return dest
    }

    private func saveAndRedirect(urls: [URL]) {
        let userDefaults = UserDefaults(suiteName: "group.tirol.taler.talerIdMobile")
        let paths = urls.map { $0.absoluteString }
        userDefaults?.set(paths, forKey: "SharedFiles")
        userDefaults?.synchronize()

        // Open the main app
        let urlString = "talerid://share"
        guard let url = URL(string: urlString) else {
            completeRequest()
            return
        }

        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                break
            }
            responder = responder?.next
        }

        completeRequest()
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    override func didSelectPost() {
        completeRequest()
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}
