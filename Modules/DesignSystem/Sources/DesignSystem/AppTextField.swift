//
//  File.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import SwiftValidator

/// Defines the validation rules that can be applied to an `AppTextField`.
///
/// These rules are used to validate the text input and provide feedback to the user
/// when the input doesn't meet the specified criteria.
public enum AppTextFieldValidationRules {
    /// Ensures the text has at least a minimum number of characters.
    ///
    /// - Parameters:
    ///   - length: The minimum number of characters required.
    ///   - message: Custom error message to display if validation fails. If `nil`, a default message is used.
    case minimumLength(length: Int, message: String?)

    /// Verifies that the text matches another value exactly.
    ///
    /// This is commonly used for password confirmation fields.
    ///
    /// - Parameters:
    ///   - value: The value to compare against.
    ///   - message: Custom error message to display if validation fails. If `nil`, a default message is used.
    case isSameAs(value: String, message: String?)

    /// Validates that the text is a properly formatted email address.
    ///
    /// - Parameter message: Custom error message to display if validation fails. If `nil`, a default message is used.
    case email(message: String?)
}

public struct AppTextFieldErrorResult: Equatable {
    public let valid: Bool
    public let errorMessage: String?

    public init(valid: Bool, errorMessage: String?) {
        self.valid = valid
        self.errorMessage = errorMessage
    }
}

/// Specifies the input variant for an `AppTextField`.
///
/// Each variant configures the text field with appropriate input restrictions
/// and keyboard types to optimize for different kinds of user input.
public enum AppTextFieldVariant {
    /// Standard text input with no specific restrictions.
    ///
    /// Uses the default keyboard type.
    case text

    /// Input optimized for decimal numbers.
    ///
    /// On iOS, this uses the decimal pad keyboard which includes digits and a decimal point.
    case decimals

    /// Input optimized for numeric values only.
    ///
    /// On iOS, this uses the number pad keyboard which includes only digits.
    case numbers

    /// Secure text input that masks characters for privacy.
    ///
    /// Typically used for passwords and sensitive information.
    case secure

    /// Input optimized for email addresses.
    ///
    /// On iOS, this uses the email address keyboard which includes the "@" symbol and ".com" shortcut.
    case email

    #if canImport(UIKit)
    var keyboardType: UIKeyboardType {
        switch self {
        case .decimals: return .decimalPad
        case .numbers: return .numberPad
        case .text, .secure: return .default
        case .email: return .emailAddress
        }
    }
    #endif
}

public struct AppTextField: View {
    @State private var showPassword = false

    @FocusState private var isFocused: Bool

    @Binding private var text: String
    @Binding private var errorResult: AppTextFieldErrorResult?

    public let title: String
    public let variant: AppTextFieldVariant
    public let validations: [any StringValidatableRule]

    public init(
        text: Binding<String>,
        errorResult: Binding<AppTextFieldErrorResult?>,
        title: String,
        variant: AppTextFieldVariant = .text,
        validations: [AppTextFieldValidationRules]
    ) {
        self._text = text
        self._errorResult = errorResult
        self.title = title
        self.variant = variant
        self.validations = validations.map({ validation -> any StringValidatableRule in
            switch validation {
            case let .minimumLength(length, message):
                StringValidateMinimumLength(length: length, message: message)
            case let .isSameAs(value, message):
                StringIsTheSameValue(value: value, message: message)
            case let .email(message):
                StringIsEmail(message: message)
            }
        })
    }

    public init(
        text: Binding<String>,
        errorResult: Binding<AppTextFieldErrorResult?>,
        localizedTitle: LocalizedStringResource,
        bundle: Bundle,
        variant: AppTextFieldVariant = .text,
        validations: [AppTextFieldValidationRules]
    ) {
        self.init(
            text: text,
            errorResult: errorResult,
            title: NSLocalizedString(localizedTitle.key, bundle: bundle, comment: ""),
            variant: variant,
            validations: validations
        )
    }

    public init(text: Binding<String>, title: String, variant: AppTextFieldVariant = .text) {
        self.init(
            text: text,
            errorResult: .constant(nil),
            title: title,
            variant: variant,
            validations: []
        )
    }

    public init(
        text: Binding<String>,
        localizedTitle: LocalizedStringResource,
        bundle: Bundle,
        variant: AppTextFieldVariant = .text
    ) {
        self.init(
            text: text,
            title: NSLocalizedString(localizedTitle.key, bundle: bundle, comment: ""),
            variant: variant
        )
    }

    public var body: some View {
        FloatingFieldWrapper(text: text, title: title, error: textFieldError, field: {
            if variant == .secure {
                HStack {
                    JustStack {
                        if showPassword {
                            TextField(placeholderText, text: $text)
                                .focused($isFocused)
                        } else {
                            SecureField(placeholderText, text: $text)
                                .focused($isFocused)
                        }
                    }
                    .takeWidthEagerly(alignment: .leading)
                    Image(systemName: !showPassword ? "eye" : "eye.slash")
                        .foregroundColor(showError ? Color.red : Color.accentColor)
                        .onTapGesture { handleShowPassword() }
                }
            } else {
                #if canImport(UIKit)
                TextField(placeholderText, text: $text)
                    .focused($isFocused)
                    .keyboardType(variant.keyboardType)
                #else
                TextField(placeholderText, text: $text)
                    .focused($isFocused)
                #endif
            }
        })
        .onChange(of: text) { _, newValue in handleValueChange(value: newValue) }
    }

    private var placeholderText: String {
        #if canImport(UIKit)
        return ""
        #else
        return title
        #endif
    }

    private var validator: StringValidator {
        StringValidator(value: text, validators: validations)
    }

    private var textFieldError: (show: Bool, message: String?) {
        guard showError else { return (false, nil) }

        return (true, errorResult?.errorMessage)
    }

    private var showError: Bool {
        guard !validations.isEmpty else { return false }

        return !isFocused && !text.isEmpty && errorResult?.valid != true
    }

    private func handleShowPassword() {
        showPassword.toggle()
    }

    private func handleValueChange(value: String) {
        setErrorResult(value: value)
    }

    private func setErrorResult(value: String) {
        let result = validator.result
        errorResult = AppTextFieldErrorResult(valid: result.valid, errorMessage: result.message)
    }
}

private struct FloatingFieldWrapper<Field: View>: View {
    @State private var textYOffset: CGFloat
    @State private var textScaleEffect: CGFloat

    private let text: String
    private let title: String
    private let error: (show: Bool, message: String?)
    @ViewBuilder private let field: Field

    init(
        text: String,
        title: String,
        error: (show: Bool, message: String?),
        @ViewBuilder field: @escaping () -> Field
    ) {
        self.text = text
        self.title = title
        self.error = error
        self.field = field()
        self.textYOffset = Self.nextTextYOffsetValue(text.isEmpty)
        self.textScaleEffect = Self.nextTextScaleEffectValue(text.isEmpty)
    }

    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(textColor)
                    .offset(y: textYOffset)
                    .scaleEffect(textScaleEffect, anchor: .leading)
                    .padding(.horizontal, titleHorizontalPadding)
                field
            }
            if error.show, let message = error.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Color.red)
                    .takeWidthEagerly(alignment: .leading)
            }
        }
        .padding(.top, 12)
        .animation(.spring(response: 0.5), value: textYOffset)
        .onChange(of: text.isEmpty, handleOnTextIsEmptyChange)
    }

    private var textColor: Color {
        if text.isEmpty { .secondary } else { .accentColor }
    }

    private var titleHorizontalPadding: CGFloat {
        if text.isEmpty { 4 } else { 0 }
    }

    private func handleOnTextIsEmptyChange(_ oldValue: Bool, _ newValue: Bool) {
        textYOffset = Self.nextTextYOffsetValue(newValue)
        textScaleEffect = Self.nextTextScaleEffectValue(newValue)
    }

    private static func nextTextYOffsetValue(_ textIsEmpty: Bool) -> CGFloat {
        if textIsEmpty { 0 } else { -25 }
    }

    private static func nextTextScaleEffectValue(_ textIsEmpty: Bool) -> CGFloat {
        if textIsEmpty { 1 } else { 0.75 }
    }
}

#Preview {
    VStack(spacing: 24) {
        AppTextField(
            text: .constant("Yes"),
            errorResult: .constant(AppTextFieldErrorResult(valid: false, errorMessage: "Nooo")),
            title: "Task",
            validations: []
        )
        AppTextField(
            text: .constant(""),
            errorResult: .constant(AppTextFieldErrorResult(valid: false, errorMessage: "Nooo")),
            title: "Task",
            validations: []
        )
    }
        .padding(.all, .medium)
}
