import AppKit
import GridSpacesCore
import SwiftUI

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    private let viewModel = GridViewModel()
    private let overlayProcessController = OverlayProcessController()
    private var panel: NSPanel?
    private var keyMonitor: Any?
    private var openRequestID: UInt = 0

    override init() {
        super.init()
        viewModel.onRequestClose = { [weak self] in self?.close() }
    }

    var isOpen: Bool { panel?.isVisible == true }

    func startOverlayHelper() {
        overlayProcessController.start()
    }

    func shutdown() {
        overlayProcessController.shutdown()
    }

    func open() {
        ensurePanel()
        overlayProcessController.send(.show)

        openRequestID &+= 1
        let requestID = openRequestID
        viewModel.refresh { [weak self] in
            guard let self, self.openRequestID == requestID else { return }
            self.positionPanelAtPointer()
            self.panel?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            self.installKeyMonitor()
        }
    }

    func close() {
        openRequestID &+= 1
        panel?.orderOut(nil)
        overlayProcessController.send(.hide)
        removeKeyMonitor()
    }

    func toggle() {
        isOpen ? close() : open()
    }

    func reloadConfiguration() {
        viewModel.reloadConfiguration()
        overlayProcessController.send(.reload)
        if isOpen {
            viewModel.refresh()
        }
    }

    func openConfig() {
        let url: URL
        do {
            url = try ConfigFilePreparer.prepare()
        } catch {
            presentError(
                "Could not prepare GridSpaces config at \(ConfigLoader.defaultURL.path): \(error.localizedDescription)"
            )
            return
        }

        guard NSWorkspace.shared.open(url) else {
            presentError(
                "Could not open GridSpaces config at \(url.path) with its default application."
            )
            return
        }
    }

    func windowWillClose(_ notification: Notification) {
        overlayProcessController.send(.hide)
        removeKeyMonitor()
    }

    func windowDidResignKey(_ notification: Notification) {
        close()
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isOpen, self.panel?.isKeyWindow == true else { return event }
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

    private func ensurePanel() {
        guard panel == nil else { return }

        let hostingController = NSHostingController(
            rootView: GridView(
                viewModel: viewModel,
                onOpenConfig: { [weak self] in self?.openConfig() }
            )
        )
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

    private func presentError(_ message: String) {
        viewModel.reportError(message)
        guard !isOpen else { return }

        openRequestID &+= 1
        ensurePanel()
        positionPanelAtPointer()
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()
    }

    private func positionPanelAtPointer() {
        guard let panel else { return }

        let screens = NSScreen.screens
        let mainScreenIndex = NSScreen.main.flatMap { mainScreen in
            screens.firstIndex(where: { $0 === mainScreen })
        }
        guard let targetIndex = PopupPlacement.targetScreenIndex(
            pointerLocation: NSEvent.mouseLocation,
            screenFrames: screens.map(\.frame),
            mainScreenIndex: mainScreenIndex
        ) else {
            return
        }

        let origin = PopupPlacement.centeredOrigin(
            windowSize: panel.frame.size,
            visibleFrame: screens[targetIndex].visibleFrame
        )
        panel.setFrameOrigin(origin)
    }

    private func handle(_ event: NSEvent) {
        if PopupShortcut.shouldOpenConfig(
            isPopupVisible: isOpen,
            isPopupKey: panel?.isKeyWindow == true,
            charactersIgnoringModifiers: event.charactersIgnoringModifiers,
            modifiers: popupModifiers(event.modifierFlags)
        ) {
            openConfig()
            return
        }

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
        return viewModel.config.keys.workspaces[token]
    }

    private func popupModifiers(_ flags: NSEvent.ModifierFlags) -> PopupModifier {
        var modifiers: PopupModifier = []
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.function) { modifiers.insert(.function) }
        return modifiers
    }

    private func keyToken(_ event: NSEvent) -> String {
        if event.keyCode == 36 || event.keyCode == 76 { return "return" }
        if event.keyCode == 53 { return "escape" }
        let key = (event.charactersIgnoringModifiers ?? "").lowercased()
        let flags = event.modifierFlags
        var parts: [String] = []
        if flags.contains(.command) { parts.append("cmd") }
        if flags.contains(.option) { parts.append("alt") }
        if flags.contains(.control) { parts.append("ctrl") }
        if flags.contains(.shift) { parts.append("shift") }
        parts.append(key)
        return parts.joined(separator: "-")
    }
}
