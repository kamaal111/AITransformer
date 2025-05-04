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

    static func readFileContent(from url: URL) -> Result<FileItem, Error> {
        let fileContent: String
        do {
            fileContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            return .failure(error)
        }

        return .success(.init(content: fileContent, url: url))
    }
}
