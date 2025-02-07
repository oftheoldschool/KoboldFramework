import os
import Foundation
@_implementationOnly import KoboldLogging

public class KFileSystem {
    public func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask)
        return paths[0]
    }

    public func listDocumentsDirectory() -> [String] {
        do {
            let documentsDirectory = getDocumentsDirectory()
            return try FileManager.default.subpathsOfDirectory(atPath: documentsDirectory.path())
        } catch {
            kerror("Unable to list documents directory")
        }
        return []
    }

    public func readFileToString(filename: String) -> String? {
        do {
            let documentsDirectory = getDocumentsDirectory()
            let filePath = documentsDirectory.appendingPathComponent(filename)
            return try String(contentsOf: filePath)
        } catch {
            kerror("Unable to read file as string: \(filename) - \(error.localizedDescription)")
        }
        return nil
    }

    public func readFileToData(filename: String) -> Data? {
        do {
            let documentsDirectory = getDocumentsDirectory()
            let filePath = documentsDirectory.appendingPathComponent(filename)
            return try Data(contentsOf: filePath)
        } catch {
            kerror("Unable to read file as data: \(filename) - \(error.localizedDescription)")
        }
        return nil
    }

    public func createFileFromString(filename: String, _ body: () -> String) {
        do {
            let documentsDirectory = getDocumentsDirectory()
            let filePath = documentsDirectory.appendingPathComponent(filename)
            let str = body()
            try str.write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            kerror("Unable to create file from string: \(filename) - \(error.localizedDescription)")
        }
    }

    public func createFileFromData(filename: String, _ body: () -> Data) {
        do {
            let documentsDirectory = getDocumentsDirectory()
            let filePath = documentsDirectory.appendingPathComponent(filename)
            kinfo("using file path: \(filePath)")
            let data = body()
            try data.write(to: filePath)
        } catch {
            kerror("Unable to create file from data: \(filename) - \(error.localizedDescription)")
        }
    }

    public func fileExists(filename: String) -> Bool {
        let documentsDirectory = getDocumentsDirectory()
        let filePath = documentsDirectory.appendingPathComponent(filename).path(percentEncoded: false)
        return FileManager.default.fileExists(atPath: filePath)
    }

    public func deleteFile(filename: String) {
        let documentsDirectory = getDocumentsDirectory()
        let fileUrl = documentsDirectory.appendingPathComponent(filename)
        let filePath = fileUrl.path(percentEncoded: false)
        if FileManager.default.fileExists(atPath: filePath) && FileManager.default.isDeletableFile(atPath: filePath) {
            do {
                try FileManager.default.removeItem(at: fileUrl)
            } catch {
                kerror("Unable to delete file \(filename): \(error.localizedDescription)")
            }
        }
    }
}
