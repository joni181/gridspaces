import Testing
@testable import GridSpacesCore

@Test func exchangeMovesIntoEmptyWorkspace() throws {
    let state = ExchangeState(
        workspaces: [
            "A": [],
            "B": [window(1), window(2)],
        ]
    )

    try state.exchange.execute(source: "B", destination: "A")

    #expect(state.ids(in: "A") == [1, 2])
    #expect(state.ids(in: "B").isEmpty)
}

@Test func exchangeSwapsOccupiedWorkspaces() throws {
    let state = ExchangeState(
        workspaces: [
            "A": [window(1), window(2)],
            "B": [window(3), window(4)],
        ]
    )

    try state.exchange.execute(source: "B", destination: "A")

    #expect(state.ids(in: "A") == [3, 4])
    #expect(state.ids(in: "B") == [1, 2])
}

@Test func exchangeRollsBackAfterMoveFailure() {
    let state = ExchangeState(
        workspaces: [
            "A": [window(1), window(2)],
            "B": [window(3), window(4)],
        ],
        failingMoveID: 4
    )

    #expect(throws: ExchangeTestError.self) {
        try state.exchange.execute(source: "B", destination: "A")
    }
    #expect(state.ids(in: "A") == [1, 2])
    #expect(state.ids(in: "B") == [3, 4])
}

@Test func exchangeIgnoresWindowThatVanishedDuringMove() throws {
    let state = ExchangeState(
        workspaces: [
            "A": [],
            "B": [window(1), window(2)],
        ],
        vanishingMoveID: 2
    )

    try state.exchange.execute(source: "B", destination: "A")

    #expect(state.ids(in: "A") == [1])
    #expect(state.ids(in: "B").isEmpty)
}

@Test func exchangeRollsBackAfterVerificationFailure() {
    let state = ExchangeState(
        workspaces: [
            "A": [window(1)],
            "B": [window(2)],
        ],
        ignoredMoveID: 2
    )

    #expect(throws: GridSpacesError.self) {
        try state.exchange.execute(source: "B", destination: "A")
    }
    #expect(state.ids(in: "A") == [1])
    #expect(state.ids(in: "B") == [2])
}

private enum ExchangeTestError: Error {
    case failed
}

private final class ExchangeState {
    private var workspaces: [String: [WindowInfo]]
    private let failingMoveID: Int?
    private let vanishingMoveID: Int?
    private let ignoredMoveID: Int?

    init(
        workspaces: [String: [WindowInfo]],
        failingMoveID: Int? = nil,
        vanishingMoveID: Int? = nil,
        ignoredMoveID: Int? = nil
    ) {
        self.workspaces = workspaces
        self.failingMoveID = failingMoveID
        self.vanishingMoveID = vanishingMoveID
        self.ignoredMoveID = ignoredMoveID
    }

    var exchange: WorkspaceContentExchange {
        WorkspaceContentExchange(
            listWindows: { [self] workspace in
                workspaces[workspace, default: []]
            },
            moveWindow: { [self] id, destination in
                if id == vanishingMoveID {
                    remove(id)
                    throw ExchangeTestError.failed
                }
                if id == failingMoveID {
                    throw ExchangeTestError.failed
                }
                if id == ignoredMoveID {
                    return
                }
                remove(id)
                workspaces[destination, default: []].append(window(id))
            }
        )
    }

    func ids(in workspace: String) -> Set<Int> {
        Set(workspaces[workspace, default: []].map(\.id))
    }

    private func remove(_ id: Int) {
        for workspace in workspaces.keys {
            workspaces[workspace]?.removeAll { $0.id == id }
        }
    }
}

private func window(_ id: Int) -> WindowInfo {
    WindowInfo(id: id, appName: "App \(id)", title: "Window \(id)")
}
