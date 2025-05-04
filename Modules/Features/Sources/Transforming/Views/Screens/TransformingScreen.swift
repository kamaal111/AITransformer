//
//  TransformingScreen.swift
//  Features
//
//  Created by Kamaal M Farah on 4/28/25.
//

import SwiftUI
import DesignSystem

private let MAX_SIDEBAR_WIDTH: CGFloat = 200

public struct TransformingScreen: View {
    @State private var viewModel = TransformingViewModel()
    @State private var toast: Toast?

    public init() { }

    public var body: some View {
        TwoColumnView(
            leftView: {
                TransformingScreenSidebar(toast: $toast, viewModel: viewModel)
                    .frame(maxWidth: MAX_SIDEBAR_WIDTH)
            },
            rightView: {
                TransformingScreenDetailsView(toast: $toast, viewModel: viewModel)
                    .takeSizeEagerly()
            }
        )
        .toastView(toast: $toast)
    }
}

#Preview {
    TransformingScreen()
}
