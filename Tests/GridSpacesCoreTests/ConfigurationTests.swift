import Foundation
import Testing
@testable import GridSpacesCore

@Test func missingFileUsesDefaults() {
    let url = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
    let result = ConfigLoader.load(from: url)

    #expect(result.config == .defaults)
    #expect(result.warnings.isEmpty)
}

@Test func overlayIPCCommandsUseStableWireValues() {
    #expect(OverlayCommand.ping.rawValue == "ping")
    #expect(OverlayCommand.show.rawValue == "show")
    #expect(OverlayCommand.hide.rawValue == "hide")
    #expect(OverlayCommand.reload.rawValue == "reload")
    #expect(OverlayCommand.shutdown.rawValue == "shutdown")
}

@Test func defaultGridUsesFullKeyboardLayout() {
    #expect(
        GridSpacesConfig.defaults.grid == [
            ["1", "2", "3", "4", "5"],
            ["Q", "W", "E", "R", "T"],
            ["A", "S", "D", "F", "G"],
            ["Y", "X", "C", "V", "B"],
        ]
    )
}

@Test func defaultAppearanceUsesExistingMonitorPalette() {
    #expect(
        Appearance.defaults.monitorColors == [
            "#32ADE6",
            "#FF9500",
            "#34C759",
            "#FF2D55",
            "#AF52DE",
            "#FFCC00",
        ]
    )
    #expect(Appearance.defaults.screenBorders)
    #expect(Appearance.defaults.screenBorderWidth == 5)
    #expect(Appearance.defaults.screenMinimumMonitors == 2)
    #expect(GridSpacesConfig.defaults.appearance == .defaults)
}

@Test func parsesGridKeysAndBehavior() throws {
    let url = try temporaryConfig(
        """
        [grid]
        rows = [["1", "", "3"], ["Q"]]

        [keys]
        a = 'left'
        c = 'close-all'

        [keys.workspaces]
        w = 'W'
        x = 'workspace-x'

        [behavior]
        wrap = true
        confirm_close_all = false
        move_mode = "cycle"
        monitor_wrap = true

        [appearance]
        monitor_colors = ["#112233", "#aBcDeF"]
        screen_borders = false
        screen_border_width = 9
        screen_minimum_monitors = 3
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.grid == [["1", nil, "3"], ["Q"]])
    #expect(result.config.keys.left == "a")
    #expect(result.config.keys.closeAll == "c")
    #expect(result.config.keys.right == "l")
    #expect(result.config.keys.workspaces == ["w": "W", "x": "workspace-x"])
    #expect(result.config.behavior.wrap)
    #expect(!result.config.behavior.confirmCloseAll)
    #expect(result.config.behavior.moveMode == .cycle)
    #expect(result.config.behavior.monitorWrap)
    #expect(result.config.appearance.monitorColors == ["#112233", "#ABCDEF"])
    #expect(!result.config.appearance.screenBorders)
    #expect(result.config.appearance.screenBorderWidth == 9)
    #expect(result.config.appearance.screenMinimumMonitors == 3)
    #expect(result.warnings.isEmpty)
}

@Test func omittedMonitorColorsUseDefaults() throws {
    let url = try temporaryConfig("[behavior]\nwrap = true")
    let result = ConfigLoader.load(from: url)

    #expect(result.config.appearance == .defaults)
    #expect(result.warnings.isEmpty)
}

@Test func emptyMonitorColorsFallBackToDefaults() throws {
    let url = try temporaryConfig(
        """
        [appearance]
        monitor_colors = []
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.appearance == .defaults)
    #expect(result.warnings.count == 1)
    #expect(result.warnings[0].contains("appearance.monitor_colors"))
}

@Test func malformedMonitorColorFallsBackToCompleteDefaultPalette() throws {
    let url = try temporaryConfig(
        """
        [appearance]
        monitor_colors = ["#112233", "#FFF", "orange"]
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.appearance == .defaults)
    #expect(result.warnings.count == 1)
    #expect(result.warnings[0].contains("#RRGGBB"))
}

@Test func screenOverlayAppearanceBoundariesAreAccepted() throws {
    let url = try temporaryConfig(
        """
        [appearance]
        screen_border_width = 1
        screen_minimum_monitors = 1
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.appearance.screenBorderWidth == 1)
    #expect(result.config.appearance.screenMinimumMonitors == 1)
    #expect(result.warnings.isEmpty)
}

@Test func invalidScreenOverlayNumbersFallBackIndependently() throws {
    let url = try temporaryConfig(
        """
        [appearance]
        monitor_colors = ["#112233"]
        screen_borders = false
        screen_border_width = 0
        screen_minimum_monitors = -1
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.appearance.monitorColors == ["#112233"])
    #expect(!result.config.appearance.screenBorders)
    #expect(result.config.appearance.screenBorderWidth == 5)
    #expect(result.config.appearance.screenMinimumMonitors == 2)
    #expect(result.warnings.count == 2)
    #expect(result.warnings.contains { $0.contains("screen_border_width") })
    #expect(result.warnings.contains { $0.contains("screen_minimum_monitors") })
}

@Test func invalidDocumentFallsBackToDefaults() throws {
    let url = try temporaryConfig("[grid\nbad")
    let result = ConfigLoader.load(from: url)

    #expect(result.config == .defaults)
    #expect(!result.warnings.isEmpty)
}

@Test func invalidIndividualSettingsKeepDefaults() throws {
    let url = try temporaryConfig(
        """
        [keys]
        shift-h = 'move-left'

        [behavior]
        move_mode = "teleport"
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.moveLeft == "shift-h")
    #expect(result.config.behavior.moveMode == .directional)
    #expect(result.warnings.count == 1)
}

@Test func plusSeparatorEmitsWarningAndIsSkipped() throws {
    let url = try temporaryConfig(
        """
        [keys]
        "shift+h" = 'move-left'
        j = 'down'
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.moveLeft == KeyBindings.defaults.moveLeft)
    #expect(result.config.keys.down == "j")
    #expect(result.warnings.count == 1)
    #expect(result.warnings[0].contains("shift+h"))
    #expect(result.warnings[0].contains("shift-h"))
}

@Test func unknownCommandEmitsWarning() throws {
    let url = try temporaryConfig(
        """
        [keys]
        h = 'teleport'
        j = 'down'
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.left == KeyBindings.defaults.left)
    #expect(result.config.keys.down == "j")
    #expect(result.warnings.count == 1)
    #expect(result.warnings[0].contains("teleport"))
}

@Test func duplicateHotkeyEmitsWarning() throws {
    // H and h normalize to the same hotkey; the second one (sorted) is a duplicate.
    let url = try temporaryConfig(
        """
        [keys]
        H = 'right'
        h = 'left'
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.right == "h" || result.config.keys.left == "h")
    #expect(result.warnings.count == 1)
    #expect(result.warnings[0].contains("duplicate"))
}

@Test func multiModifierHotkeyIsAccepted() throws {
    let url = try temporaryConfig(
        """
        [keys]
        ctrl-shift-j = 'move-down'
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.moveDown == "ctrl-shift-j")
    #expect(result.warnings.isEmpty)
}

@Test func workspaceBindingsAcceptModifierKeys() throws {
    let url = try temporaryConfig(
        """
        [keys.workspaces]
        w = 'W'
        shift-1 = 'workspace-1'
        x = ''
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.workspaces == ["w": "W", "shift-1": "workspace-1"])
    #expect(result.warnings.count == 1)
}

@Test func workspacePlusSeparatorEmitsWarning() throws {
    let url = try temporaryConfig(
        """
        [keys.workspaces]
        "shift+1" = 'workspace-1'
        w = 'W'
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.workspaces == ["w": "W"])
    #expect(result.warnings.count == 1)
    #expect(result.warnings[0].contains("shift+1"))
}

@Test func workspaceBindingsAreEmptyByDefault() {
    #expect(KeyBindings.defaults.workspaces.isEmpty)
    #expect(GridSpacesConfig.defaults.keys.workspaces.isEmpty)
}

@Test func exampleConfigLoadsCleanly() throws {
    // Resolve config/gridspaces.toml relative to the package root.
    let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let configURL = packageRoot.appendingPathComponent("config/gridspaces.toml")
    guard FileManager.default.fileExists(atPath: configURL.path) else { return }

    let result = ConfigLoader.load(from: configURL)

    #expect(result.warnings.isEmpty)
}

private func temporaryConfig(_ contents: String) throws -> URL {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )
    let url = directory.appendingPathComponent("gridspaces.toml")
    try Data(contents.utf8).write(to: url)
    return url
}
