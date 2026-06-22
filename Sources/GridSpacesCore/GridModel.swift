import Foundation

public struct GridTile: Identifiable, Hashable, Sendable {
    public var id: String { workspace.name }
    public var workspace: WorkspaceState
    public let position: Position
    public let isOverflow: Bool

    public init(workspace: WorkspaceState, position: Position, isOverflow: Bool) {
        self.workspace = workspace
        self.position = position
        self.isOverflow = isOverflow
    }
}

public struct GridModel: Sendable {
    public private(set) var tiles: [GridTile]
    public let configuredRowCount: Int
    public let columnCount: Int
    private let byName: [String: GridTile]
    private let byPosition: [Position: GridTile]

    public init(config: GridSpacesConfig, states: [WorkspaceState]) {
        let stateByName = Dictionary(uniqueKeysWithValues: states.map { ($0.name, $0) })
        var built: [GridTile] = []
        var configuredNames = Set<String>()

        for (row, values) in config.grid.enumerated() {
            for (column, name) in values.enumerated() {
                guard let name else { continue }
                configuredNames.insert(name)
                let state = stateByName[name] ?? WorkspaceState(name: name)
                built.append(GridTile(
                    workspace: state,
                    position: Position(row: row, column: column),
                    isOverflow: false
                ))
            }
        }

        let overflow = states
            .filter { !configuredNames.contains($0.name) && !$0.windows.isEmpty }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let overflowRow = config.grid.count
        for (column, state) in overflow.enumerated() {
            built.append(GridTile(
                workspace: state,
                position: Position(row: overflowRow, column: column),
                isOverflow: true
            ))
        }

        tiles = built
        configuredRowCount = config.grid.count
        columnCount = max(
            config.grid.map(\.count).max() ?? 0,
            overflow.count
        )
        byName = Dictionary(uniqueKeysWithValues: built.map { ($0.workspace.name, $0) })
        byPosition = Dictionary(uniqueKeysWithValues: built.map { ($0.position, $0) })
    }

    public var rowCount: Int {
        configuredRowCount + (tiles.contains(where: \.isOverflow) ? 1 : 0)
    }

    public var originWorkspace: String? {
        tiles
            .filter { !$0.isOverflow }
            .min { lhs, rhs in
                lhs.position.row == rhs.position.row
                    ? lhs.position.column < rhs.position.column
                    : lhs.position.row < rhs.position.row
            }?
            .workspace.name
    }

    public func tile(named name: String) -> GridTile? {
        byName[name]
    }

    public func workspace(
        from currentName: String,
        direction: Direction,
        wrap: Bool,
        fallbackFromOverflow: Bool = false
    ) -> String? {
        guard let current = byName[currentName] else {
            return originWorkspace
        }
        if fallbackFromOverflow && current.isOverflow {
            return originWorkspace
        }

        switch direction {
        case .left, .right:
            let rowTiles = tiles
                .filter { $0.position.row == current.position.row }
                .sorted { $0.position.column < $1.position.column }
            return adjacent(
                current: current,
                candidates: rowTiles,
                increasing: direction == .right,
                coordinate: { $0.position.column },
                wrap: wrap
            )
        case .up, .down:
            let columnTiles = tiles
                .filter { $0.position.column == current.position.column }
                .sorted { $0.position.row < $1.position.row }
            return adjacent(
                current: current,
                candidates: columnTiles,
                increasing: direction == .down,
                coordinate: { $0.position.row },
                wrap: wrap
            )
        }
    }

    public func reorderDestination(
        from currentName: String,
        direction: Direction
    ) -> String? {
        guard let current = byName[currentName], !current.isOverflow else {
            return nil
        }

        let candidates: [GridTile]
        let increasing: Bool
        let coordinate: (GridTile) -> Int
        switch direction {
        case .left, .right:
            candidates = tiles.filter {
                !$0.isOverflow && $0.position.row == current.position.row
            }
            increasing = direction == .right
            coordinate = { $0.position.column }
        case .up, .down:
            candidates = tiles.filter {
                !$0.isOverflow && $0.position.column == current.position.column
            }
            increasing = direction == .down
            coordinate = { $0.position.row }
        }

        let currentCoordinate = coordinate(current)
        let eligible = candidates.filter {
            increasing
                ? coordinate($0) > currentCoordinate
                : coordinate($0) < currentCoordinate
        }
        return (increasing
            ? eligible.min(by: { coordinate($0) < coordinate($1) })
            : eligible.max(by: { coordinate($0) < coordinate($1) })
        )?.workspace.name
    }

    private func adjacent(
        current: GridTile,
        candidates: [GridTile],
        increasing: Bool,
        coordinate: (GridTile) -> Int,
        wrap: Bool
    ) -> String? {
        let currentCoordinate = coordinate(current)
        let next = increasing
            ? candidates.first(where: { coordinate($0) > currentCoordinate })
            : candidates.last(where: { coordinate($0) < currentCoordinate })

        if let next {
            return next.workspace.name
        }
        guard wrap, candidates.count > 1 else {
            return current.workspace.name
        }
        return (increasing ? candidates.first : candidates.last)?.workspace.name
    }
}
