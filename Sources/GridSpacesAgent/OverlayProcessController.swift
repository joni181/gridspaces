import Foundation
import GridSpacesCore

@MainActor
final class OverlayProcessController {
    private var process: Process?
    private let commandQueue = DispatchQueue(label: "dev.gridspaces.overlay.commands")

    func start() {
        if GridSpacesOverlayIPC.sendToPort(.ping) {
            return
        }
        guard process?.isRunning != true else { return }
        guard let executableURL = helperExecutableURL() else { return }

        let process = Process()
        process.executableURL = executableURL
        do {
            try process.run()
            self.process = process
        } catch {
            self.process = nil
        }
    }

    func send(_ command: OverlayCommand) {
        start()
        commandQueue.async {
            for _ in 0..<20 {
                if GridSpacesOverlayIPC.sendToPort(command) {
                    return
                }
                Thread.sleep(forTimeInterval: 0.025)
            }
            GridSpacesOverlayIPC.post(command)
        }
    }

    func shutdown() {
        let delivered = commandQueue.sync {
            GridSpacesOverlayIPC.sendToPort(.shutdown)
        }
        if !delivered, process?.isRunning == true {
            process?.terminate()
        }
        process = nil
    }

    private func helperExecutableURL() -> URL? {
        guard let executableURL = Bundle.main.executableURL else { return nil }
        let helperURL = executableURL.deletingLastPathComponent()
            .appendingPathComponent("GridSpacesOverlayAgent")
        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            return nil
        }
        return helperURL
    }
}
