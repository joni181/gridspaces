import AppKit
import GridSpacesCore
import GridSpacesOverlayKit

@MainActor
final class OverlayAppDelegate: NSObject, NSApplicationDelegate {
    private let service = ScreenOverlayService()
    private var receiver: OverlayIPCReceiver?
    private var notificationToken: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        receiver = OverlayIPCReceiver { [weak self] command in
            self?.handle(command)
        }
        guard receiver?.isListening == true else {
            NSApp.terminate(nil)
            return
        }
        notificationToken = DistributedNotificationCenter.default().addObserver(
            forName: GridSpacesOverlayIPC.notificationName,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let value = notification.object as? String,
                let command = OverlayCommand(rawValue: value)
            else { return }
            Task { @MainActor in self?.handle(command) }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        service.shutdown()
        if let notificationToken {
            DistributedNotificationCenter.default().removeObserver(notificationToken)
        }
    }

    private func handle(_ command: OverlayCommand) {
        switch command {
        case .ping:
            break
        case .show:
            service.show()
        case .hide:
            service.hide()
        case .reload:
            service.reload()
        case .shutdown:
            service.shutdown()
            NSApp.terminate(nil)
        }
    }
}

let application = NSApplication.shared
MainActor.assumeIsolated {
    let delegate = OverlayAppDelegate()
    application.delegate = delegate
    withExtendedLifetime(delegate) {
        application.run()
    }
}
