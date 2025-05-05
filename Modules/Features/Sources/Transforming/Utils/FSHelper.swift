//
//  FSHelper.swift
//  Features
//
//  Created by Kamaal M Farah on 5/3/25.
//

import AppKit

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

    static func getItem(from url: URL) async -> FSItem? {
        if checkIfIsDirectory(url) {
            return await getDirectoryWithItems(in: url)
        }

        let parentFolder = makeEmptyRootParentFolder(for: url)

        return await getFile(from: url, parent: parentFolder)
    }

    static func getDirectoryWithItems(in url: URL) async -> FSItem? {
        guard checkIfIsDirectory(url) else { return nil }

        let fileManager = FileManager.default
        let itemURLs: [URL]
        do {
            itemURLs = try fileManager
                .contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        } catch {
            return nil
        }

        let parentFolder = makeEmptyRootParentFolder(for: url)
        let folder = FSItem.createAsFolder(url: url, items: [], parent: parentFolder)
        let items = await withTaskGroup(of: Optional<FSItem>.self, returning: [FSItem].self) { taskGroup in
            for url in itemURLs {
                taskGroup.addTask {
                    if checkIfIsDirectory(url) {
                        let folder = await getDirectoryWithItems(in: url)
                        let folderItems = folder?.items ?? []

                        return FSItem.createAsFolder(url: url, items: folderItems, parent: folder)
                    }

                    return await getFile(from: url, parent: folder)
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

    static func getFile(from url: URL, parent: FSItem?) async -> FSItem? {
        let fileContent: String
        do {
            fileContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            return nil
        }

        var file = FSItem.createAsFile(url: url, content: fileContent, parent: parent)
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
