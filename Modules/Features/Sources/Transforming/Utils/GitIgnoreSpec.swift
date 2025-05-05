//
//  GitIgnoreSpec.swift
//  Features
//
//  Created by Kamaal M Farah on 5/5/25.
//

import Foundation
import KamaalExtensions

enum GitIgnoreSpec {
    static func getFilePaths(_ content: String, previousIgnores: Set<String>, parent: FSItem?) -> Set<String> {
        content
            .splitLines
            .reduce(previousIgnores, { result, current in
                guard let formatted = formatLine(current) else { return result }

                var result = result
                if shouldAddLineToIgnores(formatted) {
                    result.insert(formatted)
                } else if shouldRemoveFromIgnores(formatted, ignores: result) {
                    result.remove(formatted)
                }

                return result
            })
    }

    static func ignore(ignores: Set<String>, url: URL) -> Bool {
        ignores.contains(url.lastPathComponent)
    }

    private static func shouldRemoveFromIgnores(_ line: String, ignores: Set<String>) -> Bool {
        assert(formatLine(line) == line, "Should be already formatted before evulating")
        assert(!line.isEmpty, "Should not be empty at this point")

        return ignores.contains(line) && line.hasPrefix("#")
    }

    private static func shouldAddLineToIgnores(_ line: String) -> Bool {
        assert(formatLine(line) == line, "Should be already formatted before evulating")
        assert(!line.isEmpty, "Should not be empty at this point")

        return !line.hasPrefix("#")
    }

    private static func formatLine(_ line: some StringProtocol) -> String? {
        var formatted = String(line.trimmingByWhitespacesAndNewLines)
        guard !formatted.isEmpty else { return nil }

        if formatted.hasSuffix("/") {
            formatted = String(formatted.dropLast())
            guard !formatted.isEmpty else { return nil }
        }
        if formatted.hasPrefix("./") {
            formatted = String(formatted.range(from: 2))
            guard !formatted.isEmpty else { return nil }
        }

        // Very optimistic, but will bother later when it gets in the way!
        // TODO: Do something with parent probably
        guard let name = formatted.split(separator: "/").last else { return nil }
        guard !name.isEmpty else { return nil }

        return String(name)
    }
}
