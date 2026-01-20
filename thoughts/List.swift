//
//  List.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/2/25.
//

import SwiftUI
import CoreLocation
import GRDB

let singaporeLocation = CLLocation(
    latitude: 1.290270,
    longitude: 103.851959
)

@Observable public final class EditorModel {
    var text: String = ""
}

struct List: View {
    let db: DB

    @State private var notes: [Note] = []
    @State private var notesObservation: AnyDatabaseCancellable?
    @State private var newNote: Bool = false
    @State private var activeNoteId: Int64? = nil
    @State private var editorOffset: CGFloat = UIScreen.main.bounds.height
    @State private var editorModel: EditorModel = .init()

    private let separatorWidthRatio: CGFloat = 0.9

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Main Content
            VStack {
//                Text("What here??")
//                    .font(.iosevka(size: 34, weight: .bold))
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal, 24)
//                    .padding(.top, 24)
//                    .padding(.bottom, 24)
                NoteListView(
                    notes: notes,
                    onNoteTap: { note in
                        if let noteId = note.id {
                            activeNoteId = noteId
                            editorModel.text = note.content
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                editorOffset = 0
                            }
                        }
                    },
                    onNoteDelete: { note in
                        deleteNote(note)
                    }
                )
                .ignoresSafeArea(edges: .bottom)
            }

            // MARK: - Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        activeNoteId = nil
                        editorModel.text = ""
                        newNote = true
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            editorOffset = 0
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.iosevka(size: 24, weight: .bold))
                            .foregroundColor(.black.opacity(1.0))
                            .frame(width: 50, height: 50)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 0)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 32)
                    .padding(.bottom, 67)
                }
            }

            // MARK: - Editor Overlay
            EditorContainer(model: editorModel,
                            newNote: newNote,
                            onDismiss: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    editorOffset = UIScreen.main.bounds.height
                                    newNote = false
                                    saveNoteAndRefresh()
                                }
            })
            .offset(y: editorOffset)
            .ignoresSafeArea(edges: .bottom)
        }
        .background(Color.appBackground.ignoresSafeArea(edges: .top))
        .onAppear {
            let observation = ValueObservation.tracking { db in
                try Note.fetchAll(db, sql: "SELECT * FROM note ORDER BY date DESC")
            }

            notesObservation = observation.start(in: db.dbQueue, scheduling: .immediate) { error in
                print("Observation error: \(error)")
            } onChange: { newNotes in
                withAnimation(.easeInOut(duration: 0.3)) {
                    notes = newNotes
                }
            }
        }
    }

    private func saveNoteAndRefresh() {
        let noteText = editorModel.text

        var emptyNoteCharacters = CharacterSet.whitespacesAndNewlines
        emptyNoteCharacters.insert(charactersIn: "•")

        guard !noteText.trimmingCharacters(in: emptyNoteCharacters).isEmpty else {
            editorModel.text = ""
            activeNoteId = nil
            return
        }

        do {
            if let noteId = activeNoteId {
                try db.updateNote(id: noteId, content: noteText)
            } else {
                try db.saveNote(content: noteText, location: singaporeLocation)
            }

            editorModel.text = ""
            activeNoteId = nil
        } catch {
            print("Failed to save note: \(error)")
        }
    }

    private func deleteNote(_ note: Note) {
        guard let noteId = note.id else { return }

        do {
            try db.deleteNote(id: noteId)
        } catch {
            print("Failed to delete note: \(error)")
        }
    }
}

#Preview {
    List(db: try! DB())
}
