import Foundation
import Testing
@testable import GridSpacesCore

@Test func configPreparerPreservesExistingFile() throws {
    let directory = temporaryDirectory()
    let url = directory.appendingPathComponent("gridspaces.toml")
    let contents = Data("[grid]\nrows = [[\"W\"]]\n".utf8)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try contents.write(to: url)

    let preparedURL = try ConfigFilePreparer.prepare(at: url)

    #expect(preparedURL == url)
    #expect(try Data(contentsOf: url) == contents)
}

@Test func configPreparerCreatesMissingDirectoryAndFile() throws {
    let directory = temporaryDirectory()
    let url = directory.appendingPathComponent("nested/gridspaces.toml")

    try ConfigFilePreparer.prepare(at: url)

    #expect(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))
    #expect(FileManager.default.fileExists(atPath: url.path))
    #expect(try Data(contentsOf: url).isEmpty)
}

@Test func newlyPreparedEmptyConfigUsesBuiltInDefaults() throws {
    let url = temporaryDirectory().appendingPathComponent("gridspaces.toml")

    try ConfigFilePreparer.prepare(at: url)
    let result = ConfigLoader.load(from: url)

    #expect(result.config == .defaults)
    #expect(result.warnings.isEmpty)
}

@Test func configPreparerCreatesMissingFileInExistingDirectory() throws {
    let directory = temporaryDirectory()
    let url = directory.appendingPathComponent("gridspaces.toml")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    try ConfigFilePreparer.prepare(at: url)

    #expect(FileManager.default.fileExists(atPath: url.path))
    #expect(try Data(contentsOf: url).isEmpty)
}

@Test func configPreparerReportsFilesystemFailure() throws {
    let directory = temporaryDirectory()
    let blockingFile = directory.appendingPathComponent("not-a-directory")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("blocking".utf8).write(to: blockingFile)

    #expect(throws: (any Error).self) {
        try ConfigFilePreparer.prepare(
            at: blockingFile.appendingPathComponent("gridspaces.toml")
        )
    }
    #expect(try Data(contentsOf: blockingFile) == Data("blocking".utf8))
}

private func temporaryDirectory() -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
}
