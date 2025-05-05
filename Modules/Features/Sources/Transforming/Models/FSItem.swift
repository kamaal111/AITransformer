//
//  FSItem.swift
//  Features
//
//  Created by Kamaal M Farah on 5/3/25.
//

import Foundation

enum FSItemTypes {
    case file
    case folder
}

final class FSItem: Hashable, Equatable, Sendable {
    let type: FSItemTypes
    let url: URL
    let parent: FSItem?

    private let _content: String?
    private let _items: [FSItem]?
    let isLazy: Bool

    private init(type: FSItemTypes, url: URL, parent: FSItem?, content: String?, items: [FSItem]?, isLazy: Bool) {
        self.type = type
        self.url = url
        if parent?.type == .folder {
            self.parent = parent
        } else {
            assert(parent == nil, "Parent should always be a folder")
            self.parent = nil
        }
        self._content = content
        self._items = items
        self.isLazy = isLazy
    }

    var content: String {
        assert(isFile, "Only file type should have content")
        assert(_content != nil, "File should not have nil as content")
        assert(!isLazy, "Exchange file with non lazy one with `getFileWithContent` first")

        return _content ?? ""
    }

    var isFolder: Bool {
        type == .folder
    }

    var isFile: Bool {
        type == .file
    }

    var name: String {
        url.lastPathComponent
    }

    var isEmpty: Bool {
        if isFile {
            return content.isEmpty
        }

        return items.isEmpty
    }

    var items: [FSItem] {
        assert(isFolder, "Only folder type holds items")
        assert(_items != nil, "Folder should not have nil as items")

        return _items ?? []
    }

    func getFileWithContent() -> FSItem {
        assert(isFile)
        if _content != nil {
            return self
        }

        assert(isLazy)
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            assertionFailure("What happened here?")
            return self
        }

        return Self.createAsFile(url: url, content: content, parent: parent)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    func getCount() -> Int {
        if isFile {
            return 1
        }

        return items.count
    }

    func setParent(_ parent: FSItem) -> FSItem {
        guard parent.isFolder else {
            assertionFailure("Should only be setting parent of folder types")
            return self
        }

        return FSItem(type: type, url: url, parent: parent, content: _content, items: _items, isLazy: isLazy)
    }

    func setItems(_ items: [FSItem]) -> FSItem {
        guard isFolder else {
            assertionFailure("Should only be setting items to folder types")
            return self
        }

        return FSItem.createAsFolder(url: url, items: items, parent: parent)
    }

    static func createAsFile(url: URL, content: String, parent: FSItem?) -> FSItem {
        .init(type: .file, url: url, parent: parent, content: content, items: nil, isLazy: false)
    }

    static func createAsLazyFile(url: URL, parent: FSItem?) -> FSItem {
        .init(type: .file, url: url, parent: parent, content: nil, items: nil, isLazy: true)
    }

    static func createAsFolder(url: URL, items: [FSItem], parent: FSItem?) -> FSItem {
        .init(type: .folder, url: url, parent: parent, content: nil, items: items, isLazy: false)
    }

    static func == (lhs: FSItem, rhs: FSItem) -> Bool {
        lhs.url == rhs.url
    }

}
