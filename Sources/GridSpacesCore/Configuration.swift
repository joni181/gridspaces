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
    public var moveWorkspaceLeft: String
    public var moveWorkspaceDown: String
    public var moveWorkspaceUp: String
    public var moveWorkspaceRight: String
    public var moveToDisplayLeft: String
    public var moveToDisplayDown: String
    public var moveToDisplayUp: String
    public var moveToDisplayRight: String
    public var moveToDisplayNext: String
    public var moveToDisplayPrevious: String
    public var workspaces: [String: String]

    enum CodingKeys: String, CodingKey {
        case left, down, up, right, confirm, cancel
        case closeAll = "close_all"
        case moveWorkspaceLeft = "move_workspace_left"
        case moveWorkspaceDown = "move_workspace_down"
        case moveWorkspaceUp = "move_workspace_up"
        case moveWorkspaceRight = "move_workspace_right"
        case moveToDisplayLeft = "move_to_display_left"
        case moveToDisplayDown = "move_to_display_down"
        case moveToDisplayUp = "move_to_display_up"
        case moveToDisplayRight = "move_to_display_right"
        case moveToDisplayNext = "move_to_display_next"
        case moveToDisplayPrevious = "move_to_display_previous"
        case workspaces
    }

    public static let defaults = KeyBindings(
        left: "h", down: "j", up: "k", right: "l",
        confirm: "return", cancel: "escape", closeAll: "x",
        moveWorkspaceLeft: "alt-h", moveWorkspaceDown: "alt-j",
        moveWorkspaceUp: "alt-k", moveWorkspaceRight: "alt-l",
        moveToDisplayLeft: "shift-h", moveToDisplayDown: "shift-j",
        moveToDisplayUp: "shift-k", moveToDisplayRight: "shift-l",
        moveToDisplayNext: "shift-l", moveToDisplayPrevious: "shift-h",
        workspaces: [:]
    )

    public var workspaceMovementHotkeys: [String] {
        [
            moveWorkspaceLeft,
            moveWorkspaceDown,
            moveWorkspaceUp,
            moveWorkspaceRight,
        ]
    }
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

public struct Appearance: Codable, Equatable, Sendable {
    public var monitorColors: [String]

    public init(monitorColors: [String]) {
        self.monitorColors = monitorColors
    }

    enum CodingKeys: String, CodingKey {
        case monitorColors = "monitor_colors"
    }

    public static let defaults = Appearance(
        monitorColors: [
            "#32ADE6",
            "#FF9500",
            "#34C759",
            "#FF2D55",
            "#AF52DE",
            "#FFCC00",
        ]
    )
}

public struct GridSpacesConfig: Equatable, Sendable {
    public var grid: [[String?]]
    public var keys: KeyBindings
    public var behavior: Behavior
    public var appearance: Appearance

    public init(
        grid: [[String?]],
        keys: KeyBindings = .defaults,
        behavior: Behavior = .defaults,
        appearance: Appearance = .defaults
    ) {
        self.grid = grid
        self.keys = keys
        self.behavior = behavior
        self.appearance = appearance
    }

    public static let defaults = GridSpacesConfig(
        grid: [
            ["1", "2", "3", "4", "5"],
            ["Q", "W", "E", "R", "T"],
            ["A", "S", "D", "F", "G"],
            ["Y", "X", "C", "V", "B"],
        ]
    )
}

private struct ConfigDocument: Decodable {
    var grid: GridDocument?
    var keys: PartialKeySection?
    var behavior: PartialBehavior?
    var appearance: PartialAppearance?
}

private struct GridDocument: Decodable {
    var rows: [[String?]]?
}

// Decodes the [keys] table: free-form hotkey→command bindings plus the [keys.workspaces] subtable.
private struct PartialKeySection: Decodable {
    var bindings: [String: String]
    var workspaces: [String: String]?

    private struct AnyCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        workspaces = try container.decodeIfPresent(
            [String: String].self,
            forKey: AnyCodingKey(stringValue: "workspaces")
        )
        var bindings: [String: String] = [:]
        for key in container.allKeys where key.stringValue != "workspaces" {
            if let value = try? container.decode(String.self, forKey: key) {
                bindings[key.stringValue] = value
            }
        }
        self.bindings = bindings
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

private struct PartialAppearance: Decodable {
    var monitorColors: [String]?

    enum CodingKeys: String, CodingKey {
        case monitorColors = "monitor_colors"
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

    private static let commandToKeyPath: [String: WritableKeyPath<KeyBindings, String>] = [
        "left": \.left,
        "down": \.down,
        "up": \.up,
        "right": \.right,
        "confirm": \.confirm,
        "cancel": \.cancel,
        "close-all": \.closeAll,
        "move-workspace left": \.moveWorkspaceLeft,
        "move-workspace down": \.moveWorkspaceDown,
        "move-workspace up": \.moveWorkspaceUp,
        "move-workspace right": \.moveWorkspaceRight,
        "move-to-display left": \.moveToDisplayLeft,
        "move-to-display down": \.moveToDisplayDown,
        "move-to-display up": \.moveToDisplayUp,
        "move-to-display right": \.moveToDisplayRight,
        "move-to-display next": \.moveToDisplayNext,
        "move-to-display previous": \.moveToDisplayPrevious,
    ]

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

        if let section = document.keys {
            var merged = KeyBindings.defaults
            var seenHotkeys: Set<String> = []

            for hotkey in section.bindings.keys.sorted() {
                guard let command = section.bindings[hotkey] else { continue }
                let normalizedHotkey = hotkey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let normalizedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                if normalizedHotkey.isEmpty {
                    warnings.append("[keys]: hotkey cannot be empty; ignoring command '\(command)'.")
                    continue
                }
                if normalizedHotkey.contains("+") {
                    let corrected = normalizedHotkey.replacingOccurrences(of: "+", with: "-")
                    warnings.append("[keys] '\(hotkey)': use '-' as modifier separator (e.g. '\(corrected)').")
                    continue
                }
                if seenHotkeys.contains(normalizedHotkey) {
                    warnings.append("[keys] '\(hotkey)': duplicate hotkey; ignoring.")
                    continue
                }
                guard let keyPath = commandToKeyPath[normalizedCommand] else {
                    warnings.append("[keys] '\(hotkey)': unknown command '\(command)'; ignoring.")
                    continue
                }

                seenHotkeys.insert(normalizedHotkey)
                merged[keyPath: keyPath] = normalizedHotkey
            }

            if let workspaces = section.workspaces {
                merged.workspaces = normalizeWorkspaceBindings(workspaces, warnings: &warnings)
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

        if let monitorColors = document.appearance?.monitorColors {
            if let normalized = normalizeMonitorColors(monitorColors) {
                result.appearance.monitorColors = normalized
            } else {
                warnings.append(
                    "appearance.monitor_colors must contain at least one color, "
                        + "with every color in #RRGGBB format; using the default monitor colors."
                )
            }
        }

        return ConfigLoadResult(config: result, warnings: warnings)
    }

    private static func normalizeMonitorColors(_ colors: [String]) -> [String]? {
        guard !colors.isEmpty else { return nil }

        var normalized: [String] = []
        normalized.reserveCapacity(colors.count)
        for color in colors {
            let trimmed = color.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count == 7, trimmed.first == "#" else { return nil }
            let digits = trimmed.dropFirst()
            guard digits.allSatisfy(\.isHexDigit) else { return nil }
            normalized.append(trimmed.uppercased())
        }
        return normalized
    }

    private static func normalizeWorkspaceBindings(
        _ bindings: [String: String],
        warnings: inout [String]
    ) -> [String: String] {
        var normalized: [String: String] = [:]
        var seenHotkeys: Set<String> = []

        for key in bindings.keys.sorted() {
            guard let workspace = bindings[key] else { continue }
            let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let normalizedWorkspace = workspace.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !normalizedKey.isEmpty else {
                warnings.append("keys.workspaces: hotkey cannot be empty; ignoring.")
                continue
            }
            if normalizedKey.contains("+") {
                let corrected = normalizedKey.replacingOccurrences(of: "+", with: "-")
                warnings.append("[keys.workspaces] '\(key)': use '-' as modifier separator (e.g. '\(corrected)').")
                continue
            }
            guard !normalizedWorkspace.isEmpty else {
                warnings.append("keys.workspaces '\(key)' must name a workspace; ignoring it.")
                continue
            }
            guard !seenHotkeys.contains(normalizedKey) else {
                warnings.append("[keys.workspaces] '\(key)': duplicate hotkey; ignoring.")
                continue
            }

            seenHotkeys.insert(normalizedKey)
            normalized[normalizedKey] = normalizedWorkspace
        }

        return normalized
    }
}
