import Foundation

extension Data {
    func writeToTempDirectory(fileName: String) throws -> URL {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let targetURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        try write(to: targetURL)
        return targetURL
    }
}
