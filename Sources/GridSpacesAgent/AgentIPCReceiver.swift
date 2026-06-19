import CoreFoundation
import Foundation
import GridSpacesCore

private var commandHandler: ((AgentCommand) -> Void)?

private func messagePortCallback(
    _ local: CFMessagePort?,
    _ messageID: Int32,
    _ data: CFData?,
    _ info: UnsafeMutableRawPointer?
) -> Unmanaged<CFData>? {
    guard
        let data,
        let value = String(data: data as Data, encoding: .utf8),
        let command = AgentCommand(rawValue: value)
    else {
        return nil
    }
    DispatchQueue.main.async {
        commandHandler?(command)
    }
    return nil
}

@MainActor
final class AgentIPCReceiver {
    private var port: CFMessagePort?
    private var source: CFRunLoopSource?

    init(handler: @escaping (AgentCommand) -> Void) {
        commandHandler = handler
        var shouldFreeInfo = DarwinBoolean(false)
        guard let port = CFMessagePortCreateLocal(
            nil,
            GridSpacesIPC.portName,
            messagePortCallback,
            nil,
            &shouldFreeInfo
        ) else {
            return
        }
        self.port = port
        let source = CFMessagePortCreateRunLoopSource(nil, port, 0)
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    deinit {
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let port {
            CFMessagePortInvalidate(port)
        }
        commandHandler = nil
    }
}
