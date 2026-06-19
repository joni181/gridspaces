import AppKit
import GridSpacesCore
import SwiftUI

@main
struct GridSpacesAgentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panelController = PanelController()
    private var statusItem: NSStatusItem?
    private var notificationToken: NSObjectProtocol?
    private var ipcReceiver: AgentIPCReceiver?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installStatusItem()
        ipcReceiver = AgentIPCReceiver { [weak self] command in
            self?.handle(command)
        }
        notificationToken = DistributedNotificationCenter.default().addObserver(
            forName: GridSpacesIPC.notificationName,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let value = notification.object as? String,
                let command = AgentCommand(rawValue: value)
            else { return }
            Task { @MainActor in self?.handle(command) }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let notificationToken {
            DistributedNotificationCenter.default().removeObserver(notificationToken)
        }
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "square.grid.3x3",
            accessibilityDescription: "GridSpaces"
        )
        let menu = NSMenu()
        menu.addItem(withTitle: "Open GridSpaces", action: #selector(openGrid), keyEquivalent: "")
        menu.addItem(withTitle: "Reload Configuration", action: #selector(reloadConfig), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit GridSpaces", action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    private func handle(_ command: AgentCommand) {
        switch command {
        case .open: panelController.open()
        case .close: panelController.close()
        case .toggle: panelController.toggle()
        case .reloadConfig: panelController.reloadConfiguration()
        }
    }

    @objc private func openGrid() {
        panelController.open()
    }

    @objc private func reloadConfig() {
        panelController.reloadConfiguration()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
