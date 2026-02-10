import SwiftUI

// MARK: - 3 Strands Cattle Co. Brand Theme
// Colors derived from logo/trailer branding: black background with copper/bronze accents

enum Theme {
    // Primary brand colors
    static let copper = Color(red: 0.753, green: 0.478, blue: 0.243)       // #C07A3E
    static let bronze = Color(red: 0.624, green: 0.443, blue: 0.290)       // #9F714A
    static let bronzeGold = Color(red: 0.831, green: 0.627, blue: 0.329)   // #D4A054

    // Semantic colors
    static let primary = copper
    static let secondary = bronze
    static let accent = bronzeGold
    static let background = Color(red: 0.051, green: 0.051, blue: 0.051)   // #0D0D0D
    static let cardBackground = Color(red: 0.110, green: 0.110, blue: 0.118) // #1C1C1E
    static let textPrimary = Color(red: 0.949, green: 0.929, blue: 0.910)  // #F2EDE8
    static let textSecondary = Color(red: 0.604, green: 0.565, blue: 0.533) // #9A9088

    // Typography
    static let heroFont: Font = .system(size: 32, weight: .bold, design: .serif)
    static let headingFont: Font = .system(size: 22, weight: .semibold, design: .serif)
    static let subheadingFont: Font = .system(size: 17, weight: .medium, design: .default)
    static let bodyFont: Font = .system(size: 15, weight: .regular, design: .default)
    static let captionFont: Font = .system(size: 13, weight: .regular, design: .default)

    // Dimensions
    static let cornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
}

// MARK: - Reusable Button Style

struct BrandButtonStyle: ButtonStyle {
    var color: Color = Theme.primary
    var isOutline: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(isOutline ? color : .white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(isOutline ? Color.clear : color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(color, lineWidth: isOutline ? 2 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
