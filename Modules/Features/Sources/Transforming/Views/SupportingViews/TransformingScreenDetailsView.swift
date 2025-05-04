//
//  TransformingScreenDetailsView.swift
//  Features
//
//  Created by Kamaal M Farah on 5/4/25.
//

import SwiftUI
import DesignSystem

struct TransformingScreenDetailsView: View {
    @Binding var toast: Toast?

    @State var viewModel: TransformingViewModel

    @State private var apiKeyField = ""
    @State private var apiKeyFieldError: AppTextFieldErrorResult?

    var body: some View {
        VStack {
            HStack {
                if viewModel.apiKeyForSelectedLLMProvider == nil {
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
                    .onSubmit(storeAPIKey)
                    Button(action: storeAPIKey) {
                        Text("Store")
                            .foregroundStyle(Color.accentColor)
                            .bold()
                    }
                    .disabled(!apiKeyFieldIsValid)
                    .padding(.bottom, -8)
                } else { }
            }
            HStack {
                Picker("", selection: $viewModel.selectedLLMProvider) {
                    ForEach(LLMProviders.allCases) { provider in
                        Text(provider.name)
                    }
                }
                .labelsHidden()
                Picker("", selection: $viewModel.selectedLLMModel) {
                    ForEach(viewModel.selectedLLMProvider.models, id: \.self) { model in
                        Text(model.key)
                    }
                }
                .labelsHidden()
            }
        }
        .takeSizeEagerly(alignment: .top)
        .padding(.vertical, .medium)
        .padding(.horizontal, .large)
    }

    private func storeAPIKey() {
        guard apiKeyFieldIsValid else { return }

        if let apiKeyFieldError, !apiKeyFieldError.valid {
            toast = .error(message: apiKeyFieldError.errorMessage ?? "")
            return
        }

        viewModel.storeAPIKey(apiKeyField)
            .onFailure { toast = .error(message: $0.localizedDescription) }
    }

    private var apiKeyFieldIsValid: Bool {
        apiKeyFieldError?.valid == true || apiKeyFieldError == nil
    }
}

#Preview {
    @Previewable @State var viewModel = TransformingViewModel()

    TwoColumnView(leftView: { Text("Hello") }, rightView: {
        TransformingScreenDetailsView(toast: .constant(nil), viewModel: viewModel)
    })
}
