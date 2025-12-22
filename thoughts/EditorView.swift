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
    
    private let bulletPrefix = "• "
    
    var isAtTop: Bool {
        return textView.contentOffset.y <= 0
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
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.textView.becomeFirstResponder()
            }
        }
    }
    
    func dismissKeyboard() {
        textView.resignFirstResponder()
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
