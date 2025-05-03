//
//  FSHelper.swift
//  Features
//
//  Created by Kamaal M Farah on 5/3/25.
//

import AppKit

enum FSHelper {
    @MainActor
    static func openFilePicker() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return nil }
        guard let fileURL = panel.url else {
            assertionFailure("File URL should be available")
            return nil
        }

        return fileURL
    }

    static func readFileContent(from url: URL) -> Result<String, Error> {
        do {
            return .success(try String(contentsOf: url, encoding: .utf8))
        } catch {
            return .failure(error)
        }
    }
}
