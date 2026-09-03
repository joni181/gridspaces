import AppKit
import GridSpacesCore
import SwiftUI

@MainActor
final class GridViewModel: ObservableObject {
    @Published var model = GridModel(config: .defaults, states: [])
    @Published var highlightedWorkspace: String?
    @Published var focusedWorkspace: String?
    @Published var monitors: [MonitorInfo] = []
    @Published var screenDescriptors: [MonitorScreenDescriptor] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingCloseWorkspace: String?
    @Published var isReorderingWorkspace = false
    @Published var isWorkspaceMoveModeActive = false
    @Published var isQuickNavigateActive = false

    @Published private(set) var config = GridSpacesConfig.defaults
    let iconResolver = AppIconResolver()
    var onRequestClose: (() -> Void)?
    private var refreshID: UInt = 0
    private let exchangeWorkspaceContents: @Sendable (String, String) throws -> Void

    init(
        config: GridSpacesConfig = .defaults,
        exchangeWorkspaceContents: @escaping @Sendable (String, String) throws -> Void = { source, destination in
            try AeroSpaceClient().exchangeWorkspaceContents(
                source: source,
                destination: destination
            )
        }
    ) {
        self.config = config
        self.exchangeWorkspaceContents = exchangeWorkspaceContents
        model = GridModel(config: config, states: [])
    }

    func reloadConfiguration() {
        let loaded = ConfigLoader.load()
        config = loaded.config
        if !loaded.warnings.isEmpty {
            errorMessage = loaded.warnings.joined(separator: "\n")
        }
    }

    func refresh(
        preferredHighlightedWorkspace: String? = nil,
        quickNavigate: Direction? = nil,
        onFocusedWorkspaceReady: (() -> Void)? = nil,
        onRefreshComplete: (() -> Void)? = nil
    ) {
        refreshID &+= 1
        let requestID = refreshID
        reloadConfiguration()
        isLoading = true
        errorMessage = nil
        if preferredHighlightedWorkspace == nil {
            highlightedWorkspace = nil
        }
        let config = config
        if quickNavigate != nil {
            // The destination is derived from grid geometry before the snapshot arrives, so
            // rebuild the cached model against the freshly loaded configuration first.
            model = GridModel(config: config, states: model.tiles.map(\.workspace))
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let client: AeroSpaceClient
            let focusedWorkspace: String
            do {
                client = try AeroSpaceClient()
                focusedWorkspace = try client.focusedWorkspace()
            } catch {
                DispatchQueue.main.async {
                    guard let self, self.refreshID == requestID else { return }
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    onFocusedWorkspaceReady?()
                    onRefreshComplete?()
                }
                return
            }

            DispatchQueue.main.async {
                guard let self, self.refreshID == requestID else { return }
                self.focusedWorkspace = focusedWorkspace
                if let quickNavigate {
                    self.highlightedWorkspace = Self.quickNavigateDestination(
                        from: focusedWorkspace,
                        direction: quickNavigate,
                        in: self.model,
                        wrap: config.behavior.wrap
                    )
                } else {
                    self.highlightedWorkspace = Self.highlightedWorkspace(
                        preferred: preferredHighlightedWorkspace,
                        focused: focusedWorkspace,
                        in: self.model,
                        fallbackToOrigin: false
                    )
                }
                onFocusedWorkspaceReady?()
            }

            do {
                let snapshot = try client.snapshot(focusedWorkspace: focusedWorkspace)
                let model = GridModel(config: config, states: snapshot.workspaces)
                DispatchQueue.main.async {
                    guard let self, self.refreshID == requestID else { return }
                    self.model = model
                    self.monitors = snapshot.monitors
                    self.focusedWorkspace = snapshot.focusedWorkspace
                    // Quick-navigate already moved the highlight, and the user may have moved
                    // it further while the snapshot was loading; keep where they are.
                    let preferred = quickNavigate == nil
                        ? preferredHighlightedWorkspace
                        : (self.highlightedWorkspace ?? preferredHighlightedWorkspace)
                    self.highlightedWorkspace = Self.highlightedWorkspace(
                        preferred: preferred,
                        focused: snapshot.focusedWorkspace,
                        in: model,
                        fallbackToOrigin: true
                    )
                    self.isLoading = false
                    onRefreshComplete?()
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self, self.refreshID == requestID else { return }
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    onRefreshComplete?()
                }
            }
        }
    }

    func navigate(_ direction: Direction) {
        guard let highlightedWorkspace else { return }
        self.highlightedWorkspace = model.workspace(
            from: highlightedWorkspace,
            direction: direction,
            wrap: config.behavior.wrap
        )
    }

    func confirmSelection() {
        if let pending = pendingCloseWorkspace {
            pendingCloseWorkspace = nil
            performCloseAll(workspace: pending)
            return
        }
        guard let highlightedWorkspace else {
            onRequestClose?()
            return
        }
        performAction {
            try AeroSpaceClient().focus(workspace: highlightedWorkspace)
        }
        onRequestClose?()
    }

    func switchDirectly(to workspace: String) {
        performAction {
            try AeroSpaceClient().focus(workspace: workspace)
        }
        onRequestClose?()
    }

    func cancel() {
        if pendingCloseWorkspace != nil {
            pendingCloseWorkspace = nil
            return
        }
        onRequestClose?()
    }

    func requestCloseAll() {
        guard let highlightedWorkspace else { return }
        guard model.tile(named: highlightedWorkspace)?.workspace.windows.isEmpty == false else {
            return
        }
        if config.behavior.confirmCloseAll {
            pendingCloseWorkspace = highlightedWorkspace
        } else {
            performCloseAll(workspace: highlightedWorkspace)
        }
    }

    func cancelPendingClose() {
        pendingCloseWorkspace = nil
    }

    func reportError(_ message: String) {
        errorMessage = message
    }

    func moveToDisplay(_ direction: Direction) {
        guard let highlightedWorkspace else { return }
        let mode = config.behavior.moveMode
        let target: String
        if mode == .directional {
            target = direction.rawValue
        } else {
            target = (direction == .left || direction == .up) ? "prev" : "next"
        }
        let monitorCount = monitors.count
        let wrap = mode == .cycle ? true : config.behavior.monitorWrap
        performAction(
            refreshAfter: true,
            preferredHighlightedWorkspace: highlightedWorkspace
        ) {
            try AeroSpaceClient().moveWorkspace(
                highlightedWorkspace,
                target: target,
                wrap: wrap,
                monitorCount: monitorCount
            )
        }
    }

    func moveWorkspaceContents(_ direction: Direction) {
        guard !isReorderingWorkspace,
              let source = highlightedWorkspace,
              let destination = model.reorderDestination(
                from: source,
                direction: direction
              )
        else {
            return
        }

        isReorderingWorkspace = true
        errorMessage = nil
        highlightedWorkspace = destination
        let originalModel = model
        var optimisticStates = model.tiles.map(\.workspace)
        guard let sourceIndex = optimisticStates.firstIndex(where: { $0.name == source }),
              let destinationIndex = optimisticStates.firstIndex(where: { $0.name == destination })
        else {
            isReorderingWorkspace = false
            highlightedWorkspace = source
            return
        }
        let sourceWindows = optimisticStates[sourceIndex].windows
        optimisticStates[sourceIndex].windows = optimisticStates[destinationIndex].windows
        optimisticStates[destinationIndex].windows = sourceWindows
        model = GridModel(config: config, states: optimisticStates)
        let exchangeWorkspaceContents = exchangeWorkspaceContents
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try exchangeWorkspaceContents(source, destination)
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isReorderingWorkspace = false
                    self.refresh(preferredHighlightedWorkspace: destination)
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isReorderingWorkspace = false
                    self.model = originalModel
                    self.refresh(preferredHighlightedWorkspace: source)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func updateWorkspaceMoveMode(heldModifiers: HotkeyModifiers) {
        let expected = HotkeyModifiers.commonModifierSet(
            for: config.keys.workspaceMovementHotkeys
        )
        isWorkspaceMoveModeActive = expected != nil && heldModifiers == expected
    }

    func clearWorkspaceMoveMode() {
        isWorkspaceMoveModeActive = false
    }

    /// True once quick-navigate has a destination that releasing the modifiers can commit.
    /// A pending close-all confirmation also blocks it, so a release never answers a
    /// destructive prompt the user did not mean to confirm.
    var canCommitQuickNavigate: Bool {
        highlightedWorkspace != nil && errorMessage == nil && pendingCloseWorkspace == nil
    }

    func monitorColor(for id: Int?) -> Color {
        Color(hexRGB: monitorColorHex(for: id))
    }

    func monitorColorHex(for id: Int?) -> String {
        let configuredPalette = config.appearance.monitorColors
        let palette = configuredPalette.isEmpty
            ? Appearance.defaults.monitorColors
            : configuredPalette
        guard monitors.count > 1, let id,
              let index = monitors.firstIndex(where: { $0.id == id })
        else {
            return palette[0]
        }
        return palette[index % palette.count]
    }

    var connectedMonitorCount: Int {
        max(monitors.count, screenDescriptors.count)
    }

    var shouldShowMonitorLayoutPanel: Bool {
        config.appearance.showMonitorLayoutPanel
            && connectedMonitorCount >= config.appearance.monitorLayoutMinimumMonitors
    }

    var highlightedMonitorID: Int? {
        guard let highlightedWorkspace else { return nil }
        return model.tile(named: highlightedWorkspace)?.workspace.monitorID
    }

    var monitorLayoutModel: MonitorLayoutModel {
        MonitorLayoutModel.build(
            screens: screenDescriptors,
            monitors: monitors,
            activeMonitorID: highlightedMonitorID,
            palette: config.appearance.monitorColors
        )
    }

    func updateScreenDescriptors(_ descriptors: [MonitorScreenDescriptor]) {
        screenDescriptors = descriptors
    }

    private func performCloseAll(workspace: String) {
        performAction(refreshAfter: true) {
            try AeroSpaceClient().closeAllWindows(workspace: workspace)
        }
    }

    private func performAction(
        refreshAfter: Bool = false,
        preferredHighlightedWorkspace: String? = nil,
        _ action: @escaping () throws -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try action()
                if refreshAfter {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self?.refresh(
                            preferredHighlightedWorkspace: preferredHighlightedWorkspace
                        )
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Tile a quick-navigate step lands on. Falls back to the focused workspace when the
    /// grid has no neighbour in that direction, so the highlight is never lost.
    static func quickNavigateDestination(
        from focused: String,
        direction: Direction,
        in model: GridModel,
        wrap: Bool
    ) -> String? {
        guard model.tile(named: focused) != nil else {
            return model.originWorkspace
        }
        return model.workspace(
            from: focused,
            direction: direction,
            wrap: wrap,
            fallbackFromOverflow: true
        ) ?? focused
    }

    static func highlightedWorkspace(
        preferred: String?,
        focused: String,
        in model: GridModel,
        fallbackToOrigin: Bool
    ) -> String? {
        if let preferred, model.tile(named: preferred) != nil {
            return preferred
        }
        if model.tile(named: focused) != nil {
            return focused
        }
        return fallbackToOrigin ? model.originWorkspace : nil
    }
}

extension Color {
    init(hexRGB: String) {
        let digits = hexRGB.dropFirst()
        let value = UInt64(digits, radix: 16)!
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}
