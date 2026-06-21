import CoreFoundation
import Foundation
import GridSpacesCore

private var overlayCommandHandler: ((OverlayCommand) -> Void)?

private func overlayMessagePortCallback(
    _ local: CFMessagePort?,
    _ messageID: Int32,
    _ data: CFData?,
    _ info: UnsafeMutableRawPointer?
) -> Unmanaged<CFData>? {
    guard
        let data,
        let value = String(data: data as Data, encoding: .utf8),
        let command = OverlayCommand(rawValue: value)
    else {
        return nil
    }
    DispatchQueue.main.async {
        overlayCommandHandler?(command)
    }
    return nil
}

@MainActor
final class OverlayIPCReceiver {
    private var port: CFMessagePort?
    private var source: CFRunLoopSource?
    let isListening: Bool

    init(handler: @escaping (OverlayCommand) -> Void) {
        overlayCommandHandler = handler
        var shouldFreeInfo = DarwinBoolean(false)
        guard let port = CFMessagePortCreateLocal(
            nil,
            GridSpacesOverlayIPC.portName,
            overlayMessagePortCallback,
            nil,
            &shouldFreeInfo
        ) else {
            isListening = false
            return
        }
        self.port = port
        let source = CFMessagePortCreateRunLoopSource(nil, port, 0)
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        isListening = true
    }

    deinit {
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let port {
            CFMessagePortInvalidate(port)
        }
        overlayCommandHandler = nil
    }
}
