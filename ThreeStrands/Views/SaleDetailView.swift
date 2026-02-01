import SwiftUI

struct SaleDetailView: View {
    let sale: FlashSale
    @EnvironmentObject var notificationService: NotificationService
    @State private var showingNotificationSent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero image area
                ZStack {
                    LinearGradient(
                        colors: [Theme.forestGreen, Theme.forestGreen.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(spacing: 16) {
                        Image(systemName: sale.imageSystemName)
                            .font(.system(size: 60))
                            .foregroundColor(Theme.gold)

                        Text("\(sale.discountPercent)% OFF")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)

                        if !sale.isExpired {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                Text(sale.timeRemaining)
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.gold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.black.opacity(0.2)))
                        } else {
                            Text("Sale Ended")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.vertical, 40)
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, Theme.screenPadding)

                // Details
                VStack(alignment: .leading, spacing: 20) {
                    // Title and type
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sale.cutType.emoji + " " + sale.cutType.rawValue)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1)

                        Text(sale.title)
                            .font(Theme.heroFont)
                            .foregroundColor(Theme.textPrimary)
                    }

                    // Price card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sale Price")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                            Text(sale.formattedSalePrice)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Theme.forestGreen)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Was")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                            Text(sale.formattedOriginalPrice)
                                .font(.system(size: 20))
                                .foregroundColor(Theme.textSecondary)
                                .strikethrough()
                        }
                    }
                    .padding(Theme.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .fill(Theme.forestGreen.opacity(0.05))
                    )

                    // Weight and price per lb
                    HStack(spacing: 20) {
                        infoChip(icon: "scalemass.fill", label: "Weight", value: "\(String(format: "%.1f", sale.weightLbs)) lbs")
                        infoChip(icon: "dollarsign.circle.fill", label: "Per Pound", value: sale.pricePerLb)
                        infoChip(icon: "tag.fill", label: "Savings", value: "$\(String(format: "%.2f", sale.originalPrice - sale.salePrice))")
                    }

                    // Description
                    Text(sale.description)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                        .lineSpacing(4)

                    // CTA buttons
                    if !sale.isExpired {
                        VStack(spacing: 12) {
                            Button("Order on 3strands Website") {
                                // Deep link to Square Online store
                            }
                            .buttonStyle(BrandButtonStyle(color: Theme.forestGreen))

                            Button("Send Me a Reminder") {
                                notificationService.scheduleTestNotification(
                                    sale: sale.title,
                                    discount: "\(sale.discountPercent)%"
                                )
                                showingNotificationSent = true
                            }
                            .buttonStyle(BrandButtonStyle(color: Theme.primary, isOutline: true))
                        }
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
            }
            .padding(.bottom, 40)
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reminder Set!", isPresented: $showingNotificationSent) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You'll get a notification about this deal in a few seconds.")
        }
    }

    private func infoChip(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.primary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        )
    }
}
