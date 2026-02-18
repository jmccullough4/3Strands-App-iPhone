import SwiftUI

struct FlashSaleCard: View {
    let sale: FlashSale
    var isCompact: Bool = true
    @EnvironmentObject var store: SaleStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and timer
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.bronze.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: sale.imageSystemName)
                        .font(.system(size: 20))
                        .foregroundColor(Theme.bronze)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(sale.cutType.rawValue)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                    Text(sale.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.primary)
                        .lineLimit(isCompact ? 1 : 2)
                }

                Spacer()

                if !sale.isExpired {
                    timerBadge
                }
            }

            if !isCompact {
                Text(sale.description)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
            }

            // Price row
            HStack(alignment: .bottom) {
                Text(sale.formattedSalePrice)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.bronze)

                Text(sale.formattedOriginalPrice)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .strikethrough()

                Spacer()

                Text("\(sale.discountPercent)% OFF")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(Theme.primary)
                    )
            }

            // Weight info
            HStack(spacing: 4) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 11))
                Text("\(String(format: "%.1f", sale.weightLbs)) lbs")
                    .font(Theme.captionFont)
                Text("•")
                Text(sale.pricePerLb)
                    .font(Theme.captionFont)
            }
            .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.07), radius: 10, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(
                    sale.isExpired ? Color.clear : Theme.bronzeGold.opacity(0.3),
                    lineWidth: 1
                )
        )
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    store.toggleFavoriteSale(sale.id)
                }
            } label: {
                Image(systemName: store.isFavoriteSale(sale.id) ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundColor(store.isFavoriteSale(sale.id) ? .red : Theme.textSecondary)
                    .padding(10)
                    .background(Circle().fill(Theme.cardBackground.opacity(0.8)))
            }
            .padding(8)
        }
        .contextMenu {
            Button {
                store.toggleFavoriteSale(sale.id)
            } label: {
                Label(
                    store.isFavoriteSale(sale.id) ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: store.isFavoriteSale(sale.id) ? "heart.slash" : "heart"
                )
            }

            ShareLink(item: "\(sale.title) - \(sale.discountPercent)% OFF! Was \(sale.formattedOriginalPrice), now \(sale.formattedSalePrice). Shop at https://3strandsbeef.com") {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }

    private var timerBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 10))
            Text(sale.timeRemaining)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(Theme.bronzeGold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(Theme.bronzeGold.opacity(0.12))
        )
    }
}
