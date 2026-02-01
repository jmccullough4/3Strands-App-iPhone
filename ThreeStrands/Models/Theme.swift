import SwiftUI

// MARK: - 3 Strands Cattle Co. Brand Theme
// Colors derived from the 3strands-Site: saddle brown, forest green, gold

enum Theme {
    // Primary brand colors
    static let saddleBrown = Color(red: 0.545, green: 0.271, blue: 0.075)
    static let forestGreen = Color(red: 0.173, green: 0.333, blue: 0.188)
    static let gold = Color(red: 0.831, green: 0.686, blue: 0.216)

    // Semantic colors
    static let primary = saddleBrown
    static let secondary = forestGreen
    static let accent = gold
    static let background = Color(red: 0.98, green: 0.97, blue: 0.95)
    static let cardBackground = Color.white
    static let textPrimary = Color(red: 0.15, green: 0.12, blue: 0.10)
    static let textSecondary = Color(red: 0.45, green: 0.40, blue: 0.35)

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
