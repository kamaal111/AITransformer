//
//  SwiftUIView.swift
//  Features
//
//  Created by Kamaal M Farah on 5/4/25.
//

import SwiftUI
import DesignSystem

struct TransformingScreenSidebar: View {
    @Binding var toast: Toast?

    @State var viewModel: TransformingViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("Files")
                .font(.headline)
                .bold()
            Button(action: handleFileOpenClick) {
                Text("Open a folder to transform")
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
            if let openedItem = viewModel.openedItem {
                List {
                    ListItemStructureView(item: openedItem)
                }
            }
        }
        .takeHeightEagerly(alignment: .top)
        .padding(.vertical, .medium)
        .padding(.horizontal, .medium)
    }

    private func handleFileOpenClick() {
        Task { await viewModel.openFilePicker() }
    }
}

#Preview {
    @Previewable @State var viewModel = TransformingViewModel()

    TwoColumnView(
        leftView: { TransformingScreenSidebar(toast: .constant(nil), viewModel: viewModel) },
        rightView: { Text("hi").takeWidthEagerly() }
    )
}
