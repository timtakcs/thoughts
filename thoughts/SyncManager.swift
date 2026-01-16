//
//  SyncManager.swift
//  thoughts
//
//  Created by Timur Takhtarov on 1/4/26.
//

import Foundation

struct SyncNote: Codable {
    let id: Int64
    let content: String
    let date: Double
    let updated: Double
    let longitude: Double
    let latitude: Double
}

struct SyncResponse: Codable {
    let delete: [Int64]
    let update: [SyncNote]
    let load: [SyncNote]
}

enum SyncError: Error {
    case serverError
}

struct SyncManager {
    let db: DB
    let baseURL: URL

    init(db: DB, baseURL: String = "https://timurs-macbook-pro.tail8ed7b5.ts.net:8000") {
        self.db = db
        self.baseURL = URL(string: baseURL)! // im just hardcoding this
    }

    func convertNote(note: Note) -> SyncNote {
        .init(
            id: note.id!, // should only miss an id when not saved
            content: note.content,
            date: note.date.timeIntervalSince1970,
            updated: note.updated.timeIntervalSince1970,
            longitude: note.longitude,
            latitude: note.latitude
        )
    }

    func sync() async throws {
        let notes = try db.fetchAllNotes().map(convertNote)
        var request = URLRequest(url: self.baseURL.appendingPathComponent("sync"))

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(notes)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SyncError.serverError
        }

        let syncResponse = try JSONDecoder().decode(SyncResponse.self, from: data)

        try db.deleteNotes(ids: syncResponse.delete)
        try db.upsertNotes(notes: syncResponse.load + syncResponse.update)
    }
}
