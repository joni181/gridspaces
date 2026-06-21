import CoreFoundation
import Foundation

public enum OverlayCommand: String, Sendable {
    case ping
    case show
    case hide
    case reload
    case shutdown
}

public enum GridSpacesOverlayIPC {
    public static let notificationName = Notification.Name("dev.gridspaces.overlay.command")
    public static let portName = "dev.gridspaces.overlay.ipc" as CFString

    @discardableResult
    public static func sendToPort(_ command: OverlayCommand) -> Bool {
        if let port = CFMessagePortCreateRemote(nil, portName) {
            let data = Data(command.rawValue.utf8) as CFData
            let status = CFMessagePortSendRequest(
                port,
                1,
                data,
                0.2,
                0.2,
                nil,
                nil
            )
            if status == kCFMessagePortSuccess {
                return true
            }
        }
        return false
    }

    public static func post(_ command: OverlayCommand) {
        DistributedNotificationCenter.default().postNotificationName(
            notificationName,
            object: command.rawValue,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    @discardableResult
    public static func send(_ command: OverlayCommand) -> Bool {
        if sendToPort(command) {
            return true
        }
        post(command)
        return false
    }
}
