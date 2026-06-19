import Foundation

public enum Direction: String, CaseIterable, Codable, Sendable {
    case left
    case down
    case up
    case right
}

public enum MoveMode: String, Codable, Sendable {
    case directional
    case cycle
}

public struct Position: Hashable, Codable, Sendable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

public struct WindowInfo: Codable, Hashable, Sendable {
    public let id: Int
    public let appName: String
    public let title: String

    enum CodingKeys: String, CodingKey {
        case id = "window-id"
        case appName = "app-name"
        case title = "window-title"
    }

    public init(id: Int, appName: String, title: String) {
        self.id = id
        self.appName = appName
        self.title = title
    }
}

public struct MonitorInfo: Codable, Hashable, Sendable {
    public let id: Int
    public let name: String

    enum CodingKeys: String, CodingKey {
        case id = "monitor-id"
        case name = "monitor-name"
    }

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public struct WorkspaceState: Hashable, Sendable {
    public let name: String
    public var windows: [WindowInfo]
    public var monitorID: Int?

    public init(name: String, windows: [WindowInfo] = [], monitorID: Int? = nil) {
        self.name = name
        self.windows = windows
        self.monitorID = monitorID
    }

    public var distinctApplications: [String] {
        var seen = Set<String>()
        return windows.compactMap { seen.insert($0.appName).inserted ? $0.appName : nil }
    }
}

public struct AeroSpaceSnapshot: Sendable {
    public let workspaces: [WorkspaceState]
    public let focusedWorkspace: String
    public let monitors: [MonitorInfo]

    public init(workspaces: [WorkspaceState], focusedWorkspace: String, monitors: [MonitorInfo]) {
        self.workspaces = workspaces
        self.focusedWorkspace = focusedWorkspace
        self.monitors = monitors
    }
}

public enum GridSpacesError: LocalizedError {
    case aerospaceNotFound
    case commandFailed(command: String, message: String)
    case invalidOutput(command: String, message: String)
    case invalidArguments(String)

    public var errorDescription: String? {
        switch self {
        case .aerospaceNotFound:
            return "AeroSpace is required but its `aerospace` CLI was not found on PATH. Install AeroSpace and ensure the CLI is available."
        case let .commandFailed(command, message):
            return "AeroSpace command failed (`\(command)`): \(message)"
        case let .invalidOutput(command, message):
            return "Could not understand AeroSpace output from `\(command)`: \(message)"
        case let .invalidArguments(message):
            return message
        }
    }
}
