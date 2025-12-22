//
//  DBTests.swift
//  thoughtsTests
//
//  Created by Timur Takhtarov on 12/9/25.
//

import XCTest
import CoreLocation
@testable import thoughts

final class DBTests: XCTestCase {
    var db: DB!

    override func setUpWithError() throws {
        db = try DB(filename: ":memory")
    }

    override func tearDownWithError() throws {
        db = nil
    }

    func testSaveAndFetchNotesFlow() throws {
        let dummyLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco

        let initialNotes = try db.fetchAllNotes()
        XCTAssertTrue(initialNotes.isEmpty, "Database should be empty initially")

        try db.saveNote(content: "First note", location: dummyLocation)
        try db.saveNote(content: "Second note", location: dummyLocation)

        let notesAfterTwo = try db.fetchAllNotes()
        XCTAssertEqual(notesAfterTwo.count, 2, "Should have exactly 2 notes after saving twice")

        XCTAssertTrue(notesAfterTwo.contains { $0.content == "First note" })
        XCTAssertTrue(notesAfterTwo.contains { $0.content == "Second note" })

        try db.saveNote(content: "Third note", location: dummyLocation)

        let notesAfterThree = try db.fetchAllNotes()
        XCTAssertEqual(notesAfterThree.count, 3, "Should have exactly 3 notes after saving third time")

        if let firstNote = notesAfterThree.first {
            print("Most recent note: \(firstNote.content)")
            XCTAssertNotNil(firstNote.id, "Note should have a database ID assigned")
            XCTAssertEqual(firstNote.latitude, 37.7749, accuracy: 0.0001)
        }
    }
}
