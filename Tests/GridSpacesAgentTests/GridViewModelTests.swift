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
