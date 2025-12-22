//
//  DB.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/6/25.
//

import Foundation
import CoreLocation
import GRDB

struct Note: Identifiable {
    var id: Int64?
    let date: Date
    let content: String
    let latitude: Double
    let longitude: Double
}

extension Note: FetchableRecord {
    enum Columns {
        static let id = Column("id")
        static let content = Column("content")
        static let date = Column("date")
        static let latitude = Column("latitude")
        static let longitude = Column("longitude")
    }

    init(row: Row) throws {
        self.id = row[Columns.id]
        self.content = row[Columns.content]
        self.date = row[Columns.date]
        self.latitude = row[Columns.latitude]
        self.longitude = row[Columns.longitude]
    }
}

struct DB {
    let dbQueue: DatabaseQueue

    init(filename: String = "thoughts") throws {
        self.dbQueue = try DatabaseQueue(path: DB.sqlitePath(filename: filename))

        try dbQueue.write { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS note (
                    id INTEGER PRIMARY KEY,
                    content TEXT NOT NULL,
                    date REAL NOT NULL,
                    longitude REAL NOT NULL,
                    latitude REAL NOT NULL
                );
                """
            )
        }
    }

    func saveNote(content: String, location: CLLocation) throws {
        let date = Date()
        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO note (content, date, longitude, latitude) VALUES (?, ?, ?, ?)",
                arguments: [content,
                            date,
                            location.coordinate.longitude,
                            location.coordinate.latitude
                           ]
            )
        }
    }

    func fetchAllNotes() throws -> [Note] {
        try dbQueue.read { db in
            try Note.fetchAll(
                db,
                sql: "SELECT * FROM note ORDER BY date DESC")
        }
    }

    func deleteNote(id: Int64) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM note WHERE id = ?",
                arguments: [id]
            )
        }
    }

    func updateNote(id: Int64, content: String) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE note SET content = ? WHERE id = ?",
                arguments: [content, id]
            )
        }
    }

    static func sqlitePath(filename: String) -> String {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("thoughts").appendingPathExtension("sqlite")
            return fileUrl.path
        } catch {
            print("ERROR: cannot connect to db - using empty path")
            return ""
        }
    }
}
