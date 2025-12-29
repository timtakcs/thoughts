//
//  EditorContainer.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/3/25.
//

import UIKit
import SwiftUI

struct EditorContainer: UIViewRepresentable {
    var offset: Binding<CGFloat>
    let model: EditorModel
    
    private let onDragChanged: (Value) -> Void
    private let onDragEnded: (Value) -> Void
    
    public init(
        offset: CGFloat,
        model: EditorModel
    ) {
        self.init(
            offset: offset,
            model: model,
            onDragChanged: { _ in },
            onDragEnded: { _ in }
        )
    }
    
    internal init(
        offset: CGFloat,
        model: EditorModel,
        onDragChanged: @escaping (Value) -> Void,
        onDragEnded: @escaping (Value) -> Void
    ) {
        self.offset = .constant(offset)
        self.model = model
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
    }
    
    public func onDragChanged(_ action: @escaping (Value) -> Void) -> EditorContainer {
        EditorContainer(
            offset: offset.wrappedValue,
            model: model,
            onDragChanged: action,
            onDragEnded: onDragEnded
        )
    }
    
    public func onDragEnded(_ action: @escaping (Value) -> Void) -> EditorContainer {
        EditorContainer(
            offset: offset.wrappedValue,
            model: model,
            onDragChanged: onDragChanged,
            onDragEnded: action
        )
    }
    
    func makeUIView(context: Context) -> ContainerView {
        let containerView = ContainerView()
        
        let editorView = EditorView(model: model)
        containerView.editorView = editorView
        
        editorView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(editorView)
        
        NSLayoutConstraint.activate([
            editorView.topAnchor.constraint(equalTo: containerView.topAnchor),
            editorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            editorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        let capsule = UIView()
        capsule.backgroundColor = UIColor.systemGray3.withAlphaComponent(0.3)
        capsule.layer.cornerRadius = 2.5
        capsule.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(capsule)
        
        NSLayoutConstraint.activate([
            capsule.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            capsule.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            capsule.widthAnchor.constraint(equalToConstant: 40),
            capsule.heightAnchor.constraint(equalToConstant: 5)
        ])
        
        let gestureManager = context.coordinator.gestureManager
        gestureManager.containerView = containerView
        gestureManager.editorView = editorView

        gestureManager.onDragChanged = onDragChanged
        gestureManager.onDragEnded = onDragEnded

        gestureManager.currentContainerOffset = offset.wrappedValue

        let panGesture = UIPanGestureRecognizer(
            target: gestureManager,
            action: #selector(GestureManager.handlePan(_:))
        )
        panGesture.delegate = gestureManager
        containerView.addGestureRecognizer(panGesture)
        
        context.coordinator.containerView = containerView
        
        return containerView
    }
    
    public func updateUIView(_ uiView: ContainerView, context: Context) {
        // Check if we need to reload from model
        if context.coordinator.lastReloadTrigger != model.reloadTrigger {
            context.coordinator.lastReloadTrigger = model.reloadTrigger
            uiView.editorView?.loadFromModel()
        }

        uiView.editorView?.saveText()

        context.coordinator.gestureManager.currentContainerOffset = offset.wrappedValue
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: EditorContainer
        var containerView: ContainerView?
        let gestureManager = GestureManager()
        var lastReloadTrigger: UUID?

        init(_ parent: EditorContainer) {
            self.parent = parent
        }
    }
    
    public struct Value {
        public let location: CGPoint
        public let translation: CGPoint
        public let velocity: CGPoint
    }
}

class ContainerView: UIView {
    var editorView: EditorView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
