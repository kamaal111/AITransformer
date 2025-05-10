//
//  FileSystemTests.swift
//  FileSystem
//
//  Created by Kamaal M Farah on 5/6/25.
//

import Testing
import Foundation
@testable import FileSystem

@Test func getDirectoryInfo() async throws {
    let fileURL = URL(fileURLWithPath: #filePath)
    let directoryURL = fileURL.deletingLastPathComponent()
    let fs = FileSystem()

    let directoryInfo = try await fs.getDirectoryInfo(for: directoryURL).get()
    let foundDirectories = await fs.findDirectories("Resources/Samples/TestDirectory1", in: directoryInfo)

    #expect(foundDirectories.count == 1)

    let foundDirectory = foundDirectories[0]
    let foundFiles = await foundDirectory.getFiles()

    #expect(foundFiles.count == 1)

    let foundFile = foundFiles[0]

    #expect(foundFile.parent == foundDirectory)
    #expect((await foundFile.parent?.getParent()) == (await foundDirectory.getParent()))
}
