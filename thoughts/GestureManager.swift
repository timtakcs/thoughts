//
//  GestureManager.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/21/25.
//

import UIKit

enum GestureOwner {
    case container
    case textView
}

class GestureManager: NSObject {
    weak var containerView: ContainerView?
    weak var editorView: EditorView?

    var onDragChanged: ((EditorContainer.Value) -> Void)?
    var onDragEnded: ((EditorContainer.Value) -> Void)?

    var currentContainerOffset: CGFloat = 0

    private var currentOwner: GestureOwner = .container
    private var textViewStartOffset: CGFloat = 0
    private var containerStartOffset: CGFloat = 0

    private var gestureStartOffset: CGFloat = 0
    private var transitionTranslationY: CGFloat = 0

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let containerView = containerView,
              let editorView = editorView else { return }

        let translation = gesture.translation(in: containerView)
        let velocity = gesture.velocity(in: containerView)
        let location = gesture.location(in: containerView)

        switch gesture.state {
        case .began:
            textViewStartOffset = editorView.contentOffsetY
            containerStartOffset = currentContainerOffset
            currentOwner = determineInitialOwner(velocity: velocity)

            gestureStartOffset = editorView.contentOffsetY

            if currentOwner == .container && velocity.y > 0 {
                editorView.dismissKeyboard()
            } else if currentOwner == .textView {
                editorView.dismissKeyboard()
            }

        case .changed:
            let previousOwner = currentOwner
            currentOwner = updateOwnerDuringDrag(
                translation: translation,
                velocity: velocity,
                startOffset: gestureStartOffset
            )

            var effectiveTranslation = translation
            if currentOwner != previousOwner {
                gesture.setTranslation(.zero, in: containerView)
                effectiveTranslation = .zero

                if currentOwner == .textView {
                    gestureStartOffset = editorView.contentOffsetY
                } else {
                    containerStartOffset = currentContainerOffset
                }

                editorView.dismissKeyboard()
            }

            switch currentOwner {
            case .container:
                let adjustedTranslationY = effectiveTranslation.y
                let value = EditorContainer.Value(
                    location: location,
                    translation: CGPoint(x: translation.x, y: adjustedTranslationY),
                    velocity: velocity
                )
                onDragChanged?(value)

            case .textView:
                let newOffset = gestureStartOffset - effectiveTranslation.y
                editorView.setContentOffset(newOffset, allowOverscroll: true)
            }

        case .ended, .cancelled:
            switch currentOwner {
            case .container:
                let absoluteOffset = translation.y
                let value = EditorContainer.Value(
                    location: location,
                    translation: CGPoint(x: 0, y: absoluteOffset),
                    velocity: velocity
                )
                onDragEnded?(value)

            case .textView:
                editorView.finishScrolling(velocity: velocity)
            }
            currentOwner = .container
            transitionTranslationY = 0

        default:
            break
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // this should tell uikit that this gesture manager needs to fail before anything else can be called
        return true
    }

    private func determineInitialOwner(velocity: CGPoint) -> GestureOwner {
        guard let editorView = editorView else { return .container }
        
        let isAtTop = editorView.isAtTop
        let isPanningDown = velocity.y > 0
        
        if isAtTop && isPanningDown {
            return .container
        } else {
            return .textView
        }
    }
    
    private func updateOwnerDuringDrag(
        translation: CGPoint,
        velocity: CGPoint,
        startOffset: CGFloat
    ) -> GestureOwner {
        guard let editorView = editorView else { return currentOwner }

        switch currentOwner {
        case .textView:
            let isAtTop = editorView.isAtTop
            if isAtTop && velocity.y > 0 {
                return .container
            }
            return .textView

        case .container:
            if translation.y < 0 && velocity.y < 0 {
                return .textView
            }
            return .container
        }
    }
}

extension GestureManager: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let editorView = editorView else { return true }

        // If text is selected, let UITextView handle the gesture for selection manipulation
        if editorView.hasTextSelection {
            return false
        }

        return true
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }
}
