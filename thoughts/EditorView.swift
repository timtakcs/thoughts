//
//  EditorView.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/20/25.
//

import UIKit

class EditorView: UIView {
    private let textView = UITextView()
    private let onTextChange: (String) -> Void
    private let onDismiss: () -> Void
    private let dismissThreshold: CGFloat = -60

    private var hasTriggeredHaptic = false
    private var hasSetInitialOffset = false
    private var keyboardHeight: CGFloat = 0

    private let bulletPrefix = "• "

    init(text: String,
         onTextChange: @escaping (String) -> Void,
         onDismiss: @escaping () -> Void) {
        self.onTextChange = onTextChange
        self.onDismiss = onDismiss
        super.init(frame: .zero)

        setupTextView()
        setupKeyboardObservers()
        setText(text: text)
    }

    func setText(text: String) {
        if text.isEmpty {
            textView.text = bulletPrefix
        } else {
            textView.text = text
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false

        let customFont = UIFont.iosevka(size: 18, weight: .light)
        textView.font = customFont
        textView.backgroundColor = .clear
        textView.tintColor = .white

        textView.textContainerInset = UIEdgeInsets(top: 30, left: 24, bottom: 0, right: 24)
        textView.delegate = self
        textView.contentOffset = .zero


        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 16
        paragraphStyle.lineSpacing = 6

        textView.typingAttributes = [
            .font: customFont,
            .paragraphStyle: paragraphStyle
        ]

        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .onDrag

        addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            keyboardHeight = keyboardFrame.height
            textView.contentInset.bottom = keyboardHeight
            textView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        keyboardHeight = 0
        textView.contentInset.bottom = keyboardHeight
        textView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !hasSetInitialOffset && bounds.height > 0 {
            hasSetInitialOffset = true
        }
    }

}

extension EditorView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""

        if text.isEmpty {
            textView.text = bulletPrefix
            return
        }

        if !text.hasPrefix(bulletPrefix) && !text.isEmpty {
            textView.text = bulletPrefix
            return
        }

        onTextChange(textView.text)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let currentText = textView.text as NSString
            let newText = currentText.replacingCharacters(in: range, with: "\n" + bulletPrefix)
            textView.text = newText

            let newPosition = range.location + 1 + bulletPrefix.count
            if let newCursorPosition = textView.position(from: textView.beginningOfDocument, offset: newPosition) {
                textView.selectedTextRange = textView.textRange(from: newCursorPosition, to: newCursorPosition)
            }

            onTextChange(textView.text)

            return false
        }

        return true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < dismissThreshold && !hasTriggeredHaptic {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            hasTriggeredHaptic = true
        }
        if scrollView.contentOffset.y >= dismissThreshold {
            hasTriggeredHaptic = false
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y < dismissThreshold {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.onDismiss()
            }
        }
    }
}
