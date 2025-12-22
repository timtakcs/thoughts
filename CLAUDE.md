# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"thoughts" is an iOS note-taking app built with SwiftUI and UIKit. It features a bullet-point based editor with location tracking for each note. The app uses GRDB.swift for SQLite persistence and implements custom gesture-based UI interactions.

## Build & Test Commands

### Building
```bash
# Install dependencies (required after cloning or when Podfile changes)
pod install

# Open the workspace (NOT the .xcodeproj file)
open thoughts.xcworkspace

# Build the app in Xcode
# Use Cmd+B or Product > Build
```

### Testing
```bash
# Run all tests
# Use Cmd+U or Product > Test in Xcode

# Run specific test class
# Use the test navigator (Cmd+6) and click the diamond next to the test class
```

### Important
- Always use `thoughts.xcworkspace` NOT `thoughts.xcodeproj` when opening in Xcode (CocoaPods requirement)
- Run `pod install` if you modify the Podfile or after cloning the repository
- The project uses sandboxing disabled (`ENABLE_USER_SCRIPT_SANDBOXING = NO`) for CocoaPods compatibility

## Architecture

### Core Data Flow
1. **App Entry** (`thoughtsApp.swift`) → Displays the main `List` view
2. **List View** (`List.swift`) → Manages the note list display and floating action button
   - Initializes the database (`DB.swift`) on creation
   - Maintains active note state for editing
   - Coordinates between note list and editor overlay
3. **Database Layer** (`DB.swift`) → Handles all SQLite operations via GRDB
4. **Editor System** → Split between SwiftUI and UIKit implementations:
   - `EditorContainer.swift` - UIViewRepresentable bridge with custom drag gesture handling
   - `EditorView.swift` - UIKit-based text editor with bullet-point logic
   - `Editor.swift` - Original SwiftUI TextEditor (currently unused, but in codebase)

### UI Architecture Pattern
The app uses a **hybrid UIKit/SwiftUI approach**:
- Main navigation and state management: SwiftUI (`List.swift`)
- Custom interactive components: UIKit via UIViewRepresentable
  - `NoteListView` wraps UITableView for better swipe-to-delete control
  - `EditorContainer` wraps custom UITextView for advanced gesture handling

### Database Schema
```sql
CREATE TABLE note (
    id INTEGER PRIMARY KEY,
    content TEXT NOT NULL,
    date REAL NOT NULL,
    longitude REAL NOT NULL,
    latitude REAL NOT NULL
)
```

### Editor Interaction Model
The editor uses a modal overlay pattern:
1. Slides up from bottom with spring animation (`editorOffset` state)
2. Dismisses via drag-down gesture when UITextView is scrolled to top
3. Auto-saves on dismiss if content is non-empty
4. Supports both create (new note) and edit (existing note) modes via `activeNoteId`

### Key Implementation Details

**Bullet Point System**: All notes must start with "• " prefix. The EditorView enforces this by:
- Preventing deletion of the prefix
- Auto-inserting "• " after newlines
- Resetting to "• " if text becomes empty

**Note Filtering on Save**: Notes containing only "• " and whitespace are discarded (see `List.swift:130-135`)

**Location Data**: Currently hardcoded to Singapore coordinates (`singaporeLocation` in `List.swift:11-14`). Each note stores lat/long but location services are not implemented.

**Animation**: Uses spring animations with consistent parameters:
- Response: 0.3
- Damping: 0.7-0.8

**Gesture Conflict Resolution**: The EditorContainer's coordinator implements `gestureRecognizerShouldBegin` to only allow drag-down when:
1. User is dragging downward (velocity.y > 0)
2. TextView is at scroll top position (isAtTop)

## Testing Strategy

Tests use in-memory SQLite database (`:memory:` path) to avoid filesystem dependencies:
```swift
db = try DB(filename: ":memory")
```

Current test coverage focuses on database CRUD operations (`DBTests.swift`). No UI tests exist yet.
