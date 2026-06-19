import Foundation
import TOMLDecoder

public struct KeyBindings: Codable, Equatable, Sendable {
    public var left: String
    public var down: String
    public var up: String
    public var right: String
    public var confirm: String
    public var cancel: String
    public var closeAll: String
    public var moveLeft: String
    public var moveDown: String
    public var moveUp: String
    public var moveRight: String
    public var moveNext: String
    public var movePrevious: String
    public var workspaces: [String: String]

    enum CodingKeys: String, CodingKey {
        case left, down, up, right, confirm, cancel
        case closeAll = "close_all"
        case moveLeft = "move_left"
        case moveDown = "move_down"
        case moveUp = "move_up"
        case moveRight = "move_right"
        case moveNext = "move_next"
        case movePrevious = "move_previous"
        case workspaces
    }

    public static let defaults = KeyBindings(
        left: "h", down: "j", up: "k", right: "l",
        confirm: "return", cancel: "escape", closeAll: "x",
        moveLeft: "shift+h", moveDown: "shift+j", moveUp: "shift+k", moveRight: "shift+l",
        moveNext: "shift+l", movePrevious: "shift+h",
        workspaces: [:]
    )
}

public struct Behavior: Codable, Equatable, Sendable {
    public var wrap: Bool
    public var confirmCloseAll: Bool
    public var moveMode: MoveMode
    public var monitorWrap: Bool

    enum CodingKeys: String, CodingKey {
        case wrap
        case confirmCloseAll = "confirm_close_all"
        case moveMode = "move_mode"
        case monitorWrap = "monitor_wrap"
    }

    public static let defaults = Behavior(
        wrap: false,
        confirmCloseAll: true,
        moveMode: .directional,
        monitorWrap: false
    )
}

public struct GridSpacesConfig: Equatable, Sendable {
    public var grid: [[String?]]
    public var keys: KeyBindings
    public var behavior: Behavior

    public init(grid: [[String?]], keys: KeyBindings = .defaults, behavior: Behavior = .defaults) {
        self.grid = grid
        self.keys = keys
        self.behavior = behavior
    }

    public static let defaults = GridSpacesConfig(
        grid: [
            ["1", "2", "3", "4", "5"],
            ["Q", "W", "E"],
            ["A", "S", "D"],
        ]
    )
}

private struct ConfigDocument: Decodable {
    var grid: GridDocument?
    var keys: PartialKeyBindings?
    var behavior: PartialBehavior?
}

private struct GridDocument: Decodable {
    var rows: [[String?]]?
}

private struct PartialKeyBindings: Decodable {
    var left: String?
    var down: String?
    var up: String?
    var right: String?
    var confirm: String?
    var cancel: String?
    var closeAll: String?
    var moveLeft: String?
    var moveDown: String?
    var moveUp: String?
    var moveRight: String?
    var moveNext: String?
    var movePrevious: String?
    var workspaces: [String: String]?

    enum CodingKeys: String, CodingKey {
        case left, down, up, right, confirm, cancel
        case closeAll = "close_all"
        case moveLeft = "move_left"
        case moveDown = "move_down"
        case moveUp = "move_up"
        case moveRight = "move_right"
        case moveNext = "move_next"
        case movePrevious = "move_previous"
        case workspaces
    }
}

private struct PartialBehavior: Decodable {
    var wrap: Bool?
    var confirmCloseAll: Bool?
    var moveMode: String?
    var monitorWrap: Bool?

    enum CodingKeys: String, CodingKey {
        case wrap
        case confirmCloseAll = "confirm_close_all"
        case moveMode = "move_mode"
        case monitorWrap = "monitor_wrap"
    }
}

public struct ConfigLoadResult: Sendable {
    public let config: GridSpacesConfig
    public let warnings: [String]

    public init(config: GridSpacesConfig, warnings: [String]) {
        self.config = config
        self.warnings = warnings
    }
}

public enum ConfigLoader {
    public static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/gridspaces/gridspaces.toml")
    }

    public static func load(from url: URL = defaultURL) -> ConfigLoadResult {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ConfigLoadResult(config: .defaults, warnings: [])
        }

        do {
            let data = try Data(contentsOf: url)
            let document = try TOMLDecoder().decode(ConfigDocument.self, from: data)
            return merge(document)
        } catch {
            return ConfigLoadResult(
                config: .defaults,
                warnings: ["Invalid configuration at \(url.path): \(error.localizedDescription). Using built-in defaults."]
            )
        }
    }

    private static func merge(_ document: ConfigDocument) -> ConfigLoadResult {
        var result = GridSpacesConfig.defaults
        var warnings: [String] = []

        if let rows = document.grid?.rows {
            let normalized: [[String?]] = rows.map { row in row.map { value -> String? in
                guard let value else { return nil }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }}
            let names = normalized.flatMap { $0.compactMap { $0 } }
            if normalized.isEmpty || names.isEmpty {
                warnings.append("grid.rows must contain at least one workspace; using the default grid.")
            } else if Set(names).count != names.count {
                warnings.append("grid.rows contains duplicate workspace names; using the default grid.")
            } else {
                result.grid = normalized
            }
        }

        if let keys = document.keys {
            var merged = KeyBindings.defaults
            assign(keys.left, to: &merged.left, name: "keys.left", warnings: &warnings)
            assign(keys.down, to: &merged.down, name: "keys.down", warnings: &warnings)
            assign(keys.up, to: &merged.up, name: "keys.up", warnings: &warnings)
            assign(keys.right, to: &merged.right, name: "keys.right", warnings: &warnings)
            assign(keys.confirm, to: &merged.confirm, name: "keys.confirm", warnings: &warnings)
            assign(keys.cancel, to: &merged.cancel, name: "keys.cancel", warnings: &warnings)
            assign(keys.closeAll, to: &merged.closeAll, name: "keys.close_all", warnings: &warnings)
            assign(keys.moveLeft, to: &merged.moveLeft, name: "keys.move_left", warnings: &warnings)
            assign(keys.moveDown, to: &merged.moveDown, name: "keys.move_down", warnings: &warnings)
            assign(keys.moveUp, to: &merged.moveUp, name: "keys.move_up", warnings: &warnings)
            assign(keys.moveRight, to: &merged.moveRight, name: "keys.move_right", warnings: &warnings)
            assign(keys.moveNext, to: &merged.moveNext, name: "keys.move_next", warnings: &warnings)
            assign(keys.movePrevious, to: &merged.movePrevious, name: "keys.move_previous", warnings: &warnings)
            if let workspaces = keys.workspaces {
                merged.workspaces = normalizeWorkspaceBindings(
                    workspaces,
                    warnings: &warnings
                )
            }
            result.keys = merged
        }

        if let behavior = document.behavior {
            result.behavior.wrap = behavior.wrap ?? result.behavior.wrap
            result.behavior.confirmCloseAll = behavior.confirmCloseAll ?? result.behavior.confirmCloseAll
            result.behavior.monitorWrap = behavior.monitorWrap ?? result.behavior.monitorWrap
            if let mode = behavior.moveMode {
                if let parsed = MoveMode(rawValue: mode.lowercased()) {
                    result.behavior.moveMode = parsed
                } else {
                    warnings.append("behavior.move_mode must be \"directional\" or \"cycle\"; using directional.")
                }
            }
        }

        return ConfigLoadResult(config: result, warnings: warnings)
    }

    private static func assign(
        _ candidate: String?,
        to value: inout String,
        name: String,
        warnings: inout [String]
    ) {
        guard let candidate else { return }
        let normalized = candidate.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty {
            warnings.append("\(name) cannot be empty; using \(value).")
        } else {
            value = normalized
        }
    }

    private static func normalizeWorkspaceBindings(
        _ bindings: [String: String],
        warnings: inout [String]
    ) -> [String: String] {
        var normalized: [String: String] = [:]

        for key in bindings.keys.sorted() {
            guard let workspace = bindings[key] else { continue }
            let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let normalizedWorkspace = workspace.trimmingCharacters(in: .whitespacesAndNewlines)

            guard normalizedKey.count == 1 else {
                warnings.append("keys.workspaces.\(key) must be a single character; ignoring it.")
                continue
            }
            guard !normalizedWorkspace.isEmpty else {
                warnings.append("keys.workspaces.\(key) must name a workspace; ignoring it.")
                continue
            }
            guard normalized[normalizedKey] == nil else {
                warnings.append(
                    "keys.workspaces contains duplicate case-insensitive key \(key); ignoring it."
                )
                continue
            }

            normalized[normalizedKey] = normalizedWorkspace
        }

        return normalized
    }
}
