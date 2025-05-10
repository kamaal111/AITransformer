//
//  TransformingViewModel.swift
//  Features
//
//  Created by Kamaal M Farah on 5/3/25.
//

import Foundation
import FileSystem
import Observation
import KamaalLogger
import KamaalExtensions

private let DEFAULT_PROVIDER: LLMProviders = .openai

@MainActor
@Observable
final class TransformingViewModel {
    var selectedLLMProvider: LLMProviders {
        didSet { onSelectedLLMProviderChange() }
    }
    var selectedLLMModel: LLMModel
    private(set) var openedItem: FSItem?
    private var apiKeys: [LLMProviders: String]
    private(set) var loadingOpenedItem = false
    var itemPathsToIgnore = ""

    private let fs = FileSystem()
    private let logger = KamaalLogger(from: TransformingViewModel.self, failOnError: true)

    init() {
        let llmProvider = DEFAULT_PROVIDER
        self.selectedLLMProvider = llmProvider
        self.selectedLLMModel = llmProvider.models.first!
        self.openedItem = nil

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

    func openFilePicker() async {
        await withLoadingOpeningItem {
            let openFilePickerConfig = FileSystemOpenFilePickerConfig(
                allowsMultipleSelection: false,
                canChooseDirectories: true,
                canChooseFiles: false
            )
            guard let fileURLs = fs.openFilePicker(config: openFilePickerConfig) else { return }

            assert(fileURLs.count == 1, "If not nil, there should be atleast 1 URL")
            guard let fileURL = fileURLs.first else { return }
            await openItem(on: fileURL)
        }
    }

    private func openItem(on url: URL) async {
//        let directory = await fs.getDirectoryInfo(for: url, ignoringRuleFilenames: [".gitignore"])
        guard let item = await FSHelper.getItem(from: url, lazily: true) else { return }

        setOpenedItem(item)
        logger.info("Opened file: \(item.name)")
    }

    private func onSelectedLLMProviderChange() {
        if !selectedLLMProvider.models.contains(selectedLLMModel) {
            selectedLLMModel = selectedLLMProvider.models.first!
        }
        if apiKeys[selectedLLMProvider] == nil {
            apiKeys[selectedLLMProvider] = Self.getAPIKey(for: selectedLLMProvider)
        }
    }

    private func setOpenedItem(_ item: FSItem) {
        openedItem = item
    }

    private func withLoadingOpeningItem<T: Sendable>(_ handler: () async -> T) async -> T {
        loadingOpenedItem = true
        let result = await handler()
        loadingOpenedItem = false

        return result
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
