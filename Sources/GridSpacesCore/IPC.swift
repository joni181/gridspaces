import Foundation
import CoreFoundation

public enum AgentCommand: String, Sendable {
    case open
    case close
    case toggle
    case reloadConfig = "reload-config"
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
