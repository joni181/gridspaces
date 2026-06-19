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

@Test func parsesGridKeysAndBehavior() throws {
    let url = try temporaryConfig(
        """
        [grid]
        rows = [["1", "", "3"], ["Q"]]

        [keys]
        left = "a"
        close_all = "c"

        [behavior]
        wrap = true
        confirm_close_all = false
        move_mode = "cycle"
        monitor_wrap = true
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.grid == [["1", nil, "3"], ["Q"]])
    #expect(result.config.keys.left == "a")
    #expect(result.config.keys.closeAll == "c")
    #expect(result.config.keys.right == "l")
    #expect(result.config.behavior.wrap)
    #expect(!result.config.behavior.confirmCloseAll)
    #expect(result.config.behavior.moveMode == .cycle)
    #expect(result.config.behavior.monitorWrap)
    #expect(result.warnings.isEmpty)
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
        left = ""

        [behavior]
        move_mode = "teleport"
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.left == KeyBindings.defaults.left)
    #expect(result.config.behavior.moveMode == .directional)
    #expect(result.warnings.count == 2)
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
