import Testing
@testable import GridSpacesCore

@Test func configuredPlacementAndReservedUnknownWorkspace() {
    let config = GridSpacesConfig(grid: [["1", "2"], ["Q"]])
    let model = GridModel(
        config: config,
        states: [WorkspaceState(name: "1")]
    )

    #expect(model.tile(named: "1")?.position == Position(row: 0, column: 0))
    #expect(model.tile(named: "2")?.position == Position(row: 0, column: 1))
    #expect(model.tile(named: "2")?.workspace.windows == [])
    #expect(model.tile(named: "Q")?.position == Position(row: 1, column: 0))
}

@Test func onlyOccupiedUngridddedWorkspacesEnterOverflow() {
    let config = GridSpacesConfig(grid: [["1"]])
    let occupied = WorkspaceState(
        name: "Y",
        windows: [WindowInfo(id: 1, appName: "Notes", title: "Note")]
    )
    let model = GridModel(
        config: config,
        states: [occupied, WorkspaceState(name: "Z")]
    )

    #expect(model.tile(named: "Y")?.position == Position(row: 1, column: 0))
    #expect(model.tile(named: "Y")?.isOverflow == true)
    #expect(model.tile(named: "Z") == nil)
}

@Test func directionalNavigationSkipsGaps() {
    let config = GridSpacesConfig(grid: [["1", nil, "3"]])
    let model = GridModel(config: config, states: [])

    #expect(model.workspace(from: "1", direction: .right, wrap: false) == "3")
    #expect(model.workspace(from: "3", direction: .left, wrap: false) == "1")
}

@Test func wrapAndNoWrap() {
    let model = GridModel(
        config: GridSpacesConfig(grid: [["1", "2", "3"]]),
        states: []
    )

    #expect(model.workspace(from: "3", direction: .right, wrap: false) == "3")
    #expect(model.workspace(from: "3", direction: .right, wrap: true) == "1")
}

@Test func ungridddedHeadlessSwitchUsesOrigin() {
    let overflow = WorkspaceState(
        name: "Y",
        windows: [WindowInfo(id: 1, appName: "Notes", title: "Note")]
    )
    let model = GridModel(
        config: GridSpacesConfig(grid: [["1", "2"]]),
        states: [overflow]
    )

    #expect(
        model.workspace(
            from: "Y",
            direction: .right,
            wrap: false,
            fallbackFromOverflow: true
        ) == "1"
    )
}

@Test func navigationCanEnterOverflow() {
    let overflow = WorkspaceState(
        name: "Y",
        windows: [WindowInfo(id: 1, appName: "Notes", title: "Note")]
    )
    let model = GridModel(
        config: GridSpacesConfig(grid: [["1"]]),
        states: [overflow]
    )

    #expect(model.workspace(from: "1", direction: .down, wrap: false) == "Y")
}
