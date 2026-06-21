import AppKit
import GridSpacesCore

@MainActor
public final class ScreenOverlayService {
    private let renderer: ScreenOverlayRendering
    private let screensProvider: () -> [NSScreen]
    private let configProvider: () -> GridSpacesConfig
    private let monitorLoader: () throws -> [MonitorInfo]
    private var appearance = Appearance.defaults
    private var refreshID: UInt = 0

    private(set) var cachedMonitors: [MonitorInfo]
    private(set) var isVisible = false

    public convenience init() {
        self.init(
            renderer: ScreenOverlayController(),
            screensProvider: { NSScreen.screens },
            configProvider: { ConfigLoader.load().config },
            monitorLoader: { try AeroSpaceClient().listMonitors() },
            initialMonitors: []
        )
    }

    init(
        renderer: ScreenOverlayRendering,
        screensProvider: @escaping () -> [NSScreen],
        configProvider: @escaping () -> GridSpacesConfig,
        monitorLoader: @escaping () throws -> [MonitorInfo],
        initialMonitors: [MonitorInfo]
    ) {
        self.renderer = renderer
        self.screensProvider = screensProvider
        self.configProvider = configProvider
        self.monitorLoader = monitorLoader
        cachedMonitors = initialMonitors
    }

    public func show() {
        isVisible = true
        appearance = configProvider().appearance
        render()
        refreshMonitors()
    }

    public func hide() {
        isVisible = false
        renderer.remove()
    }

    public func reload() {
        appearance = configProvider().appearance
        if isVisible {
            render()
        }
        refreshMonitors()
    }

    public func shutdown() {
        hide()
    }

    private func render() {
        renderer.update(
            screens: screensProvider(),
            monitors: cachedMonitors,
            appearance: appearance
        )
    }

    private func refreshMonitors() {
        refreshID &+= 1
        let requestID = refreshID
        let monitorLoader = monitorLoader
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let monitors = try? monitorLoader() else { return }
            DispatchQueue.main.async {
                guard let self, self.refreshID == requestID else { return }
                self.applyRefreshedMonitors(monitors)
            }
        }
    }

    func applyRefreshedMonitors(_ monitors: [MonitorInfo]) {
        guard monitors != cachedMonitors else { return }
        cachedMonitors = monitors
        if isVisible {
            render()
        }
    }
}
