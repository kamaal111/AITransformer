//
//  FileSystemTests.swift
//  FileSystem
//
//  Created by Kamaal M Farah on 5/6/25.
//

import Testing
import Foundation
@testable import FileSystem

private let FS = FileSystem()
private let FILE_URL = URL(fileURLWithPath: #filePath)
private let TEST_DIRECTORY = FILE_URL.deletingLastPathComponent()

@Test func getDirectoryInfo() async throws {
    let directoryInfo = try await FS.getDirectoryInfo(for: TEST_DIRECTORY).get()
    let foundDirectories = await FS.findDirectories("Resources/Samples/TestDirectory1", in: directoryInfo)

    #expect(foundDirectories.count == 1)

    let foundDirectory = foundDirectories[0]

    #expect(foundDirectory.fileCount == 1)

    let foundFile = foundDirectory.files[0]

    #expect(foundFile.parent == foundDirectory)
    #expect(foundFile.parent?.parent == foundDirectory.parent)
}

@Test func getDirectoryInfoWithIgnoring() async throws {
    let directoryURL = TEST_DIRECTORY.appending(path: "Resources/Samples/TestDirectory2", directoryHint: .isDirectory)
    let directoryInfo = try await FS.getDirectoryInfo(for: directoryURL, ignoringRuleFilenames: [".ignored"]).get()

    #expect(directoryInfo.fileCount == 1)
    #expect(directoryInfo.files.count == 1)
    let file = try #require(directoryInfo.files.first)
    #expect(file.name == "NotIgnored.swift")
}
