//
//  LLMProviders.swift
//  Features
//
//  Created by Kamaal M Farah on 5/3/25.
//

import Foundation

private let OPENAI_MODELS = [
    LLMModel(key: "gpt-4o-mini")
]

enum LLMProviders: CaseIterable, Hashable, Identifiable {
    case openai

    var id: Self { self }

    var models: [LLMModel] {
        switch self {
        case .openai: OPENAI_MODELS
        }
    }

    var name: String {
        switch self {
        case .openai: NSLocalizedString("OpenAI", bundle: .module, comment: "")
        }
    }
}
