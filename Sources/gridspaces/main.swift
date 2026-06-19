import AppKit
import Foundation
import GridSpacesCore

@main
enum GridSpacesCLI {
    static func main() {
        do {
            try run(Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data("gridspaces: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    private static func run(_ arguments: [String]) throws {
        guard let command = arguments.first else {
            throw GridSpacesError.invalidArguments(usage)
        }

        switch command {
        case "open", "toggle":
            try ensureAgentRunning()
            try sendWithRetry(command == "open" ? .open : .toggle)
        case "close":
            GridSpacesIPC.send(.close)
        case "reload-config":
            try ensureAgentRunning()
            try sendWithRetry(.reloadConfig)
            print("GridSpaces configuration reloaded.")
        case "focus":
            let direction = try parseDirection(arguments)
            try focus(direction: direction)
        case "--help", "-h", "help":
            print(usage)
        default:
            throw GridSpacesError.invalidArguments("Unknown command: \(command)\n\n\(usage)")
        }
    }

    private static func parseDirection(_ arguments: [String]) throws -> Direction {
        guard
            let flagIndex = arguments.firstIndex(of: "--direction"),
            arguments.indices.contains(flagIndex + 1),
            let direction = Direction(rawValue: arguments[flagIndex + 1])
        else {
            throw GridSpacesError.invalidArguments(
                "focus requires --direction <left|down|up|right>"
            )
        }
        return direction
    }

    private static func focus(direction: Direction) throws {
        let loaded = ConfigLoader.load()
        loaded.warnings.forEach {
            FileHandle.standardError.write(Data("gridspaces: warning: \($0)\n".utf8))
        }
        let client = try AeroSpaceClient()
        let snapshot = try client.snapshot()
        let model = GridModel(config: loaded.config, states: snapshot.workspaces)
        guard let destination = model.workspace(
            from: snapshot.focusedWorkspace,
            direction: direction,
            wrap: loaded.config.behavior.wrap,
            fallbackFromOverflow: true
        ), destination != snapshot.focusedWorkspace else {
            return
        }
        try client.focus(workspace: destination)
    }

    private static func ensureAgentRunning() throws {
        if !NSRunningApplication.runningApplications(
            withBundleIdentifier: "dev.gridspaces.agent"
        ).isEmpty {
            return
        }

        let executable = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
        let siblingAgent = executable.deletingLastPathComponent()
            .appendingPathComponent("GridSpacesAgent")
        let environmentPath = ProcessInfo.processInfo.environment["GRIDSPACES_APP"]
        let appCandidates = [
            environmentPath.map(URL.init(fileURLWithPath:)),
            URL(fileURLWithPath: "/Applications/GridSpaces.app"),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications/GridSpaces.app"),
            executable.deletingLastPathComponent().appendingPathComponent("GridSpaces.app"),
        ].compactMap { $0 }

        if let app = appCandidates.first(where: {
            FileManager.default.fileExists(atPath: $0.path)
        }) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-gj", app.path]
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 { return }
        }

        if FileManager.default.isExecutableFile(atPath: siblingAgent.path) {
            let process = Process()
            process.executableURL = siblingAgent
            try process.run()
            return
        }

        throw GridSpacesError.invalidArguments(
            "GridSpacesAgent could not be found. Run `./scripts/build.sh` or install GridSpaces.app."
        )
    }

    private static func sendWithRetry(_ command: AgentCommand) throws {
        for _ in 0..<20 {
            if GridSpacesIPC.send(command) {
                return
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        throw GridSpacesError.invalidArguments(
            "GridSpacesAgent started but its IPC endpoint did not become available."
        )
    }

    private static let usage = """
    Usage:
      gridspaces open
      gridspaces toggle
      gridspaces close
      gridspaces focus --direction <left|down|up|right>
      gridspaces reload-config
    """
}
