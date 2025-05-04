//
//  TransformingViewModel.swift
//  Features
//
//  Created by Kamaal M Farah on 5/3/25.
//

import Foundation
import Observation
import KamaalLogger
import KamaalExtensions

enum OpenFilePickerErrors: Error, LocalizedError {
    case failedToReadContent(cause: Error, url: URL)

    var errorDescription: String? {
        switch self {
        case let .failedToReadContent(_, url):
            return String(
                format: NSLocalizedString("Failed to read file content of %@", bundle: .module, comment: ""),
                url.absoluteString
            )
        }
    }
}

@Observable
final class TransformingViewModel {
    private(set) var openedFiles: [FileItem] = []

    private let logger = KamaalLogger(from: TransformingViewModel.self, failOnError: true)

    @MainActor
    func openFilePicker() -> Result<Void, OpenFilePickerErrors> {
        guard let fileURLs = FSHelper.openFilePicker(config: .init(allowsMultipleSelection: true)) else { return .success(()) }

        let results = fileURLs
            .map { url in
                FSHelper.readFileContent(from: url)
                    .mapError { error in OpenFilePickerErrors.failedToReadContent(cause: error, url: url) }
                    .onFailure { error in logger.error(label: "Failed to read file content", error: error) }
            }
            .reduce((successes: [FileItem](), failures: [OpenFilePickerErrors]()), { result, current in
                switch current {
                case let .failure(failure): return (result.successes, result.failures.appended(failure))
                case let .success(success): return (result.successes.appended(success), result.failures)
                }
            })
        addToOpenedFiles(results.successes)

        if let firstError = results.failures.first {
            return .failure(firstError)
        }

        logger.info("Opened \(results.successes.count) files")

        return .success(())
    }

    @MainActor
    private func addToOpenedFiles(_ file: FileItem) {
        addToOpenedFiles([file])
    }

    @MainActor
    private func addToOpenedFiles(_ files: [FileItem]) {
        var newOpenedFiles = openedFiles
        for file in files {
            if let existingFileIndex = openedFiles.findIndex(by: \.url, is: file.url) {
                newOpenedFiles[existingFileIndex] = file
            } else {
                newOpenedFiles = newOpenedFiles.prepended(file)
            }
        }
        openedFiles = newOpenedFiles
    }
}
