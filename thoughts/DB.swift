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
    let updated: Date
    let content: String
    let latitude: Double
    let longitude: Double
}

extension Note: FetchableRecord {
    enum Columns {
        static let id = Column("id")
        static let content = Column("content")
        static let date = Column("date")
        static let updated = Column("updated")
        static let latitude = Column("latitude")
        static let longitude = Column("longitude")
    }

    init(row: Row) throws {
        self.id = row[Columns.id]
        self.content = row[Columns.content]
        self.date = row[Columns.date]
        self.updated = row[Columns.updated]
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
                    updated REAL NOT NULL,
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
                sql: "INSERT INTO note (content, date, updated, longitude, latitude) VALUES (?, ?, ?, ?, ?)",
                arguments: [content,
                            date,
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

    func deleteNotes(ids: [Int64]) throws {
        guard !ids.isEmpty else { return }
        try dbQueue.write { db in
            let placeholders = ids.map { _ in "?" }.joined(separator: ", ")
            try db.execute(
                sql: "DELETE FROM note WHERE id IN (\(placeholders))",
                arguments: StatementArguments(ids)
            )
        }
    }

    func updateNote(id: Int64, content: String) throws {
        let date = Date()
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE note SET content = ?, updated = ? WHERE id = ?",
                arguments: [content, date, id]
            )
        }
    }

    func upsertNotes(notes: [SyncNote]) throws {
        try dbQueue.write { db in
            for note in notes {
                try db.execute(
                    sql: """
                        INSERT INTO note (id, content, date, longitude, latitude, updated)
                        VALUES (?, ?, ?, ?, ?, ?)
                        ON CONFLICT(id) DO UPDATE SET
                            content = excluded.content,
                            updated = excluded.updated
                        """,
                    arguments: [note.id, note.content, note.date, note.longitude, note.latitude, note.updated]
                )
            }
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
