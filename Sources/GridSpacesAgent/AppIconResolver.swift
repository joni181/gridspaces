import AppKit

@MainActor
final class AppIconResolver {
    private var cache: [String: NSImage] = [:]

    func icon(for applicationName: String) -> NSImage {
        if let cached = cache[applicationName] {
            return cached
        }

        let runningMatch = NSWorkspace.shared.runningApplications.first {
            $0.localizedName?.localizedCaseInsensitiveCompare(applicationName) == .orderedSame
        }
        let icon: NSImage
        if let bundleURL = runningMatch?.bundleURL {
            icon = NSWorkspace.shared.icon(forFile: bundleURL.path)
        } else {
            icon = NSImage(systemSymbolName: "app.fill", accessibilityDescription: applicationName)
                ?? NSImage(size: NSSize(width: 32, height: 32))
        }
        cache[applicationName] = icon
        return icon
    }
}
