//
//  TransformingViewModel.swift
//  Features
//
//  Created by Kamaal M Farah on 5/3/25.
//

import Foundation
import Observation

@Observable
final class TransformingViewModel {
    private(set) var openedFile: FileItem?

    var openedFileName: String? {
        openedFile?.name
    }

    @MainActor
    func openFilePicker() {
        let fileURL = FSHelper.openFilePicker()
        guard let fileURL else { return }

        let fileContentResult = FSHelper.readFileContent(from: fileURL)
        let file: FileItem
        switch fileContentResult {
        case let .failure(failure):
            print("Failed to read file content; error='\(failure)'")
            return
        case let .success(success): file = success
        }

        openedFile = file
    }
}
