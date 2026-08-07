import AppKit
import GridSpacesCore
import SwiftUI

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    private let viewModel = GridViewModel()
    private var panel: NSPanel?
    private var treePanel: NSPanel?
    private var keyMonitor: Any?
    private var openRequestID: UInt = 0
    private var quickNavigateModifiers: HotkeyModifiers?
    private var quickNavigateGeneration: UInt = 0
    private var isQuickNavigateOpening = false
    private var pendingQuickNavigateSteps: [Direction] = []
    private let quickNavigatePollInterval: TimeInterval = 0.03

    override init() {
        super.init()
        viewModel.onRequestClose = { [weak self] in self?.close() }
    }

    var isOpen: Bool { panel?.isVisible == true }

    func open() {
        open(quickNavigate: nil)
    }

    /// Opens the grid with the highlight already moved one tile in `direction`, and commits
    /// the highlighted workspace as soon as the trigger modifiers are released.
    func quickNavigate(_ direction: Direction) {
        if isQuickNavigateOpening {
            // The grid is still loading; replay the extra step once the highlight exists.
            pendingQuickNavigateSteps.append(direction)
            return
        }
        if isOpen {
            // Navigating away is an unambiguous answer to a close-all prompt: not now.
            viewModel.cancelPendingClose()
            viewModel.navigate(direction)
            armQuickNavigate(direction: direction)
            return
        }
        open(quickNavigate: direction)
    }

    private func open(quickNavigate direction: Direction?) {
        ensurePanel()

        openRequestID &+= 1
        let requestID = openRequestID
        disarmQuickNavigate()
        isQuickNavigateOpening = direction != nil
        viewModel.refresh(quickNavigate: direction) { [weak self] in
            guard let self, self.openRequestID == requestID else { return }
            self.positionPanelAtPointer()
            self.panel?.makeKeyAndOrderFront(nil)
            if self.viewModel.config.appearance.showTreePanel {
                self.ensureTreePanel()
                self.positionTreePanel()
                self.treePanel?.orderFront(nil)
                // Re-center after SwiftUI completes its layout pass.
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.openRequestID == requestID else { return }
                    self.positionTreePanel()
                }
            }
            NSApp.activate(ignoringOtherApps: true)
            self.installKeyMonitor()

            guard let direction else { return }
            self.isQuickNavigateOpening = false
            self.pendingQuickNavigateSteps.forEach(self.viewModel.navigate)
            self.pendingQuickNavigateSteps = []
            self.armQuickNavigate(direction: direction)
        }
    }

    func close() {
        openRequestID &+= 1
        disarmQuickNavigate()
        viewModel.clearWorkspaceMoveMode()
        panel?.orderOut(nil)
        treePanel?.orderOut(nil)
        removeKeyMonitor()
    }

    func toggle() {
        isOpen ? close() : open()
    }

    func reloadConfiguration() {
        viewModel.reloadConfiguration()
        if isOpen {
            if viewModel.config.appearance.showTreePanel {
                ensureTreePanel()
                positionTreePanel()
                treePanel?.orderFront(nil)
            } else {
                treePanel?.orderOut(nil)
            }
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
        removeKeyMonitor()
    }

    func windowDidResignKey(_ notification: Notification) {
        viewModel.clearWorkspaceMoveMode()
        close()
    }

    /// Starts watching for release of the modifiers of the quick-navigate hotkey that was
    /// pressed. A hotkey without modifiers cannot be released, so the grid simply stays open.
    private func armQuickNavigate(direction: Direction) {
        guard let modifiers = viewModel.config.keys.quickNavigateModifiers(for: direction) else {
            disarmQuickNavigate()
            return
        }

        quickNavigateModifiers = modifiers
        viewModel.isQuickNavigateActive = true
        quickNavigateGeneration &+= 1
        scheduleQuickNavigatePoll(generation: quickNavigateGeneration)
        // The modifiers may already be gone if the shortcut was tapped rather than held.
        evaluateQuickNavigateRelease()
    }

    private func disarmQuickNavigate() {
        quickNavigateGeneration &+= 1
        quickNavigateModifiers = nil
        isQuickNavigateOpening = false
        pendingQuickNavigateSteps = []
        viewModel.isQuickNavigateActive = false
    }

    /// Polls the hardware modifier state, which stays correct even when the panel never
    /// became key and therefore no `flagsChanged` event reaches the local monitor.
    private func scheduleQuickNavigatePoll(generation: UInt) {
        DispatchQueue.main.asyncAfter(deadline: .now() + quickNavigatePollInterval) { [weak self] in
            guard let self, self.quickNavigateGeneration == generation else { return }
            self.evaluateQuickNavigateRelease()
            guard self.quickNavigateGeneration == generation else { return }
            self.scheduleQuickNavigatePoll(generation: generation)
        }
    }

    private func evaluateQuickNavigateRelease(
        heldModifiers: HotkeyModifiers? = nil
    ) {
        guard let expected = quickNavigateModifiers else { return }
        let held = heldModifiers ?? hotkeyModifiers(NSEvent.modifierFlags)
        guard !held.contains(expected) else { return }
        commitQuickNavigate()
    }

    private func commitQuickNavigate() {
        let canCommit = viewModel.canCommitQuickNavigate
        disarmQuickNavigate()
        // With no destination, or with an error on screen, leave the grid open instead of
        // switching blind; the usual grid keys still apply.
        guard canCommit else { return }
        viewModel.confirmSelection()
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .flagsChanged]
        ) { [weak self] event in
            guard let self, self.isOpen, self.panel?.isKeyWindow == true else { return event }
            if event.type == .flagsChanged {
                let held = self.hotkeyModifiers(event.modifierFlags)
                self.viewModel.updateWorkspaceMoveMode(heldModifiers: held)
                self.evaluateQuickNavigateRelease(heldModifiers: held)
                return event
            }
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

        if viewModel.config.appearance.showTreePanel {
            ensureTreePanel()
        }
    }

    private let treePanelWidth: CGFloat = 280

    private func ensureTreePanel() {
        guard treePanel == nil else { return }

        let hostingController = NSHostingController(
            rootView: WorkspaceTreeView(viewModel: viewModel)
        )
        let initialRect = CGRect(x: 0, y: 0, width: treePanelWidth, height: 400)
        let newPanel = NSPanel(
            contentRect: initialRect,
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
        newPanel.contentViewController = hostingController
        newPanel.backgroundColor = .clear
        newPanel.isOpaque = false
        newPanel.hasShadow = true
        treePanel = newPanel
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

        let visibleFrame = screens[targetIndex].visibleFrame
        let origin = PopupPlacement.centeredOrigin(
            windowSize: panel.frame.size,
            visibleFrame: visibleFrame
        )
        panel.setFrameOrigin(origin)
    }

    private func positionTreePanel() {
        guard let panel, let treePanel else { return }

        let gap: CGFloat = 8
        let mainFrame = panel.frame
        let width = treePanelWidth
        // Use actual SwiftUI-computed height if available; fall back to a reasonable default.
        let height = treePanel.frame.height > 0 ? treePanel.frame.height : 400

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
        let visibleFrame = screens[targetIndex].visibleFrame

        let rightX = mainFrame.maxX + gap
        let leftX = mainFrame.minX - width - gap

        let x: CGFloat
        if rightX + width <= visibleFrame.maxX {
            x = rightX
        } else if leftX >= visibleFrame.minX {
            x = leftX
        } else {
            x = mainFrame.midX - width / 2
        }

        // Vertically center on the main panel, clamped within the screen.
        let centeredY = mainFrame.midY - height / 2
        let y = max(visibleFrame.minY, min(centeredY, visibleFrame.maxY - height))

        treePanel.setFrame(CGRect(x: x, y: y, width: width, height: height), display: true)
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

        if viewModel.isQuickNavigateActive,
           let direction = quickNavigateDirection(event: event) {
            viewModel.navigate(direction)
            return
        }

        if let direction = workspaceMoveDirection(token: token) {
            viewModel.moveWorkspaceContents(direction)
            return
        }
        if let direction = displayMoveDirection(token: token, event: event) {
            viewModel.moveToDisplay(direction)
            return
        }
        if let direction = navigationDirection(token: token, event: event) {
            viewModel.navigate(direction)
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
        let modifiers = hotkeyModifiers(event.modifierFlags)
        guard modifiers.isEmpty else { return nil }
        if token == viewModel.config.keys.left || event.keyCode == 123 { return .left }
        if token == viewModel.config.keys.down || event.keyCode == 125 { return .down }
        if token == viewModel.config.keys.up || event.keyCode == 126 { return .up }
        if token == viewModel.config.keys.right || event.keyCode == 124 { return .right }
        return nil
    }

    /// While the quick-navigate modifiers stay held, the quick-navigate hotkeys and the plain
    /// navigation keys (or arrows) pressed with those modifiers keep moving the highlight.
    private func quickNavigateDirection(event: NSEvent) -> Direction? {
        guard
            let expected = quickNavigateModifiers,
            hotkeyModifiers(event.modifierFlags) == expected
        else {
            return nil
        }

        let keys = viewModel.config.keys
        let key = (event.charactersIgnoringModifiers ?? "").lowercased()
        if let direction = keys.quickNavigateDirection(modifiers: expected, key: key) {
            return direction
        }
        if key == keys.left || event.keyCode == 123 { return .left }
        if key == keys.down || event.keyCode == 125 { return .down }
        if key == keys.up || event.keyCode == 126 { return .up }
        if key == keys.right || event.keyCode == 124 { return .right }
        return nil
    }

    private func workspaceMoveDirection(token: String) -> Direction? {
        if token == viewModel.config.keys.moveWorkspaceLeft { return .left }
        if token == viewModel.config.keys.moveWorkspaceDown { return .down }
        if token == viewModel.config.keys.moveWorkspaceUp { return .up }
        if token == viewModel.config.keys.moveWorkspaceRight { return .right }
        return nil
    }

    private func displayMoveDirection(token: String, event: NSEvent) -> Direction? {
        if viewModel.config.behavior.moveMode == .cycle {
            if token == viewModel.config.keys.moveToDisplayPrevious { return .left }
            if token == viewModel.config.keys.moveToDisplayNext { return .right }
        }
        if token == viewModel.config.keys.moveToDisplayLeft || (event.keyCode == 123 && event.modifierFlags.contains(.shift)) { return .left }
        if token == viewModel.config.keys.moveToDisplayDown || (event.keyCode == 125 && event.modifierFlags.contains(.shift)) { return .down }
        if token == viewModel.config.keys.moveToDisplayUp || (event.keyCode == 126 && event.modifierFlags.contains(.shift)) { return .up }
        if token == viewModel.config.keys.moveToDisplayRight || (event.keyCode == 124 && event.modifierFlags.contains(.shift)) { return .right }
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

    private func hotkeyModifiers(_ flags: NSEvent.ModifierFlags) -> HotkeyModifiers {
        var modifiers: HotkeyModifiers = []
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
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
