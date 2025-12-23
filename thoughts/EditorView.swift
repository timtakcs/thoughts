//
//  EditorView.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/20/25.
//

import UIKit

class EditorView: UIView {
    private let textView = UITextView()
    private let model: EditorModel
    private var hasSetInitialOffset = false

    private let bulletPrefix = "• "

    var isAtTop: Bool {
        return textView.contentOffset.y <= 0
    }
    
    var contentOffsetY: CGFloat {
        return textView.contentOffset.y
    }
    
    var maxContentOffset: CGFloat {
        return max(0, textView.contentSize.height - textView.bounds.height)
    }
    
    init(model: EditorModel) {
        self.model = model
        super.init(frame: .zero)
        setupTextView()
        loadInitialText()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 20, weight: .regular)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 60, left: 24, bottom: 16, right: 24)
        textView.delegate = self
        textView.contentOffset = .zero

        // Keep scrolling enabled for programmatic control, but disable the pan gesture
        textView.isScrollEnabled = true
        textView.panGestureRecognizer.isEnabled = false

        addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func loadInitialText() {
        if model.text.isEmpty {
            textView.text = bulletPrefix
            model.text = bulletPrefix
        } else {
            textView.text = model.text
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if !hasSetInitialOffset && bounds.height > 0 {
            hasSetInitialOffset = true
            textView.contentOffset = .zero
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.textView.contentOffset = .zero
            }
        }
    }
    
    func dismissKeyboard() {
        textView.resignFirstResponder()
    }
    
    func setContentOffset(_ offsetY: CGFloat) {
        let clampedOffset = max(0, min(offsetY, maxContentOffset))
        textView.contentOffset = CGPoint(x: 0, y: clampedOffset)
    }

    func finishScrolling(velocity: CGPoint) {
        // Could add deceleration animation here later
        // For now, just stop where we are
    }

    func saveText() {
        model.text = textView.text
    }
}

extension EditorView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""

        if text.isEmpty {
            textView.text = bulletPrefix
            model.text = bulletPrefix
            return
        }

        if !text.hasPrefix(bulletPrefix) && !text.isEmpty {
            textView.text = model.text
            return
        }

        model.text = text
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let isNewLine = text == "\n"
        let prefix = (isNewLine ? bulletPrefix : "")
        let bulletCount = (isNewLine ? bulletPrefix.count : 0)

        let currentText = textView.text as NSString
        let newText = currentText.replacingCharacters(in: range, with: text + prefix)

        textView.text = newText

        let newPosition = range.location + text.count + bulletCount
        if let newCursorPosition = textView.position(from: textView.beginningOfDocument, offset: newPosition) {
            textView.selectedTextRange = textView.textRange(from: newCursorPosition, to: newCursorPosition)
        }

        model.text = newText
        return false
    }
}
