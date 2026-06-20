import Darwin
import Foundation

public enum ConfigFilePreparer {
    @discardableResult
    public static func prepare(
        at url: URL = ConfigLoader.defaultURL,
        fileManager: FileManager = .default
    ) throws -> URL {
        let directory = url.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        try createFileIfMissing(at: url)

        return url
    }

    private static func createFileIfMissing(at url: URL) throws {
        let descriptor = url.withUnsafeFileSystemRepresentation { path -> Int32 in
            guard let path else {
                errno = EINVAL
                return -1
            }
            return Darwin.open(path, O_WRONLY | O_CREAT | O_EXCL, S_IRUSR | S_IWUSR)
        }

        if descriptor >= 0 {
            Darwin.close(descriptor)
            return
        }
        if errno == EEXIST {
            return
        }
        throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }
}
