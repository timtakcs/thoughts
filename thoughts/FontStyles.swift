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
