import AppKit
import GridSpacesCore
import SwiftUI

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    private let viewModel = GridViewModel()
    private var panel: NSPanel?
    private var keyMonitor: Any?
    private var openRequestID: UInt = 0

    override init() {
        super.init()
        viewModel.onRequestClose = { [weak self] in self?.close() }
    }

    var isOpen: Bool { panel?.isVisible == true }

    func open() {
        if panel == nil {
            let hostingController = NSHostingController(rootView: GridView(viewModel: viewModel))
            let newPanel = NSPanel(
                contentRect: .zero,
                styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.titleVisibility = .hidden
            newPanel.titlebarAppearsTransparent = true
            newPanel.isMovableByWindowBackground = true
            newPanel.level = .floating
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            newPanel.isReleasedWhenClosed = false
            newPanel.delegate = self
            newPanel.contentViewController = hostingController
            newPanel.backgroundColor = .clear
            newPanel.isOpaque = false
            newPanel.hasShadow = true
            panel = newPanel
        }

        openRequestID &+= 1
        let requestID = openRequestID
        viewModel.refresh { [weak self] in
            guard let self, self.openRequestID == requestID else { return }
            self.panel?.center()
            self.panel?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            self.installKeyMonitor()
        }
    }

    func close() {
        openRequestID &+= 1
        panel?.orderOut(nil)
        removeKeyMonitor()
    }

    func toggle() {
        isOpen ? close() : open()
    }

    func reloadConfiguration() {
        viewModel.reloadConfiguration()
        if isOpen {
            viewModel.refresh()
        }
    }

    func windowWillClose(_ notification: Notification) {
        removeKeyMonitor()
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isOpen else { return event }
            self.handle(event)
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func handle(_ event: NSEvent) {
        let token = keyToken(event)

        if viewModel.pendingCloseWorkspace != nil {
            if token == viewModel.config.keys.confirm || event.keyCode == 36 || event.keyCode == 76 {
                viewModel.confirmSelection()
            } else {
                viewModel.cancelPendingClose()
            }
            return
        }

        if let direction = navigationDirection(token: token, event: event) {
            viewModel.navigate(direction)
            return
        }
        if let direction = moveDirection(token: token, event: event) {
            viewModel.moveWorkspace(direction)
            return
        }

        switch token {
        case viewModel.config.keys.confirm:
            viewModel.confirmSelection()
            return
        case viewModel.config.keys.cancel:
            viewModel.cancel()
            return
        case viewModel.config.keys.closeAll:
            viewModel.requestCloseAll()
            return
        default:
            if event.keyCode == 36 || event.keyCode == 76 {
                viewModel.confirmSelection()
                return
            } else if event.keyCode == 53 {
                viewModel.cancel()
                return
            }
        }

        if let workspace = directWorkspace(token: token, event: event) {
            viewModel.switchDirectly(to: workspace)
        }
    }

    private func navigationDirection(token: String, event: NSEvent) -> Direction? {
        guard !event.modifierFlags.contains(.shift) else { return nil }
        if token == viewModel.config.keys.left || event.keyCode == 123 { return .left }
        if token == viewModel.config.keys.down || event.keyCode == 125 { return .down }
        if token == viewModel.config.keys.up || event.keyCode == 126 { return .up }
        if token == viewModel.config.keys.right || event.keyCode == 124 { return .right }
        return nil
    }

    private func moveDirection(token: String, event: NSEvent) -> Direction? {
        if viewModel.config.behavior.moveMode == .cycle {
            if token == viewModel.config.keys.movePrevious { return .left }
            if token == viewModel.config.keys.moveNext { return .right }
        }
        if token == viewModel.config.keys.moveLeft || (event.keyCode == 123 && event.modifierFlags.contains(.shift)) { return .left }
        if token == viewModel.config.keys.moveDown || (event.keyCode == 125 && event.modifierFlags.contains(.shift)) { return .down }
        if token == viewModel.config.keys.moveUp || (event.keyCode == 126 && event.modifierFlags.contains(.shift)) { return .up }
        if token == viewModel.config.keys.moveRight || (event.keyCode == 124 && event.modifierFlags.contains(.shift)) { return .right }
        return nil
    }

    private func directWorkspace(token: String, event: NSEvent) -> String? {
        let disallowedModifiers: NSEvent.ModifierFlags = [
            .command, .control, .option, .shift, .function,
        ]
        guard event.modifierFlags.intersection(disallowedModifiers).isEmpty else {
            return nil
        }
        return viewModel.config.keys.workspaces[token]
    }

    private func keyToken(_ event: NSEvent) -> String {
        if event.keyCode == 36 || event.keyCode == 76 { return "return" }
        if event.keyCode == 53 { return "escape" }
        let value = (event.charactersIgnoringModifiers ?? "").lowercased()
        return event.modifierFlags.contains(.shift) ? "shift+\(value)" : value
    }
}
