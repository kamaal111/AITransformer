//
//  FileItem.swift
//  Features
//
//  Created by Kamaal M Farah on 5/3/25.
//

import Foundation

struct FileItem: Hashable {
    let content: String
    let url: URL

    var name: String {
        url.lastPathComponent
    }
}
