//
//  List.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/2/25.
//

import SwiftUI
import CoreLocation

let singaporeLocation = CLLocation(
    latitude: 1.290270,
    longitude: 103.851959
)

@Observable public final class EditorModel {
    var text: String = "• \n•  \n•  \n•  \n• d \n•  \n•  \n•  \n•  \n•  \n•  \n•  \n•  \n•  \n•  \n•  \n•  \n•  \n•  \n•  \n• why is this not working •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n •  \n"
}

struct List: View {
    @State private var notes: [Note] = []

    @State private var activeNoteId: Int64? = nil
    @State private var showingEditor = false
    @State private var editorOffset: CGFloat = UIScreen.main.bounds.height

    private let separatorWidthRatio: CGFloat = 0.9
    private let editorModel: EditorModel = .init()
    private let db: DB

    init() {
        do {
            self.db = try DB()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Main Content
            VStack {
                Text("What here??")
                    .font(.system(size: 34, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                NoteListView(
                    notes: notes,
                    onNoteTap: { note in
                        if let noteId = note.id {
                            activeNoteId = noteId
                            editorModel.text = note.content
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingEditor = true
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
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingEditor = true
                            editorOffset = 0
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.black.opacity(1.0))
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 32)
                    .padding(.bottom, 67)
                }
            }

            // MARK: - Editor Overlay
            EditorContainer(offset: editorOffset, model: editorModel)
                .onDragChanged { value in
                    editorOffset = max(0.0, value.translation.y)
                }
                .onDragEnded { value in
                    if value.translation.y > 200 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            editorOffset = UIScreen.main.bounds.height
                            saveNoteAndRefresh()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            editorOffset = 0
                        }
                    }
                }
                .offset(y: editorOffset)
                .ignoresSafeArea(edges: .bottom)
        }
        .onAppear() {
            loadNotes()
        }
    }

    private func loadNotes() {
        do {
            notes = try db.fetchAllNotes()
        } catch {
            print("Failed to load notes: \(error)")
        }
    }

    private func saveNoteAndRefresh() {
        let noteText = editorModel.text

        var emptyNoteCharacters = CharacterSet.whitespacesAndNewlines
        emptyNoteCharacters.insert(charactersIn: "•")

        guard !noteText.trimmingCharacters(in: emptyNoteCharacters).isEmpty else {
            return
        }

        do {
            if let noteId = activeNoteId {
                try db.updateNote(id: noteId, content: noteText)
            } else {
                try db.saveNote(content: noteText, location: singaporeLocation)
            }

            editorModel.text = "will this show"
            print("this does get called from the list")
            activeNoteId = nil

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loadNotes()
                }
            }
        } catch {
            print("Failed to save note: \(error)")
        }
    }

    private func deleteNote(_ note: Note) {
        guard let noteId = note.id else { return }

        do {
            try db.deleteNote(id: noteId)
            withAnimation(.easeInOut(duration: 0.3)) {
                loadNotes()
            }
        } catch {
            print("Failed to delete note: \(error)")
        }
    }
}

#Preview {
    List()
}
