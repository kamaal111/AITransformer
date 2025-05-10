//
//  FileSystem.swift
//  FileSystem
//
//  Created by Kamaal M Farah on 5/6/25.
//

import Cocoa
import Foundation

public enum FileSystemGetDirectoryInfoErrors: Error {
    case notADirectory
    case doesNotExist
    case generalError(cause: Error)
}

public struct FileSystemOpenFilePickerConfig {
    public let allowsMultipleSelection: Bool
    public let canChooseDirectories: Bool

    public init(allowsMultipleSelection: Bool = false, canChooseDirectories: Bool = false) {
        self.allowsMultipleSelection = allowsMultipleSelection
        self.canChooseDirectories = canChooseDirectories
    }
}

public actor FileSystem: Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    public init() {
        self.init(fileManager: .default)
    }

    @MainActor
    public func openFilePicker(config: FileSystemOpenFilePickerConfig = .init()) -> [URL]? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = config.allowsMultipleSelection
        panel.canChooseDirectories = config.canChooseDirectories
        guard panel.runModal() == .OK else { return nil }

        return panel.urls
    }

    public func getDirectoryInfo(for url: URL) async -> Result<DirectoryInfo, FileSystemGetDirectoryInfoErrors> {
        await getDirectoryInfo(for: url, parent: nil)
    }

    public func findDirectories(_ match: String, in directory: DirectoryInfo) async -> [DirectoryInfo] {
        let directoryURLString = directory.url.absoluteString
        var matches: [DirectoryInfo] = []
        for currentDirectory in await listNestedDirectories(in: directory) {
            var currentDirectoryURLComponents = currentDirectory.url.absoluteString
                .split(separator: directoryURLString)
            if currentDirectoryURLComponents.count > 1 {
                currentDirectoryURLComponents.removeFirst()
            }
            let currentDirectoryURLStringWithoutSourceDirectory = currentDirectoryURLComponents.joined(separator: "/")
            if currentDirectoryURLStringWithoutSourceDirectory.contains(match) {
                matches.append(currentDirectory)
            }
        }

        return matches
    }

    public func listNestedDirectories(in directory: DirectoryInfo) async ->[DirectoryInfo] {
        var directories: [DirectoryInfo] = []
        for currentDirectory in await directory.getDirectories() {
            directories.append(currentDirectory)
            let nestedDirectories = await listNestedDirectories(in: currentDirectory)
            directories.append(contentsOf: nestedDirectories)
        }

        return directories
    }

    public func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let itemExists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        return itemExists && isDirectory.boolValue
    }

    public func isFile(_ url: URL) -> Bool {
        itemExists(url) && !isDirectory(url)
    }

    public func itemExists(_ url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    private func getDirectoryInfo(
        for url: URL,
        parent: DirectoryInfo?
    ) async -> Result<DirectoryInfo, FileSystemGetDirectoryInfoErrors> {
        guard itemExists(url) else { return .failure(.doesNotExist) }
        guard isDirectory(url) else { return .failure(.notADirectory) }

        let itemURLs: [URL]
        do {
            itemURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        } catch {
            return .failure(.generalError(cause: error))
        }

        let fetchingDirectoryInfo = DirectoryInfo(url: url, parent: parent, files: [], directories: [])
        var fetchingDirectoryInfoDirectoriess: [DirectoryInfo] = []
        var fetchingDirectoryInfoFiles: [FileInfo] = []
        for currentURL in itemURLs {
            guard itemExists(currentURL) else { continue }

            if isDirectory(currentURL) {
                let directoryResult = await getDirectoryInfo(for: currentURL, parent: fetchingDirectoryInfo)
                switch directoryResult {
                case .failure: continue
                case let .success(success):
                    fetchingDirectoryInfoDirectoriess.append(success)
                }
            } else if isFile(currentURL) {
                let file = FileInfo(url: currentURL, parent: fetchingDirectoryInfo)
                fetchingDirectoryInfoFiles.append(file)
            }
        }

        let fetchingDirectoriesWithItems = await fetchingDirectoryInfo
            .setFiles(fetchingDirectoryInfoFiles)
            .setDirectories(fetchingDirectoryInfoDirectoriess)

        return .success(fetchingDirectoriesWithItems)
    }
}

public actor DirectoryInfo: Hashable, Equatable, Sendable {
    fileprivate let url: URL
    private let parent: DirectoryInfo?
    private var files: [FileInfo]
    private var directories: [DirectoryInfo]

    public init(url: URL, parent: DirectoryInfo?, files: [FileInfo], directories: [DirectoryInfo]) {
        self.url = url
        self.parent = parent
        self.files = files
        self.directories = directories
    }

    public func getURL() -> URL {
        url
    }

    public func getParent() -> DirectoryInfo? {
        parent
    }

    public func getFiles() -> [FileInfo] {
        files
    }

    @discardableResult
    public func setFiles(_ files: [FileInfo]) -> Self {
        self.files = files

        return self
    }

    public func getDirectories() -> [DirectoryInfo] {
        directories
    }

    @discardableResult
    public func setDirectories(_ directories: [DirectoryInfo]) -> Self {
        self.directories = directories

        return self
    }

    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    public static func == (lhs: DirectoryInfo, rhs: DirectoryInfo) -> Bool {
        lhs.url == rhs.url
    }
}

public struct FileInfo: Hashable, Equatable, Sendable {
    public let url: URL
    public let parent: DirectoryInfo?

    public init(url: URL, parent: DirectoryInfo?) {
        self.url = url
        self.parent = parent
    }
}
