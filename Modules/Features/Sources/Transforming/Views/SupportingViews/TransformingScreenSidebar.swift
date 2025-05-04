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
                Text("Pick a file to transform")
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
            ForEach(viewModel.openedFiles, id: \.url) { file in
                Text(file.name)
            }
        }
        .takeHeightEagerly(alignment: .top)
        .padding(.vertical, .medium)
        .padding(.horizontal, .medium)
    }

    private func handleFileOpenClick() {
        viewModel.openFilePicker()
            .onFailure { toast = .error(message: $0.localizedDescription) }
    }
}

#Preview {
    @Previewable @State var viewModel = TransformingViewModel()

    TwoColumnView(
        leftView: { TransformingScreenSidebar(toast: .constant(nil), viewModel: viewModel) },
        rightView: { Text("hi").takeWidthEagerly() }
    )
}
