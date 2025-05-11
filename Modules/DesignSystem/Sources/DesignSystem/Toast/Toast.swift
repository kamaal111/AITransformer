//
//  Toast.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI

@usableFromInline
let TOAST_DEFAULT_DURATION: Double = 3

@usableFromInline
let TOAST_DEFAULT_WIDTH: CGFloat = .infinity

public struct Toast: Equatable {
    public let style: ToastStyle
    public let message: String
    public let duration: Double
    public let width: CGFloat

    init(
        style: ToastStyle,
        message: String,
        duration: Double = TOAST_DEFAULT_DURATION,
        width: CGFloat = TOAST_DEFAULT_WIDTH
    ) {
        self.style = style
        self.message = message
        self.duration = duration
        self.width = width
    }

    public static func error(
        message: String,
        duration: Double = TOAST_DEFAULT_DURATION,
        width: CGFloat = TOAST_DEFAULT_WIDTH
    ) -> Self {
        .init(style: .error, message: message, duration: duration, width: width)
    }

    public static func success(
        message: String,
        duration: Double = TOAST_DEFAULT_DURATION,
        width: CGFloat = TOAST_DEFAULT_WIDTH
    ) -> Self {
        .init(style: .success, message: message, duration: duration, width: width)
    }
}

/// Style options for toast notifications that define appearance and behavior.
///
/// `ToastStyle` provides predefined appearance options for toast notifications,
/// including colors and system images appropriate for different notification types.
public enum ToastStyle {
    /// Style for error messages, typically shown in red with an X icon.
    case error
    /// Style for warning messages, typically shown in orange with a warning triangle icon.
    case warning
    /// Style for success messages, typically shown in green with a checkmark icon.
    case success
    /// Style for informational messages, typically shown in blue with an information icon.
    case info

    /// The color associated with this toast style.
    ///
    /// Each style has a semantic color:
    /// - `.error`: red
    /// - `.warning`: orange
    /// - `.info`: blue
    /// - `.success`: green
    public var color: Color {
        switch self {
        case .error: .red
        case .warning: .orange
        case .info: .blue
        case .success: .green
        }
    }

    /// The SF Symbol name for the icon associated with this toast style.
    ///
    /// Each style has an appropriate icon:
    /// - `.info`: "info.circle.fill"
    /// - `.warning`: "exclamationmark.triangle.fill" 
    /// - `.success`: "checkmark.circle.fill"
    /// - `.error`: "xmark.circle.fill"
    public var imageSystemName: String {
        switch self {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        case .error: "xmark.circle.fill"
        }
    }
}
