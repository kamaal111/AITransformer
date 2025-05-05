//
//  SwiftUIView.swift
//  Features
//
//  Created by Kamaal M Farah on 5/4/25.
//

import SwiftUI
import DesignSystem

struct TransformingScreenSidebar: View {
    @State var viewModel: TransformingViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: handleFileOpenClick) {
                HStack {
                    Text("Click here to upload items")
                        .lineLimit(2)
                    Image(systemName: "square.and.arrow.up.fill")
                }
                .bold()
                .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .takeWidthEagerly(alignment: .center)
            .padding(.bottom, .small)
            .disabled(viewModel.loadingOpenedItem)
            if let openedItem = viewModel.openedItem {
                Text("Files")
                    .font(.headline)
                    .bold()
                AppTextField(text: $viewModel.itemPathsToIgnore, localizedTitle: "Paths to ignore", bundle: .module)
                List {
                    ListItemStructureView(item: openedItem)
                }
            }
        }
        .takeSizeEagerly(alignment: .topLeading)
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
        leftView: { TransformingScreenSidebar(viewModel: viewModel) },
        rightView: { Text("hi").takeWidthEagerly() }
    )
}
