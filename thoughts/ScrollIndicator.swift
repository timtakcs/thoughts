//
//  ScrollIndicator.swift
//  thoughts
//
//  Created by Timur Takhtarov on 1/20/26.
//

import UIKit

final class ScrollIndicator {
    private weak var scrollView: UIScrollView?
    private let indicatorView = UIView()
    private var bottomInset: CGFloat = 0

    private let indicatorHeight: CGFloat = 30
    private let indicatorWidth: CGFloat = 3
    private let indicatorInset: CGFloat = 4
    private let minIndicatorHeight: CGFloat = 8

    private var hideWorkItem: DispatchWorkItem?

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        setupIndicator()
    }

    private func setupIndicator() {
        indicatorView.backgroundColor = .white
        indicatorView.layer.cornerRadius = indicatorWidth / 2
        indicatorView.alpha = 0
        scrollView?.addSubview(indicatorView)
    }

    func updatePosition() {
        guard let scrollView = scrollView else { return }

        let contentHeight = scrollView.contentSize.height
        let viewHeight = scrollView.bounds.height
        let effectiveBottom = max(scrollView.safeAreaInsets.bottom, bottomInset)
        let maxOffset = contentHeight - viewHeight + scrollView.adjustedContentInset.bottom

        guard maxOffset > 0 else {
            indicatorView.alpha = 0
            return
        }

        let trackHeight = viewHeight - indicatorHeight - (indicatorInset * 2) - scrollView.safeAreaInsets.top - effectiveBottom

        var indicatorY: CGFloat

        let contentOffset = scrollView.contentOffset.y
        let overscroll = max(-contentOffset, contentOffset - maxOffset, 0)
        let compression = min(overscroll * 0.2, indicatorHeight - minIndicatorHeight)
        let currentHeight = indicatorHeight - compression

        if contentOffset < 0 {
            indicatorY = scrollView.safeAreaInsets.top + indicatorInset + scrollView.contentOffset.y
        } else if contentOffset > maxOffset {
            indicatorY = viewHeight - effectiveBottom - indicatorInset - currentHeight + scrollView.contentOffset.y
        } else {
            let scrollProgress = contentOffset / maxOffset
            indicatorY = scrollView.safeAreaInsets.top + indicatorInset + (scrollProgress * trackHeight) + contentOffset
        }

        indicatorView.frame = CGRect(
            x: scrollView.bounds.width - indicatorWidth - indicatorInset,
            y: indicatorY,
            width: indicatorWidth,
            height: currentHeight
        )
        indicatorView.layer.cornerRadius = indicatorWidth / 2

        scrollView.bringSubviewToFront(indicatorView)

        if scrollView.isDragging || scrollView.isDecelerating {
            hideWorkItem?.cancel()
            UIView.animate(withDuration: 0.15) {
                self.indicatorView.alpha = 1.0
            }
        }
    }

    func scheduleHide() {
        hideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 1.0) {
                self?.indicatorView.alpha = 0
            }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    func hideAfterDeceleration() {
        scheduleHide()
    }

    // using the keyboard animation curve to update the scroll indicator position
    // makes it look super smooth when activating the keyboard
    // not sure if this is actually needed
    // it might be cleaner to just disable this when keyboard appears
    func updateBottomInset(_ bottomInset: CGFloat, animatingWith notification: Notification?) {
        self.bottomInset = bottomInset

        if let notification = notification,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
           let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {

            let curve = UIView.AnimationCurve(rawValue: Int(curveValue)) ?? .easeInOut
            let animator = UIViewPropertyAnimator(duration: duration, curve: curve) {
                self.updatePosition()
            }
            animator.startAnimation()
        } else {
            updatePosition()
        }
    }
}
