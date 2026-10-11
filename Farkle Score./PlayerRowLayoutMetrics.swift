//
//  PlayerRowLayoutMetrics.swift
//  Farkle Score.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Height estimates for sidebar player rows, mirroring `PlayerRowView` sizing for fit checks.
enum PlayerRowLayoutMetrics {
    static let rowSpacing: CGFloat = 8
    private static let standardVerticalPadding: CGFloat = 10
    private static let editTapTargetBase: CGFloat = 44
    private static let prominentContentTopInset: CGFloat = 20

    static func estimatedRowHeight(prominent: Bool, dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        let avatar = scaled(AppTheme.avatarSize, relativeTo: .headline, dynamicTypeSize: dynamicTypeSize)
        let prominentAvatar = scaled(
            AppTheme.activePlayerRowAvatarSize,
            relativeTo: .title,
            dynamicTypeSize: dynamicTypeSize
        )
        let editTarget = scaled(editTapTargetBase, relativeTo: .body, dynamicTypeSize: dynamicTypeSize)
        let scoreHeight = scaledScoreLineHeight(prominent: prominent, dynamicTypeSize: dynamicTypeSize)
        let topInset = scaled(prominentContentTopInset, relativeTo: .subheadline, dynamicTypeSize: dynamicTypeSize)

        let contentHeight: CGFloat
        if prominent {
            contentHeight = topInset + max(prominentAvatar, scoreHeight) + editTarget
        } else {
            contentHeight = max(avatar, editTarget, scoreHeight)
        }
        let verticalPadding = prominent
            ? AppTheme.activePlayerRowVerticalPadding
            : standardVerticalPadding
        return verticalPadding * 2 + contentHeight
    }

    static func estimatedListHeight(
        playerCount: Int,
        activeIndex: Int,
        emphasizeActive: Bool,
        dynamicTypeSize: DynamicTypeSize
    ) -> CGFloat {
        guard playerCount > 0 else { return 0 }

        var total: CGFloat = 0
        for index in 0..<playerCount {
            let prominent = emphasizeActive && index == activeIndex
            total += estimatedRowHeight(prominent: prominent, dynamicTypeSize: dynamicTypeSize)
        }
        total += CGFloat(playerCount - 1) * rowSpacing
        return total
    }

    private static func scaledScoreLineHeight(prominent: Bool, dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        let base: CGFloat = prominent ? 22 : 20
        return scaled(
            base,
            relativeTo: prominent ? .title2 : .title3,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    private static func scaled(
        _ value: CGFloat,
        relativeTo textStyle: Font.TextStyle,
        dynamicTypeSize: DynamicTypeSize
    ) -> CGFloat {
#if canImport(UIKit)
        let uiStyle = uiFontTextStyle(for: textStyle)
        let traits = UITraitCollection(preferredContentSizeCategory: uiContentSizeCategory(for: dynamicTypeSize))
        return UIFontMetrics(forTextStyle: uiStyle).scaledValue(for: value, compatibleWith: traits)
#else
        return value * contentSizeScale(for: dynamicTypeSize)
#endif
    }

#if canImport(UIKit)
    private static func uiFontTextStyle(for style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }

    private static func uiContentSizeCategory(for dynamicTypeSize: DynamicTypeSize) -> UIContentSizeCategory {
        switch dynamicTypeSize {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }
#else
    private static func contentSizeScale(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall: return 0.82
        case .small: return 0.88
        case .medium: return 0.94
        case .large: return 1.0
        case .xLarge: return 1.06
        case .xxLarge: return 1.12
        case .xxxLarge: return 1.18
        case .accessibility1: return 1.24
        case .accessibility2: return 1.30
        case .accessibility3: return 1.36
        case .accessibility4: return 1.42
        case .accessibility5: return 1.48
        @unknown default: return 1.0
        }
    }
#endif
}
