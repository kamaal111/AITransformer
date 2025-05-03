//
//  TransformingScreen.swift
//  Features
//
//  Created by Kamaal M Farah on 4/28/25.
//

import SwiftUI
import DesignSystem

private let DEFAULT_PROVIDER: LLMProviders = .openai
private let DEFAULT_MODEL = DEFAULT_PROVIDER.models.first!

public struct TransformingScreen: View {
    @State private var viewModel = TransformingViewModel()

    @State private var apiKeyField = ""
    @State private var apiKeyFieldError: AppTextFieldErrorResult?
    @State private var selectedLLMProvider = DEFAULT_PROVIDER
    @State private var selectedLLMModel: LLMModel = DEFAULT_MODEL

    public init() { }

    public var body: some View {
        VStack {
            VStack {
                AppTextField(
                    text: $apiKeyField,
                    errorResult: $apiKeyFieldError,
                    localizedTitle: "API key",
                    bundle: .module,
                    variant: .secure,
                    validations: [
                        .minimumLength(
                            length: 1,
                            message: NSLocalizedString(
                                "API key should not be empty",
                                bundle: .module,
                                comment: ""
                            )
                        ),
                    ]
                )
                HStack {
                    Picker("", selection: $selectedLLMProvider) {
                        ForEach(LLMProviders.allCases) { provider in
                            Text(provider.name)
                        }
                    }
                    .labelsHidden()
                    Picker("", selection: $selectedLLMModel) {
                        ForEach(selectedLLMProvider.models, id: \.self) { model in
                            Text(model.key)
                        }
                    }
                    .labelsHidden()
                }
            }
            Button(action: viewModel.openFilePicker) {
                Text("Pick a file to transform")
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
            Text(viewModel.openedFileName ?? "No file open")
        }
        .padding(.all, .large)
        .onChange(of: selectedLLMProvider, initial: false) { oldValue, newValue in
            guard oldValue != newValue else { return }
            print("newValue", newValue)

            selectedLLMModel = newValue.models.first!
        }
    }
}

#Preview {
    TransformingScreen()
}
