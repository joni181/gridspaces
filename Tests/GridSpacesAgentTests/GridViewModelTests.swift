import GridSpacesCore
import Testing
@testable import GridSpacesAgent

@MainActor
@Test func refreshSelectionPreservesHighlightedWorkspace() {
    let config = GridSpacesConfig(grid: [["focused", "highlighted"]])
    let model = GridModel(
        config: config,
        states: [
            WorkspaceState(name: "focused", monitorID: 1),
            WorkspaceState(name: "highlighted", monitorID: 1),
        ]
    )

    let selection = GridViewModel.highlightedWorkspace(
        preferred: "highlighted",
        focused: "focused",
        in: model,
        fallbackToOrigin: true
    )

    #expect(selection == "highlighted")
}

@MainActor
@Test func refreshSelectionFallsBackWhenHighlightedWorkspaceDisappears() {
    let config = GridSpacesConfig(grid: [["focused"]])
    let model = GridModel(
        config: config,
        states: [WorkspaceState(name: "focused", monitorID: 1)]
    )

    let selection = GridViewModel.highlightedWorkspace(
        preferred: "missing",
        focused: "focused",
        in: model,
        fallbackToOrigin: true
    )

    #expect(selection == "focused")
}

@MainActor
@Test func workspaceMoveModeRequiresExactCommonModifiers() {
    let viewModel = GridViewModel()

    viewModel.updateWorkspaceMoveMode(heldModifiers: .option)
    #expect(viewModel.isWorkspaceMoveModeActive)

    viewModel.updateWorkspaceMoveMode(heldModifiers: [.option, .control])
    #expect(!viewModel.isWorkspaceMoveModeActive)

    viewModel.clearWorkspaceMoveMode()
    #expect(!viewModel.isWorkspaceMoveModeActive)
}

@MainActor
@Test func quickNavigateDestinationMovesOneTile() {
    let config = GridSpacesConfig(grid: [["1", "2", "3"], ["Q", "W", "E"]])
    let model = GridModel(config: config, states: [])

    #expect(
        GridViewModel.quickNavigateDestination(
            from: "2", direction: .right, in: model, wrap: false
        ) == "3"
    )
    #expect(
        GridViewModel.quickNavigateDestination(
            from: "2", direction: .down, in: model, wrap: false
        ) == "W"
    )
}

@MainActor
@Test func quickNavigateDestinationStaysPutAtTheEdgeWithoutWrap() {
    let config = GridSpacesConfig(grid: [["1", "2", "3"]])
    let model = GridModel(config: config, states: [])

    #expect(
        GridViewModel.quickNavigateDestination(
            from: "3", direction: .right, in: model, wrap: false
        ) == "3"
    )
    #expect(
        GridViewModel.quickNavigateDestination(
            from: "3", direction: .right, in: model, wrap: true
        ) == "1"
    )
}

@MainActor
@Test func quickNavigateDestinationFallsBackToOriginForUnknownWorkspaces() {
    let config = GridSpacesConfig(grid: [["1", "2"]])
    let model = GridModel(
        config: config,
        states: [
            WorkspaceState(
                name: "unmapped",
                windows: [WindowInfo(id: 1, appName: "App", title: "Title")]
            )
        ]
    )

    // Focused workspace outside the grid, and overflow tiles, both resolve to the origin.
    #expect(
        GridViewModel.quickNavigateDestination(
            from: "missing", direction: .up, in: model, wrap: false
        ) == "1"
    )
    #expect(
        GridViewModel.quickNavigateDestination(
            from: "unmapped", direction: .up, in: model, wrap: false
        ) == "1"
    )
}
