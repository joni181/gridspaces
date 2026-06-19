import Foundation

public final class AeroSpaceClient {
    public let executableURL: URL

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) throws {
        guard let executableURL = Self.findExecutable(environment: environment) else {
            throw GridSpacesError.aerospaceNotFound
        }
        self.executableURL = executableURL
    }

    public static func findExecutable(environment: [String: String]) -> URL? {
        let fileManager = FileManager.default
        let candidates = (environment["PATH"] ?? "")
            .split(separator: ":")
            .map { URL(fileURLWithPath: String($0)).appendingPathComponent("aerospace") }
            + [
                URL(fileURLWithPath: "/opt/homebrew/bin/aerospace"),
                URL(fileURLWithPath: "/usr/local/bin/aerospace"),
                URL(fileURLWithPath: "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"),
            ]
        return candidates.first { fileManager.isExecutableFile(atPath: $0.path) }
    }

    public func snapshot() throws -> AeroSpaceSnapshot {
        let workspaceNames = try listWorkspaces()
        let focused = try focusedWorkspace()
        let monitors = try listMonitors()
        let monitorMapping = try workspaceMonitorMapping()

        let states = try workspaceNames.map { name in
            WorkspaceState(
                name: name,
                windows: try listWindows(workspace: name),
                monitorID: monitorMapping[name]
            )
        }
        return AeroSpaceSnapshot(workspaces: states, focusedWorkspace: focused, monitors: monitors)
    }

    public func listWorkspaces() throws -> [String] {
        try run(["list-workspaces", "--all"])
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    public func focusedWorkspace() throws -> String {
        let value = try run(["list-workspaces", "--focused"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            throw GridSpacesError.invalidOutput(
                command: "list-workspaces --focused",
                message: "no focused workspace was returned"
            )
        }
        return value
    }

    public func listWindows(workspace: String) throws -> [WindowInfo] {
        let data = try runData(["list-windows", "--workspace", workspace, "--json"])
        do {
            return try JSONDecoder().decode([WindowInfo].self, from: data)
        } catch {
            throw GridSpacesError.invalidOutput(
                command: "list-windows --workspace \(workspace) --json",
                message: error.localizedDescription
            )
        }
    }

    public func listMonitors() throws -> [MonitorInfo] {
        let data = try runData(["list-monitors", "--json"])
        do {
            return try JSONDecoder().decode([MonitorInfo].self, from: data)
        } catch {
            throw GridSpacesError.invalidOutput(
                command: "list-monitors --json",
                message: error.localizedDescription
            )
        }
    }

    public func workspaceMonitorMapping() throws -> [String: Int] {
        let output = try run([
            "list-workspaces", "--all",
            "--format", "%{workspace}|%{monitor-id}",
        ])
        var result: [String: Int] = [:]
        for line in output.split(whereSeparator: \.isNewline) {
            let fields = line.split(separator: "|", maxSplits: 1).map(String.init)
            if fields.count == 2, let id = Int(fields[1]) {
                result[fields[0]] = id
            }
        }
        return result
    }

    public func focus(workspace: String) throws {
        _ = try run(["workspace", workspace])
    }

    public func closeAllWindows(workspace: String) throws {
        for window in try listWindows(workspace: workspace) {
            _ = try run(["close", "--window-id", String(window.id)])
        }
    }

    public func moveWorkspace(
        _ workspace: String,
        target: String,
        wrap: Bool,
        monitorCount: Int
    ) throws {
        guard monitorCount > 1 else { return }
        var arguments = ["move-workspace-to-monitor", "--workspace", workspace]
        if wrap {
            arguments.append("--wrap-around")
        }
        arguments.append(target)
        do {
            _ = try run(arguments)
        } catch let error as GridSpacesError {
            if !wrap, case .commandFailed = error {
                return
            }
            throw error
        }
    }

    @discardableResult
    public func run(_ arguments: [String]) throws -> String {
        String(decoding: try runData(arguments), as: UTF8.self)
    }

    private func runData(_ arguments: [String]) throws -> Data {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw GridSpacesError.commandFailed(
                command: arguments.joined(separator: " "),
                message: error.localizedDescription
            )
        }
        process.waitUntilExit()
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = stderr.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            throw GridSpacesError.commandFailed(
                command: arguments.joined(separator: " "),
                message: String(decoding: errorOutput, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return output
    }
}
