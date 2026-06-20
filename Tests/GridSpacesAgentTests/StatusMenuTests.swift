import AppKit
import Testing
@testable import GridSpacesAgent

@MainActor
@Test func statusMenuContainsExpectedActionsAndShortcuts() {
    let menu = AppDelegate().makeStatusMenu()

    #expect(menu.items.count == 5)
    #expect(menu.items[0].title == "Open GridSpaces")
    #expect(menu.items[0].keyEquivalent.isEmpty)

    #expect(menu.items[1].title == "Reload Configuration")
    #expect(menu.items[1].keyEquivalent == "r")
    #expect(menu.items[1].keyEquivalentModifierMask == .command)

    #expect(menu.items[2].title == "Open Config")
    #expect(menu.items[2].keyEquivalent == ",")
    #expect(menu.items[2].keyEquivalentModifierMask == .command)

    #expect(menu.items[3].isSeparatorItem)

    #expect(menu.items[4].title == "Quit GridSpaces")
    #expect(menu.items[4].keyEquivalent == "q")
    #expect(menu.items[4].keyEquivalentModifierMask == .command)
}

@MainActor
@Test func statusMenuItemsTargetTheApplicationDelegate() {
    let appDelegate = AppDelegate()
    let menu = appDelegate.makeStatusMenu()

    for item in menu.items where !item.isSeparatorItem {
        #expect(item.target === appDelegate)
        #expect(item.action != nil)
    }
}
