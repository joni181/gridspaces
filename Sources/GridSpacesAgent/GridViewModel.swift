import AppKit
import GridSpacesCore
import SwiftUI

@MainActor
final class GridViewModel: ObservableObject {
    @Published var model = GridModel(config: .defaults, states: [])
    @Published var highlightedWorkspace: String?
    @Published var focusedWorkspace: String?
    @Published var monitors: [MonitorInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingCloseWorkspace: String?

    private(set) var config = GridSpacesConfig.defaults
    let iconResolver = AppIconResolver()
    var onRequestClose: (() -> Void)?
    private var refreshID: UInt = 0

    func reloadConfiguration() {
        let loaded = ConfigLoader.load()
        config = loaded.config
        if !loaded.warnings.isEmpty {
            errorMessage = loaded.warnings.joined(separator: "\n")
        }
    }

    func refresh(onFocusedWorkspaceReady: (() -> Void)? = nil) {
        refreshID &+= 1
        let requestID = refreshID
        reloadConfiguration()
        isLoading = true
        errorMessage = nil
        highlightedWorkspace = nil
        let config = config
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
                }
                return
            }

            DispatchQueue.main.async {
                guard let self, self.refreshID == requestID else { return }
                self.focusedWorkspace = focusedWorkspace
                self.highlightedWorkspace = self.model.tile(named: focusedWorkspace) != nil
                    ? focusedWorkspace
                    : nil
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
                    self.highlightedWorkspace = model.tile(named: snapshot.focusedWorkspace) != nil
                        ? snapshot.focusedWorkspace
                        : model.originWorkspace
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self, self.refreshID == requestID else { return }
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
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

    func moveWorkspace(_ direction: Direction) {
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
        performAction(refreshAfter: true) {
            try AeroSpaceClient().moveWorkspace(
                highlightedWorkspace,
                target: target,
                wrap: wrap,
                monitorCount: monitorCount
            )
        }
    }

    func monitorColor(for id: Int?) -> Color {
        let palette: [Color] = [.cyan, .orange, .green, .pink, .purple, .yellow]
        guard monitors.count > 1, let id,
              let index = monitors.firstIndex(where: { $0.id == id })
        else {
            return .cyan
        }
        return palette[index % palette.count]
    }

    private func performCloseAll(workspace: String) {
        performAction(refreshAfter: true) {
            try AeroSpaceClient().closeAllWindows(workspace: workspace)
        }
    }

    private func performAction(refreshAfter: Bool = false, _ action: @escaping () throws -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try action()
                if refreshAfter {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self?.refresh()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
