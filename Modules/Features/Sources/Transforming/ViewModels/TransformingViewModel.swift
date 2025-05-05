//
//  TransformingViewModel.swift
//  Features
//
//  Created by Kamaal M Farah on 5/3/25.
//

import Foundation
import Observation
import KamaalExtensions
@preconcurrency import KamaalLogger

private let DEFAULT_PROVIDER: LLMProviders = .openai
private let logger = KamaalLogger(from: TransformingViewModel.self, failOnError: true)

@MainActor
@Observable
final class TransformingViewModel {
    var selectedLLMProvider: LLMProviders {
        didSet { onSelectedLLMProviderChange() }
    }
    var selectedLLMModel: LLMModel
    private(set) var openedFiles: [FileItem]
    private var apiKeys: [LLMProviders: String]

    init() {
        let llmProvider = DEFAULT_PROVIDER
        self.selectedLLMProvider = llmProvider
        self.selectedLLMModel = llmProvider.models.first!
        self.openedFiles = []

        if let initialAPIKey = Self.getAPIKey(for: llmProvider) {
            self.apiKeys = [llmProvider: initialAPIKey]
        } else {
            self.apiKeys = [:]
        }
    }

    var apiKeyForSelectedLLMProvider: String? {
        apiKeys[selectedLLMProvider]
    }

    func removeAPIKey() -> Result<Void, RemoveAPIKeyErrors> {
        Keychain.delete(forKey: selectedLLMProvider.key)
            .onFailure { logger.error(label: "Failed to remove API key for \(selectedLLMProvider.name)", error: $0) }
            .mapError { .generalFailure(cause: $0) }
            .onSuccess { apiKeys[selectedLLMProvider] = nil }
    }

    func storeAPIKey(_ apiKey: String) -> Result<Void, StoreAPIKeyErrors> {
        guard let apiKeyData = apiKey.data(using: .utf8) else { return .failure(.encodingFailure) }

        return Keychain.set(apiKeyData, forKey: selectedLLMProvider.key)
            .onFailure { logger.error(label: "Failed to store API key for \(selectedLLMProvider.name)", error: $0) }
            .mapError { .storageFailure(cause: $0) }
            .onSuccess { apiKeys[selectedLLMProvider] = apiKey }
    }

    func openFilePicker() async -> Result<Void, OpenFilePickerErrors> {
        let fileURLs = FSHelper.openFilePicker(config: .init(allowsMultipleSelection: true))
        guard let fileURLs else { return .success(()) }

        let results = await withTaskGroup(
            of: Result<FileItem, OpenFilePickerErrors>.self,
            returning: (successes: [FileItem], failures: [OpenFilePickerErrors]).self
        ) { taskGroup in
            for url in fileURLs {
                taskGroup.addTask {
                    await FSHelper.readFileContent(from: url)
                        .mapError { error in OpenFilePickerErrors.failedToReadContent(cause: error, url: url) }
                        .onFailure { error in logger.error(label: "Failed to read file content", error: error) }
                }
            }

            var groupedResults = (successes: [FileItem](), failures: [OpenFilePickerErrors]())
            for await result in taskGroup {
                switch result {
                case let .failure(failure): groupedResults.failures.append(failure)
                case let .success(success): groupedResults.successes.append((success))
                }
            }

            return groupedResults
        }
        addToOpenedFiles(results.successes)

        if let firstError = results.failures.first {
            return .failure(firstError)
        }

        logger.info("Opened \(results.successes.count) files")

        return .success(())
    }

    private func onSelectedLLMProviderChange() {
        if !selectedLLMProvider.models.contains(selectedLLMModel) {
            selectedLLMModel = selectedLLMProvider.models.first!
        }
        if apiKeys[selectedLLMProvider] == nil {
            apiKeys[selectedLLMProvider] = Self.getAPIKey(for: selectedLLMProvider)
        }
    }

    private func addToOpenedFiles(_ file: FileItem) {
        addToOpenedFiles([file])
    }

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

    private static func getAPIKey(for provider: LLMProviders) -> String? {
        Keychain.get(forKey: provider.key)
            .map { data -> String? in
                guard let data else { return nil }
                return String(data: data, encoding: .utf8)
            }
            .getOrNil() ?? nil
    }
}

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

enum StoreAPIKeyErrors: Error, LocalizedError {
    case encodingFailure
    case storageFailure(cause: Error)

    var errorDescription: String? {
        switch self {
        case .encodingFailure:
            return NSLocalizedString("Failed to encode API key for storage", bundle: .module, comment: "")
        case .storageFailure:
            return NSLocalizedString("Failed to store API key", bundle: .module, comment: "")
        }
    }
}

enum RemoveAPIKeyErrors: Error, LocalizedError {
    case generalFailure(cause: Error)

    var errorDescription: String? {
        switch self {
        case .generalFailure:
            return NSLocalizedString("Failed to remove API key", bundle: .module, comment: "")
        }
    }
}
