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
    case failedToReadContent(cause: Error)

    var errorDescription: String? {
        switch self {
        case .failedToReadContent: return NSLocalizedString("Failed to read file content", bundle: .module, comment: "")
        }
    }
}

@Observable
final class TransformingViewModel {
    private(set) var openedFiles: [FileItem] = []

    private let logger = KamaalLogger(from: TransformingViewModel.self, failOnError: true)

    @MainActor
    func openFilePicker() -> Result<Void, OpenFilePickerErrors> {
        let fileURL = FSHelper.openFilePicker()
        guard let fileURL else { return .success(()) }

        return FSHelper.readFileContent(from: fileURL)
            .onFailure { logger.error(label: "Failed to read file content", error: $0) }
            .onSuccess { addToOpenedFiles($0) }
            .mapError { .failedToReadContent(cause: $0) }
            .map { _ in () }
    }

    @MainActor
    private func addToOpenedFiles(_ file: FileItem) {
        var newOpenedFiles = openedFiles
        if let existingFileIndex = openedFiles.findIndex(by: \.url, is: file.url) {
            newOpenedFiles[existingFileIndex] = file
        } else {
            newOpenedFiles = newOpenedFiles.prepended(file)
        }
        openedFiles = newOpenedFiles
    }
}
