import CoreGraphics
import GridSpacesCore
import Testing
@testable import GridSpacesAgent

@Test func monitorLayoutPreservesSideBySideGeometryAndAspectRatios() {
    let layout = MonitorLayoutModel.build(
        screens: [
            MonitorScreenDescriptor(
                frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
                displayID: 10,
                name: "Left"
            ),
            MonitorScreenDescriptor(
                frame: CGRect(x: 1920, y: 0, width: 2560, height: 1440),
                displayID: 20,
                name: "Right"
            ),
        ],
        monitors: [
            MonitorInfo(id: 10, name: "Left"),
            MonitorInfo(id: 20, name: "Right"),
        ],
        activeMonitorID: 20,
        palette: ["#112233", "#ABCDEF"]
    )

    #expect(layout.virtualSize == CGSize(width: 4480, height: 1440))
    #expect(layout.items[0].rect == CGRect(x: 0, y: 360, width: 1920, height: 1080))
    #expect(layout.items[1].rect == CGRect(x: 1920, y: 0, width: 2560, height: 1440))
    #expect(layout.items[0].colorHex == "#112233")
    #expect(layout.items[1].colorHex == "#ABCDEF")
    #expect(layout.items[0].isActive == false)
    #expect(layout.items[1].isActive == true)
}

@Test func monitorLayoutPreservesVerticalOffsets() {
    let layout = MonitorLayoutModel.build(
        screens: [
            MonitorScreenDescriptor(
                frame: CGRect(x: 0, y: 0, width: 1200, height: 900),
                displayID: 1,
                name: "Lower"
            ),
            MonitorScreenDescriptor(
                frame: CGRect(x: 0, y: 900, width: 1200, height: 800),
                displayID: 2,
                name: "Upper"
            ),
        ],
        monitors: [
            MonitorInfo(id: 1, name: "Lower"),
            MonitorInfo(id: 2, name: "Upper"),
        ],
        activeMonitorID: 1,
        palette: ["#111111", "#222222"]
    )

    #expect(layout.virtualSize == CGSize(width: 1200, height: 1700))
    #expect(layout.items[0].rect == CGRect(x: 0, y: 800, width: 1200, height: 900))
    #expect(layout.items[1].rect == CGRect(x: 0, y: 0, width: 1200, height: 800))
}

@Test func monitorLayoutMatchesScreensByNameWhenDisplayIDDoesNotMatch() {
    let layout = MonitorLayoutModel.build(
        screens: [
            MonitorScreenDescriptor(
                frame: CGRect(x: 0, y: 0, width: 1000, height: 700),
                displayID: 999,
                name: "Studio Display"
            ),
        ],
        monitors: [
            MonitorInfo(id: 42, name: "Studio Display"),
        ],
        activeMonitorID: 42,
        palette: ["#123456"]
    )

    #expect(layout.items.first?.monitorID == 42)
    #expect(layout.items.first?.isActive == true)
}

@Test func monitorLayoutPrefersAeroSpaceAppKitScreenIndex() {
    let layout = MonitorLayoutModel.build(
        screens: [
            MonitorScreenDescriptor(
                frame: CGRect(x: 1200, y: 0, width: 1200, height: 900),
                displayID: 900,
                name: "Same Name"
            ),
            MonitorScreenDescriptor(
                frame: CGRect(x: 0, y: 0, width: 1200, height: 900),
                displayID: 901,
                name: "Same Name"
            ),
        ],
        monitors: [
            MonitorInfo(id: 1, name: "Left", appKitScreenIndex: 2),
            MonitorInfo(id: 2, name: "Right", appKitScreenIndex: 1),
        ],
        activeMonitorID: 2,
        palette: ["#111111", "#222222"]
    )

    #expect(layout.items.map(\.monitorID) == [2, 1])
    #expect(layout.items.map(\.colorHex) == ["#222222", "#111111"])
    #expect(layout.items.map(\.isActive) == [true, false])
}

@Test func monitorLayoutDoesNotAssignOneNamedMonitorToMultipleScreens() {
    let layout = MonitorLayoutModel.build(
        screens: [
            MonitorScreenDescriptor(
                frame: CGRect(x: 0, y: 0, width: 1200, height: 900),
                displayID: 100,
                name: "Studio Display"
            ),
            MonitorScreenDescriptor(
                frame: CGRect(x: 1200, y: 0, width: 1200, height: 900),
                displayID: 200,
                name: "Studio Display"
            ),
        ],
        monitors: [
            MonitorInfo(id: 1, name: "Studio Display"),
            MonitorInfo(id: 2, name: "External Display"),
        ],
        activeMonitorID: 1,
        palette: ["#111111", "#222222"]
    )

    #expect(layout.items.map(\.monitorID) == [1, 2])
    #expect(layout.items.map(\.colorHex) == ["#111111", "#222222"])
    #expect(layout.items.map(\.isActive) == [true, false])
}

@Test func monitorLayoutUsesDeterministicFallbackOrderAndCyclesPalette() {
    let layout = MonitorLayoutModel.build(
        screens: [
            MonitorScreenDescriptor(
                frame: CGRect(x: 1200, y: 0, width: 1200, height: 900),
                name: "Right"
            ),
            MonitorScreenDescriptor(
                frame: CGRect(x: 0, y: 0, width: 1200, height: 900),
                name: "Left"
            ),
            MonitorScreenDescriptor(
                frame: CGRect(x: 2400, y: 0, width: 1200, height: 900),
                name: "Far Right"
            ),
        ],
        monitors: [
            MonitorInfo(id: 1, name: "AeroSpace 1"),
            MonitorInfo(id: 2, name: "AeroSpace 2"),
            MonitorInfo(id: 3, name: "AeroSpace 3"),
        ],
        activeMonitorID: 3,
        palette: ["#111111", "#222222"]
    )

    #expect(layout.items[0].monitorID == 2)
    #expect(layout.items[0].colorHex == "#222222")
    #expect(layout.items[0].isActive == false)
    #expect(layout.items[1].monitorID == 1)
    #expect(layout.items[1].colorHex == "#111111")
    #expect(layout.items[1].isActive == false)
    #expect(layout.items[2].monitorID == 3)
    #expect(layout.items[2].colorHex == "#111111")
    #expect(layout.items[2].isActive == true)
}

@MainActor
@Test func monitorLayoutVisibilityUsesConfigAndConnectedMonitorCount() {
    var appearance = Appearance(monitorColors: ["#111111", "#222222"])
    appearance.monitorLayoutMinimumMonitors = 2
    let viewModel = GridViewModel(
        config: GridSpacesConfig(grid: [["1"]], appearance: appearance)
    )

    viewModel.updateScreenDescriptors([
        MonitorScreenDescriptor(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    ])
    #expect(viewModel.shouldShowMonitorLayoutPanel == false)

    viewModel.updateScreenDescriptors([
        MonitorScreenDescriptor(frame: CGRect(x: 0, y: 0, width: 100, height: 100)),
        MonitorScreenDescriptor(frame: CGRect(x: 100, y: 0, width: 100, height: 100)),
    ])
    #expect(viewModel.shouldShowMonitorLayoutPanel == true)

    appearance.showMonitorLayoutPanel = false
    let disabledViewModel = GridViewModel(
        config: GridSpacesConfig(grid: [["1"]], appearance: appearance)
    )
    disabledViewModel.updateScreenDescriptors(viewModel.screenDescriptors)
    #expect(disabledViewModel.shouldShowMonitorLayoutPanel == false)
}

@MainActor
@Test func monitorLayoutActiveMonitorFollowsHighlightedWorkspaceOnly() {
    let config = GridSpacesConfig(
        grid: [["1", "2"]],
        appearance: Appearance(monitorColors: ["#111111", "#222222"])
    )
    let viewModel = GridViewModel(config: config)
    viewModel.model = GridModel(
        config: config,
        states: [
            WorkspaceState(name: "1", monitorID: 10),
            WorkspaceState(name: "2", monitorID: 20),
        ]
    )
    viewModel.monitors = [
        MonitorInfo(id: 10, name: "Left"),
        MonitorInfo(id: 20, name: "Right"),
    ]
    viewModel.updateScreenDescriptors([
        MonitorScreenDescriptor(
            frame: CGRect(x: 0, y: 0, width: 100, height: 100),
            displayID: 10,
            name: "Left"
        ),
        MonitorScreenDescriptor(
            frame: CGRect(x: 100, y: 0, width: 100, height: 100),
            displayID: 20,
            name: "Right"
        ),
    ])
    viewModel.highlightedWorkspace = "1"

    #expect(viewModel.monitorLayoutModel.items.map(\.isActive) == [true, false])

    viewModel.navigate(.right)

    #expect(viewModel.highlightedWorkspace == "2")
    #expect(viewModel.monitorLayoutModel.items.map(\.isActive) == [false, true])
}
