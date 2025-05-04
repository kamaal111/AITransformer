//
//  TwoColumnView.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 5/4/25.
//

import SwiftUI

public struct TwoColumnView<LeftView: View, RightView: View>: View {
    let leftView: () -> LeftView
    let rightView: () -> RightView

    public init(@ViewBuilder leftView: @escaping () -> LeftView, @ViewBuilder rightView: @escaping () -> RightView) {
        self.leftView = leftView
        self.rightView = rightView
    }

    public var body: some View {
        HStack {
            leftView()
            Capsule()
                .frame(width: 0.5)
                .foregroundStyle(.tertiary)
            rightView()
        }
    }
}

#Preview {
    TwoColumnView(leftView: { Text("Left") }, rightView: { Text("Right") })
}
