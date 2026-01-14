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
    private var hasSetInitialOffset = false
    private var keyboardHeight: CGFloat = 0

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

    var hasTextSelection: Bool {
        guard let selectedRange = textView.selectedTextRange else { return false }
        return selectedRange.start != selectedRange.end
    }

    init(text: String, onTextChange: @escaping (String) -> Void) {
        self.onTextChange = onTextChange
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

        textView.textContainerInset = UIEdgeInsets(top: 60, left: 24, bottom: 30, right: 24)
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
        textView.panGestureRecognizer.isEnabled = false

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
            scrollCursorAboveKeyboard()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        keyboardHeight = 0
    }

    private func scrollCursorAboveKeyboard() {
        guard keyboardHeight > 0 else { return }
        guard let selectedRange = textView.selectedTextRange else { return }

        let cursorRect = textView.caretRect(for: selectedRange.start)
        let targetVisibleY = textView.bounds.height - keyboardHeight - 20
        let targetOffset = cursorRect.maxY - targetVisibleY
        let finalOffset = max(0, targetOffset)

        self.textView.setContentOffset(CGPoint(x: 0, y: finalOffset), animated: false)
  }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !hasSetInitialOffset && bounds.height > 0 {
            hasSetInitialOffset = true
        }
    }

    func dismissKeyboard() {
        textView.resignFirstResponder()
    }
    
    func setContentOffset(_ offsetY: CGFloat, allowOverscroll: Bool = false) {
        let finalOffset: CGFloat

        if allowOverscroll {
            if offsetY > maxContentOffset {
                let overshoot = offsetY - maxContentOffset
                let resistance: CGFloat = 150
                let resistedOvershoot = resistance * (1 - 1 / (1 + overshoot / resistance))
                finalOffset = maxContentOffset + resistedOvershoot
            } else {
                finalOffset = max(0, offsetY)
            }
        } else {
            finalOffset = max(0, min(offsetY, maxContentOffset))
        }

        textView.contentOffset = CGPoint(x: 0, y: finalOffset)
    }

    func finishScrolling(velocity: CGPoint) {
        let currentOffset = textView.contentOffset.y

        if currentOffset > maxContentOffset || currentOffset < 0 {
            let targetOffset = currentOffset > maxContentOffset ? maxContentOffset : 0
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0,
                options: [],
                animations: {
                    self.textView.contentOffset = CGPoint(x: 0, y: targetOffset)
                }
            )
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

        scrollCursorAboveKeyboard()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        scrollCursorAboveKeyboard()
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

              return false
          }

          return true
      }
}
