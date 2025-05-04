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

    @State private var apiKey = ""
    @State private var apiKeyFieldError: AppTextFieldErrorResult?
    @State private var editAPIKey = false
    @State private var removingAPIKeyWarningAlertIsShown = false

    var body: some View {
        VStack {
            if viewModel.apiKeyForSelectedLLMProvider == nil || editAPIKey {
                addOrEditAPIKeyView
            } else {
                modifyAPIKeyView
            }
            modifyLLMView
        }
        .takeSizeEagerly(alignment: .top)
        .padding(.vertical, .medium)
        .padding(.horizontal, .large)
        .onChange(of: editAPIKey, onEditAPIKeyChange)
        .alert("Remove API Key?", isPresented: $removingAPIKeyWarningAlertIsShown, actions: {
            Button("Cancel", role: .cancel, action: { })
            Button("Remove", role: .destructive, action: definitelyRemoveAPIKey)
        }, message: {
            Text(String(
                format: NSLocalizedString(
                    "Are you sure you want to remove the API key for %@?",
                    bundle: .module,
                    comment: ""
                ),
                viewModel.selectedLLMProvider.name
            ))
        })
    }

    private var modifyLLMView: some View {
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
        .disabled(editAPIKey)
    }

    private var modifyAPIKeyView: some View {
        HStack {
            HStack(spacing: 0) {
                Text("API key:")
                    .padding(.trailing, .extraSmall)
                ForEach(0..<4, id: \.self) { _ in
                    Image(systemName: "ellipsis")
                        .padding(.bottom, -4)
                }
            }
            .font(.headline)
            .bold()
            Spacer()
            Button(action: startEditingAPIKey) {
                Image(systemName: "pencil")
                    .foregroundStyle(Color.accentColor)
                    .bold()
            }
            .accessibilityValue("Edit API key")
            Button(action: removeAPIKey) {
                Image(systemName: "trash.fill")
                    .foregroundStyle(Color.accentColor)
                    .bold()
            }
            .accessibilityValue("Remove API key")
        }
        .takeWidthEagerly(alignment: .leading)
    }

    private var addOrEditAPIKeyView: some View {
        HStack {
            AppTextField(
                text: $apiKey,
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
            if editAPIKey {
                Button(action: cancelEditingAPIKey) {
                    Text("Cancel")
                        .foregroundStyle(Color.accentColor)
                        .bold()
                }
                .padding(.bottom, -8)
            }
        }
    }

    private var apiKeyFieldIsValid: Bool {
        apiKeyFieldError?.valid == true || apiKeyFieldError == nil
    }

    private func definitelyRemoveAPIKey() {
        viewModel.removeAPIKey()
            .onFailure { toast = .error(message: $0.localizedDescription) }
    }

    private func removeAPIKey() {
        removingAPIKeyWarningAlertIsShown = true
    }

    private func startEditingAPIKey() {
        editAPIKey = true
    }

    private func cancelEditingAPIKey() {
        editAPIKey = false
    }

    private func onEditAPIKeyChange(_ oldValue: Bool, _ newValue: Bool) {
        if newValue {
            apiKey = viewModel.apiKeyForSelectedLLMProvider ?? ""
        } else {
            apiKey = ""
        }
    }

    private func storeAPIKey() {
        guard apiKeyFieldIsValid else { return }

        if let apiKeyFieldError, !apiKeyFieldError.valid {
            toast = .error(message: apiKeyFieldError.errorMessage ?? "")
            return
        }

        viewModel.storeAPIKey(apiKey)
            .onFailure { toast = .error(message: $0.localizedDescription) }
            .onSuccess { editAPIKey = false }
    }
}

#Preview {
    @Previewable @State var viewModel = TransformingViewModel()

    TwoColumnView(leftView: { Text("Hello") }, rightView: {
        TransformingScreenDetailsView(toast: .constant(nil), viewModel: viewModel)
    })
}
