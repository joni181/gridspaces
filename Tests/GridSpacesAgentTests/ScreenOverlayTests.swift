import AppKit
import GridSpacesCore
import Testing
@testable import GridSpacesOverlayKit

@Test func overlayMappingMatchesScreensByNameBeforeUsingOrderFallback() {
    let assignments = ScreenOverlayMapping.assignments(
        screenNames: ["Studio Display", "Built-in Retina Display", "Projector"],
        monitorNames: ["Built-in Retina Display", "Studio Display", "Unknown"]
    )

    #expect(
        assignments == [
            ScreenOverlayAssignment(screenIndex: 0, monitorIndex: 1),
            ScreenOverlayAssignment(screenIndex: 1, monitorIndex: 0),
            ScreenOverlayAssignment(screenIndex: 2, monitorIndex: 2),
        ]
    )
}

@Test func overlayMappingHandlesDuplicateNamesDeterministically() {
    let assignments = ScreenOverlayMapping.assignments(
        screenNames: ["Display", "Display", "Extra"],
        monitorNames: ["Display", "Display"]
    )

    #expect(
        assignments == [
            ScreenOverlayAssignment(screenIndex: 0, monitorIndex: 0),
            ScreenOverlayAssignment(screenIndex: 1, monitorIndex: 1),
            ScreenOverlayAssignment(screenIndex: 2, monitorIndex: 2),
        ]
    )
}

@Test func overlayMappingFallsBackToCurrentScreenOrderWithoutCachedMonitors() {
    let assignments = ScreenOverlayMapping.assignments(
        screenNames: ["First", "Second", "Third"],
        monitorNames: []
    )

    #expect(
        assignments == [
            ScreenOverlayAssignment(screenIndex: 0, monitorIndex: 0),
            ScreenOverlayAssignment(screenIndex: 1, monitorIndex: 1),
            ScreenOverlayAssignment(screenIndex: 2, monitorIndex: 2),
        ]
    )
}

@Test func defaultOverlayStyleRequiresTwoScreens() {
    #expect(ScreenOverlayStyle.make(screenCount: 1, appearance: .defaults) == nil)
    #expect(
        ScreenOverlayStyle.make(screenCount: 2, appearance: .defaults)
            == ScreenOverlayStyle(borderWidth: 5)
    )
}

@Test func overlayStyleIsDisabledWhenBordersAreDisabled() {
    let appearance = Appearance(
        monitorColors: ["#112233"],
        screenBorders: false,
        screenMinimumMonitors: 1
    )

    #expect(ScreenOverlayStyle.make(screenCount: 1, appearance: appearance) == nil)
}

@Test func invisibleOverlayStyleIsSkipped() {
    let disabled = Appearance(
        monitorColors: ["#112233"],
        screenBorders: false,
        screenMinimumMonitors: 1
    )

    #expect(ScreenOverlayStyle.make(screenCount: 1, appearance: disabled) == nil)
}

@Test func overlayDrawingBoundsUseOnlyDynamicTopReservation() {
    let screenFrame = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
    let withMenuBar = ScreenOverlayGeometry.drawingBounds(
        screenFrame: screenFrame,
        visibleFrame: CGRect(x: -1870, y: 40, width: 1870, height: 1016)
    )
    let withoutMenuBar = ScreenOverlayGeometry.drawingBounds(
        screenFrame: screenFrame,
        visibleFrame: CGRect(x: -1870, y: 40, width: 1870, height: 1040)
    )

    #expect(withMenuBar == CGRect(x: 0, y: 0, width: 1920, height: 1056))
    #expect(withoutMenuBar == CGRect(x: 0, y: 0, width: 1920, height: 1080))
}

@Test func borderFramesUseNarrowOpaqueEdgeSurfaces() {
    let frames = ScreenOverlayGeometry.borderFrames(
        screenFrame: CGRect(x: -1920, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: -1920, y: 0, width: 1920, height: 1056),
        width: 5
    )

    #expect(
        frames == [
            CGRect(x: -1920, y: 1051, width: 1920, height: 5),
            CGRect(x: -1920, y: 0, width: 1920, height: 5),
            CGRect(x: -1920, y: 5, width: 5, height: 1046),
            CGRect(x: -5, y: 5, width: 5, height: 1046),
        ]
    )
    #expect(frames.reduce(0) { $0 + $1.width * $1.height } < 40_000)
}

@MainActor
@Test func borderWindowsAreOpaqueAndDoNotAcceptInteraction() throws {
    let screen = try #require(NSScreen.screens.first)
    let windows = ScreenBorderWindow.makeWindows(
        screen: screen,
        color: NSColor.red,
        width: 5
    )

    #expect(windows.count == 4)
    for window in windows {
        #expect(window.ignoresMouseEvents)
        #expect(!window.canBecomeKey)
        #expect(!window.canBecomeMain)
        #expect(window.isOpaque)
        #expect(!window.hasShadow)
        #expect(window.level.rawValue < NSWindow.Level.floating.rawValue)
        #expect(window.collectionBehavior.contains(.canJoinAllSpaces))
        #expect(window.collectionBehavior.contains(.fullScreenAuxiliary))
    }
}

@MainActor
@Test func overlayServiceShowsFromCacheAndAppliesRefreshWhileVisible() {
    let renderer = RecordingOverlayRenderer()
    let cached = [MonitorInfo(id: 1, name: "Cached")]
    let fresh = [MonitorInfo(id: 2, name: "Fresh")]
    let config = GridSpacesConfig(
        grid: [["1"]],
        appearance: Appearance(
            monitorColors: ["#112233"],
            screenMinimumMonitors: 1
        )
    )
    let service = ScreenOverlayService(
        renderer: renderer,
        screensProvider: { [] },
        configProvider: { config },
        monitorLoader: { throw GridSpacesError.aerospaceNotFound },
        initialMonitors: cached
    )

    service.show()
    #expect(service.isVisible)
    #expect(renderer.monitorUpdates == [cached])

    service.applyRefreshedMonitors(fresh)
    #expect(service.cachedMonitors == fresh)
    #expect(renderer.monitorUpdates == [cached, fresh])

    service.hide()
    #expect(!service.isVisible)
    #expect(renderer.removeCount == 1)
}

@MainActor
private final class RecordingOverlayRenderer: ScreenOverlayRendering {
    var monitorUpdates: [[MonitorInfo]] = []
    var removeCount = 0

    func update(
        screens: [NSScreen],
        monitors: [MonitorInfo],
        appearance: Appearance
    ) {
        monitorUpdates.append(monitors)
    }

    func remove() {
        removeCount += 1
    }
}
