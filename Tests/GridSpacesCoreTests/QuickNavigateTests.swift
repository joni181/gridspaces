import Foundation
import Testing
@testable import GridSpacesCore

@Test func quickNavigateDefaultsUseCtrlAltShiftHJKL() {
    let keys = KeyBindings.defaults

    #expect(keys.quickNavigateHotkey(for: .left) == "ctrl-alt-shift-h")
    #expect(keys.quickNavigateHotkey(for: .down) == "ctrl-alt-shift-j")
    #expect(keys.quickNavigateHotkey(for: .up) == "ctrl-alt-shift-k")
    #expect(keys.quickNavigateHotkey(for: .right) == "ctrl-alt-shift-l")
    #expect(
        keys.quickNavigateModifiers(for: .left) == [.control, .option, .shift]
    )
}

@Test func parsesQuickNavigateBindings() throws {
    let url = try quickNavigateConfig(
        """
        [keys]
        cmd-left = 'quick-navigate left'
        cmd-down = 'quick-navigate down'
        cmd-up = 'quick-navigate up'
        cmd-right = 'quick-navigate right'
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.quickNavigateLeft == "cmd-left")
    #expect(result.config.keys.quickNavigateDown == "cmd-down")
    #expect(result.config.keys.quickNavigateUp == "cmd-up")
    #expect(result.config.keys.quickNavigateRight == "cmd-right")
    #expect(result.config.keys.quickNavigateModifiers(for: .up) == .command)
    #expect(result.warnings.isEmpty)
}

@Test func quickNavigateBindingsKeepDefaultsWhenUnset() throws {
    let url = try quickNavigateConfig(
        """
        [keys]
        h = 'left'
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.quickNavigateRight == KeyBindings.defaults.quickNavigateRight)
    #expect(result.warnings.isEmpty)
}

@Test func quickNavigateWithoutModifierWarns() throws {
    let url = try quickNavigateConfig(
        """
        [keys]
        n = 'quick-navigate right'
        """
    )
    let result = ConfigLoader.load(from: url)

    #expect(result.config.keys.quickNavigateRight == "n")
    #expect(result.config.keys.quickNavigateModifiers(for: .right) == nil)
    #expect(result.warnings.count == 1)
    #expect(result.warnings[0].contains("quick-navigate right"))
}

@Test func quickNavigateDirectionMatchesModifiersAndKeyInAnyOrder() throws {
    let url = try quickNavigateConfig(
        """
        [keys]
        shift-alt-ctrl-h = 'quick-navigate left'
        """
    )
    let keys = ConfigLoader.load(from: url).config.keys

    #expect(
        keys.quickNavigateDirection(
            modifiers: [.control, .option, .shift],
            key: "H"
        ) == .left
    )
    #expect(keys.quickNavigateDirection(modifiers: [.control, .option], key: "h") == nil)
    #expect(keys.quickNavigateDirection(modifiers: [.control, .option, .shift], key: "j") == .down)
}

@Test func hotkeyComponentsSplitModifiersFromKey() {
    let components = HotkeyModifiers.components(of: "Ctrl-Alt-Shift-L")

    #expect(components?.modifiers == [.control, .option, .shift])
    #expect(components?.key == "l")
    #expect(HotkeyModifiers.components(of: "h")?.modifiers == [])
    #expect(HotkeyModifiers.components(of: "hyper-h") == nil)
    #expect(HotkeyModifiers.components(of: "ctrl-shift") == nil)
}

@Test func quickNavigateAgentCommandsRoundTrip() {
    for direction in Direction.allCases {
        let command = AgentCommand.quickNavigate(direction)
        #expect(command.quickNavigateDirection == direction)
        #expect(AgentCommand(rawValue: command.rawValue) == command)
    }
    #expect(AgentCommand.open.quickNavigateDirection == nil)
    #expect(AgentCommand.quickNavigateLeft.rawValue == "quick-navigate left")
}

private func quickNavigateConfig(_ contents: String) throws -> URL {
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
