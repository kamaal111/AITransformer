//
//  TransformingScreen.swift
//  Features
//
//  Created by Kamaal M Farah on 4/28/25.
//

import SwiftUI

public struct TransformingScreen: View {
    public init() { }

    public var body: some View {
        Button(action: handleFilePickerPress) {
            Text("Pick a file to transform")
        }
    }

    private func handleFilePickerPress() {
        let fileURL = FSHelper.openFilePicker()
        guard let fileURL else { return }

        let fileContentResult = FSHelper.readFileContent(from: fileURL)
        let fileContent: String
        switch fileContentResult {
        case let .failure(failure):
            print("Failed to read file content; error='\(failure)'")
            return
        case let .success(success): fileContent = success
        }
        print("🐸🐸🐸", fileContent)
    }
}

#Preview {
    TransformingScreen()
}
