import Foundation

public struct PopupModifier: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let command = PopupModifier(rawValue: 1 << 0)
    public static let option = PopupModifier(rawValue: 1 << 1)
    public static let control = PopupModifier(rawValue: 1 << 2)
    public static let shift = PopupModifier(rawValue: 1 << 3)
    public static let function = PopupModifier(rawValue: 1 << 4)
}

public enum PopupShortcut {
    public static func shouldOpenConfig(
        isPopupVisible: Bool,
        isPopupKey: Bool,
        charactersIgnoringModifiers: String?,
        modifiers: PopupModifier
    ) -> Bool {
        isPopupVisible
            && isPopupKey
            && charactersIgnoringModifiers == ","
            && modifiers == .command
    }
}
