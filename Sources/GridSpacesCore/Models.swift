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

public struct HotkeyModifiers: OptionSet, Equatable, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let command = HotkeyModifiers(rawValue: 1 << 0)
    public static let option = HotkeyModifiers(rawValue: 1 << 1)
    public static let control = HotkeyModifiers(rawValue: 1 << 2)
    public static let shift = HotkeyModifiers(rawValue: 1 << 3)

    public static func commonModifierSet(for hotkeys: [String]) -> HotkeyModifiers? {
        guard hotkeys.count == 4 else { return nil }
        let parsed = hotkeys.compactMap(parse)
        guard parsed.count == hotkeys.count,
              let first = parsed.first,
              !first.modifiers.isEmpty,
              parsed.allSatisfy({ $0.modifiers == first.modifiers })
        else {
            return nil
        }
        return first.modifiers
    }

    private static func parse(_ hotkey: String) -> (modifiers: HotkeyModifiers, key: String)? {
        let parts = hotkey.lowercased().split(separator: "-").map(String.init)
        guard let key = parts.last, !key.isEmpty else { return nil }
        var modifiers: HotkeyModifiers = []
        for part in parts.dropLast() {
            switch part {
            case "cmd": modifiers.insert(.command)
            case "alt": modifiers.insert(.option)
            case "ctrl": modifiers.insert(.control)
            case "shift": modifiers.insert(.shift)
            default: return nil
            }
        }
        guard !["cmd", "alt", "ctrl", "shift"].contains(key) else { return nil }
        return (modifiers, key)
    }
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
