//
//  Editor.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/2/25.
//

import SwiftUI

struct Editor: View {
    @Bindable var model: EditorModel

    @FocusState private var isFocused: Bool

    @State private var hasCrossedThreshold = false
    @State private var offsetY: CGFloat = 0

    @Environment(\.dismiss) private var dismiss

    private let bulletIcon = "•"
    private let bulletPrefix = "• "
    private let dismissThreshold: CGFloat = 150

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                TextEditor(text: $model.text)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .font(.system(size: 20, weight: .regular))
                    .lineSpacing(8)
                    .scrollContentBackground(.hidden)
                    .onChange(of: model.text) { oldValue, newValue in
                        handleTextChange(oldValue: oldValue, newValue: newValue)
                    }
                    .onAppear {
                        model.text = bulletPrefix
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused = true
                        }
                    }
            }
            .background(Color(UIColor.systemBackground))
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func handleTextChange(oldValue: String, newValue: String) {
        if newValue.count > oldValue.count && newValue.last == "\n" {
            model.text = newValue + bulletPrefix
        }

        if !newValue.hasPrefix(bulletPrefix) && !newValue.isEmpty {
            model.text = oldValue
        }

        if newValue.isEmpty {
            model.text = bulletPrefix
        }
    }
}

#Preview {
    Editor(model: EditorModel())
}
