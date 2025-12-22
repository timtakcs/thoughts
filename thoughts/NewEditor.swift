//
//  NewEditor.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/4/25.
//

import UIKit

class NewEditor: NSObject {
    weak var scrollView: UIScrollView?
    weak var textView: UITextView?

    private let bulletPrefix = "• "

    func makeScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .systemBackground
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        scrollView.bounces = true

        // Create the text view
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 20, weight: .regular)
        textView.backgroundColor = .systemBackground
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24)
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false

        // Create the drag handle
        let handleView = UIView()
        handleView.backgroundColor = .systemGray3
        handleView.layer.cornerRadius = 2.5
        handleView.translatesAutoresizingMaskIntoConstraints = false

        // Create container for handle
        let handleContainer = UIView()
        handleContainer.backgroundColor = .systemBackground
        handleContainer.translatesAutoresizingMaskIntoConstraints = false
        handleContainer.addSubview(handleView)

        // Add subviews
        scrollView.addSubview(handleContainer)
        scrollView.addSubview(textView)

        NSLayoutConstraint.activate([
            // Handle container
            handleContainer.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            handleContainer.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            handleContainer.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            handleContainer.heightAnchor.constraint(equalToConstant: 25),

            // Handle
            handleView.centerXAnchor.constraint(equalTo: handleContainer.centerXAnchor),
            handleView.centerYAnchor.constraint(equalTo: handleContainer.centerYAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 5),

            // Text view
            textView.topAnchor.constraint(equalTo: handleContainer.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor, constant: -25)
        ])

        // Store references
        self.scrollView = scrollView
        self.textView = textView

        // Initialize with bullet point
        textView.text = bulletPrefix

        // Focus after a brief delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            textView.becomeFirstResponder()
//        }

        return scrollView
    }
}

extension NewEditor: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""

        // Handle empty text
        if text.isEmpty {
            textView.text = bulletPrefix
            return
        }

        // Ensure text starts with bullet
        if !text.hasPrefix(bulletPrefix) {
            textView.text = bulletPrefix + text
            return
        }

        // Add bullet on new line
        if text.last == "\n" {
            let newText = text + bulletPrefix
            textView.text = newText

            // Move cursor to end
            if let newPosition = textView.position(from: textView.endOfDocument, offset: 0) {
                textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
            }
        }
    }
}
