//
//  thoughtsApp.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/2/25.
//

import SwiftUI

@main
struct thoughtsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let db: DB

    init() {
        do {
            self.db = try DB()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            List(db: db)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                triggerSync()
            }
        }
    }

    private func triggerSync() {
        Task {
            let syncService = SyncManager(db: db)
            do {
                try await syncService.sync()
            } catch {
                print("Sync failed: \(error)")
            }
        }
    }
}
