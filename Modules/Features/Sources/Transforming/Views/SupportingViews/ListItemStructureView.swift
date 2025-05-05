//
//  ListItemStructureView.swift
//  Features
//
//  Created by Kamaal M Farah on 5/5/25.
//

import SwiftUI

struct ListItemStructureView: View {
    let item: FSItem
    let level: Int

    private init(item: FSItem, level: Int) {
        self.item = item
        self.level = level
    }

    init(item: FSItem) {
        self.init(item: item, level: 0)
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<level, id: \.self) { _ in
                Text("􀀁")
                    .font(.system(size: 2))
                    .foregroundStyle(.tertiary)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: item.isFolder ? "folder" : "text.page")
                    Text(item.name)
                        .lineLimit(1)
                }
                if item.isFolder {
                    ForEach(item.items, id: \.url) { item in
                        ListItemStructureView(item: item, level: level + 1)
                    }
                }
            }
        }
    }
}

#Preview {
    ListItemStructureView(
        item: .createAsLazyFile(url: URL.applicationDirectory.appendingPathComponent("Xcode.app"), parent: nil)
    )
}
