import Foundation
import CoreFoundation

public enum AgentCommand: String, Sendable {
    case open
    case close
    case toggle
    case reloadConfig = "reload-config"
    case quickNavigateLeft = "quick-navigate left"
    case quickNavigateDown = "quick-navigate down"
    case quickNavigateUp = "quick-navigate up"
    case quickNavigateRight = "quick-navigate right"

    public static func quickNavigate(_ direction: Direction) -> AgentCommand {
        switch direction {
        case .left: return .quickNavigateLeft
        case .down: return .quickNavigateDown
        case .up: return .quickNavigateUp
        case .right: return .quickNavigateRight
        }
    }

    public var quickNavigateDirection: Direction? {
        switch self {
        case .quickNavigateLeft: return .left
        case .quickNavigateDown: return .down
        case .quickNavigateUp: return .up
        case .quickNavigateRight: return .right
        case .open, .close, .toggle, .reloadConfig: return nil
        }
    }
}

public enum GridSpacesIPC {
    public static let notificationName = Notification.Name("dev.gridspaces.command")
    public static let commandKey = "command"
    public static let portName = "dev.gridspaces.agent.ipc" as CFString

    @discardableResult
    public static func send(_ command: AgentCommand) -> Bool {
        if let port = CFMessagePortCreateRemote(nil, portName) {
            let data = Data(command.rawValue.utf8) as CFData
            let status = CFMessagePortSendRequest(
                port,
                1,
                data,
                1,
                1,
                nil,
                nil
            )
            if status == kCFMessagePortSuccess {
                return true
            }
        }

        DistributedNotificationCenter.default().postNotificationName(
            notificationName,
            object: command.rawValue,
            userInfo: nil,
            deliverImmediately: true
        )
        return false
    }
}
