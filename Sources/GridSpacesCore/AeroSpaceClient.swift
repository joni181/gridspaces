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
        let focused = try focusedWorkspace()
        return try snapshot(focusedWorkspace: focused)
    }

    public func snapshot(focusedWorkspace focused: String) throws -> AeroSpaceSnapshot {
        let workspaceNames = try listWorkspaces()
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

    public func moveWindow(id: Int, to workspace: String) throws {
        _ = try run([
            "move-node-to-workspace",
            "--window-id", String(id),
            workspace,
        ])
    }

    public func exchangeWorkspaceContents(
        source: String,
        destination: String
    ) throws {
        let exchange = WorkspaceContentExchange(
            listWindows: { [self] workspace in
                try listWindows(workspace: workspace)
            },
            moveWindow: { [self] id, workspace in
                try moveWindow(id: id, to: workspace)
            }
        )
        try exchange.execute(source: source, destination: destination)
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

public struct WorkspaceContentExchange {
    public typealias ListWindows = (String) throws -> [WindowInfo]
    public typealias MoveWindow = (Int, String) throws -> Void

    private let listWindows: ListWindows
    private let moveWindow: MoveWindow

    public init(
        listWindows: @escaping ListWindows,
        moveWindow: @escaping MoveWindow
    ) {
        self.listWindows = listWindows
        self.moveWindow = moveWindow
    }

    public func execute(source: String, destination: String) throws {
        let sourceWindows = try listWindows(source)
        let destinationWindows = try listWindows(destination)

        do {
            for window in sourceWindows {
                try moveIfPresent(
                    window.id,
                    to: destination,
                    source: source,
                    destination: destination
                )
            }
            for window in destinationWindows {
                try moveIfPresent(
                    window.id,
                    to: source,
                    source: source,
                    destination: destination
                )
            }
            try verify(
                sourceIDs: Set(sourceWindows.map(\.id)),
                destinationIDs: Set(destinationWindows.map(\.id)),
                source: source,
                destination: destination
            )
        } catch {
            rollback(
                sourceWindows: sourceWindows,
                destinationWindows: destinationWindows,
                source: source,
                destination: destination
            )
            throw error
        }
    }

    private func moveIfPresent(
        _ id: Int,
        to workspace: String,
        source: String,
        destination: String
    ) throws {
        do {
            try moveWindow(id, workspace)
        } catch {
            let existingIDs = try currentIDs(source: source, destination: destination)
            if existingIDs.contains(id) {
                throw error
            }
        }
    }

    private func verify(
        sourceIDs: Set<Int>,
        destinationIDs: Set<Int>,
        source: String,
        destination: String
    ) throws {
        let currentSource = Set(try listWindows(source).map(\.id))
        let currentDestination = Set(try listWindows(destination).map(\.id))
        let surviving = currentSource.union(currentDestination)
        let misplacedSource = sourceIDs.intersection(surviving).subtracting(currentDestination)
        let misplacedDestination = destinationIDs.intersection(surviving).subtracting(currentSource)
        guard misplacedSource.isEmpty, misplacedDestination.isEmpty else {
            throw GridSpacesError.invalidOutput(
                command: "workspace-content exchange",
                message: "AeroSpace did not assign every moved window to the expected workspace"
            )
        }
    }

    private func currentIDs(source: String, destination: String) throws -> Set<Int> {
        Set(try listWindows(source).map(\.id))
            .union(try listWindows(destination).map(\.id))
    }

    private func rollback(
        sourceWindows: [WindowInfo],
        destinationWindows: [WindowInfo],
        source: String,
        destination: String
    ) {
        for window in sourceWindows {
            try? moveWindow(window.id, source)
        }
        for window in destinationWindows {
            try? moveWindow(window.id, destination)
        }
    }
}
