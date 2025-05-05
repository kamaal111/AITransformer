//
//  FSHelper.swift
//  Features
//
//  Created by Kamaal M Farah on 5/3/25.
//

import AppKit
import KamaalExtensions

struct FSHelperConfig {
    let allowsMultipleSelection: Bool
    let canChooseDirectories: Bool

    init(allowsMultipleSelection: Bool = false, canChooseDirectories: Bool = false) {
        self.allowsMultipleSelection = allowsMultipleSelection
        self.canChooseDirectories = canChooseDirectories
    }
}

enum FSHelper {
    @MainActor
    static func openFilePicker(config: FSHelperConfig = .init()) -> [URL]? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = config.allowsMultipleSelection
        panel.canChooseDirectories = config.canChooseDirectories
        guard panel.runModal() == .OK else { return nil }

        return panel.urls
    }

    static func checkIfIsDirectory(_ url: URL) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let itemExists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        return itemExists && isDirectory.boolValue
    }

    static func getItem(from url: URL, lazily: Bool) async -> FSItem? {
        if checkIfIsDirectory(url) {
            return await getDirectoryWithItems(in: url, lazily: lazily)
        }

        let parentFolder = makeEmptyRootParentFolder(for: url)

        return await getFile(from: url, parent: parentFolder, lazily: lazily)
    }

    static func getDirectoryWithItems(in url: URL, lazily: Bool) async -> FSItem? {
        await getDirectoryWithItems(in: url, ignores: [], lazily: lazily)
    }

    private static func getDirectoryWithItems(in url: URL, ignores: Set<String>, lazily: Bool) async -> FSItem? {
        guard checkIfIsDirectory(url) else { return nil }

        let fileManager = FileManager.default
        let itemURLs: [URL]
        do {
            itemURLs = try fileManager
                .contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        } catch {
            return nil
        }

        let parentFolder = makeEmptyRootParentFolder(for: url)
        let folder = FSItem.createAsFolder(url: url, items: [], parent: parentFolder)
        let items = await withTaskGroup(of: Optional<FSItem>.self, returning: [FSItem].self) { taskGroup in
            var ignores: Set<String> = ignores
            if let gitIgnoreFileURL = itemURLs.find(by: \.lastPathComponent, is: ".gitignore"),
               let gitIgnoreFile = await getFile(from: gitIgnoreFileURL, parent: nil, lazily: false) {
                ignores = GitIgnoreSpec
                    .getFilePaths(gitIgnoreFile.content, previousIgnores: ignores, parent: parentFolder)
            }

            for itemURL in itemURLs
            where !itemURL.lastPathComponent.hasPrefix(".") && !GitIgnoreSpec.ignore(ignores: ignores, url: itemURL) {
                let ignoresCopy = ignores
                taskGroup.addTask {
                    if checkIfIsDirectory(itemURL) {
                        let folder = await getDirectoryWithItems(in: itemURL, ignores: ignoresCopy, lazily: lazily)
                        let folderItems = folder?.items ?? []

                        return FSItem.createAsFolder(url: itemURL, items: folderItems, parent: folder)
                    }

                    return await getFile(from: itemURL, parent: folder, lazily: lazily)
                }
            }

            var items: [FSItem] = []
            for await item in taskGroup {
                guard let item else {
                    assertionFailure("Opened files should be present, so whats wrong?")
                    continue
                }

                items.append(item)
            }

            return items
        }

        return folder.setItems(items)
    }

    static func getFile(from url: URL, parent: FSItem?, lazily: Bool) async -> FSItem? {
        let fileContent: String
        if lazily {
            fileContent = ""
        } else {
            do {
                fileContent = try String(contentsOf: url, encoding: .utf8)
            } catch {
                return nil
            }
        }

        var file = if lazily {
            FSItem.createAsLazyFile(url: url, parent: parent)
        } else {
            FSItem.createAsFile(url: url, content: fileContent, parent: parent)
        }
        if file.parent == nil {
            let parentFolder = makeEmptyRootParentFolder(for: url).setItems([file])
            file = file.setParent(parentFolder)
        }

        return file
    }

    private static func makeEmptyRootParentFolder(for url: URL) -> FSItem {
        let parentFolderURL = makeParentFolderURL(for: url)

        return FSItem.createAsFolder(url: parentFolderURL, items: [], parent: nil)
    }

    private static func makeParentFolderURL(for url: URL) -> URL {
        url.deletingLastPathComponent()
    }
}
