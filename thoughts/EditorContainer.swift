//
//  EditorContainer.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/3/25.
//

import UIKit
import SwiftUI

struct EditorContainer: UIViewRepresentable {
    let model: EditorModel
    let onDismiss: () -> Void

    func makeUIView(context: Context) -> ContainerView {
        let containerView = ContainerView()

        let editorView = EditorView(
            text: model.text,
            onTextChange: { newtext in
                model.text = newtext
            },
            onDismiss: onDismiss
        )

        containerView.editorView = editorView

        editorView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(editorView)

        NSLayoutConstraint.activate([
            editorView.topAnchor.constraint(equalTo: containerView.topAnchor),
            editorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            editorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        context.coordinator.containerView = containerView

        return containerView
    }

    public func updateUIView(_ uiView: ContainerView, context: Context) {
        uiView.editorView?.setText(text: model.text)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: EditorContainer
        var containerView: ContainerView?

        init(_ parent: EditorContainer) {
            self.parent = parent
        }
    }
}

class ContainerView: UIView {
    var editorView: EditorView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .appBackground
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
