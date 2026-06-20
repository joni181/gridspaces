import Testing
@testable import GridSpacesCore

@Test func commandCommaOpensConfigForFocusedPopup() {
    #expect(
        PopupShortcut.shouldOpenConfig(
            isPopupVisible: true,
            isPopupKey: true,
            charactersIgnoringModifiers: ",",
            modifiers: .command
        )
    )
}

@Test func commandCommaRequiresVisibleKeyPopup() {
    #expect(
        !PopupShortcut.shouldOpenConfig(
            isPopupVisible: false,
            isPopupKey: true,
            charactersIgnoringModifiers: ",",
            modifiers: .command
        )
    )
    #expect(
        !PopupShortcut.shouldOpenConfig(
            isPopupVisible: true,
            isPopupKey: false,
            charactersIgnoringModifiers: ",",
            modifiers: .command
        )
    )
}

@Test func commandCommaRejectsAdditionalModifiers() {
    #expect(
        !PopupShortcut.shouldOpenConfig(
            isPopupVisible: true,
            isPopupKey: true,
            charactersIgnoringModifiers: ",",
            modifiers: [.command, .shift]
        )
    )
    #expect(
        !PopupShortcut.shouldOpenConfig(
            isPopupVisible: true,
            isPopupKey: true,
            charactersIgnoringModifiers: ",",
            modifiers: [.command, .option]
        )
    )
}

@Test func openConfigShortcutDoesNotMatchOtherKeysOrUnmodifiedComma() {
    #expect(
        !PopupShortcut.shouldOpenConfig(
            isPopupVisible: true,
            isPopupKey: true,
            charactersIgnoringModifiers: ".",
            modifiers: .command
        )
    )
    #expect(
        !PopupShortcut.shouldOpenConfig(
            isPopupVisible: true,
            isPopupKey: true,
            charactersIgnoringModifiers: ",",
            modifiers: []
        )
    )
}
