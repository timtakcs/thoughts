//
//  FontStyles.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/23/25.
//

import UIKit
import SwiftUI

extension UIFont {
    static func iosevka(size: CGFloat, weight: Weight = .regular) -> UIFont {
        let fontName: String
        switch weight {
        case .bold:
            fontName = "Iosevka Aile Bold"
        case .light:
            fontName = "Iosevka Aile Light"
        default:
            fontName = "Iosevka Aile"
        }
        return UIFont(name: fontName, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}

extension Font {
    static func iosevka(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .bold:
            fontName = "Iosevka Aile Bold"
        case .light:
            fontName = "Iosevka Aile Light"
        default:
            fontName = "Iosevka Aile"
        }
        return Font.custom(fontName, size: size)
    }
}

// MARK: - App Colors

let mycolor = 0x121212
let deleteColor = 0xEB3C30
let textColor = 0xF5F5F5

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    static let appBackground = UIColor(hex: mycolor)
    static let deleteBackground = UIColor(hex: deleteColor)
    static let appText = UIColor(hex: textColor)
}

extension Color {
    init(hex: Int) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    static let appBackground = Color(hex: mycolor)
    static let deleteBackground = Color(hex: deleteColor)
    static let appText = Color(hex: textColor)
}
