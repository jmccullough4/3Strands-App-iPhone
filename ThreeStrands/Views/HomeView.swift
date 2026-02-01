import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: SaleStore
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Banner
                    heroBanner

                    // Active Flash Sales
                    if !store.activeSales.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(Theme.gold)
                                Text("Live Flash Sales")
                                    .font(Theme.headingFont)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text("\(store.activeSales.count) active")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(.horizontal, Theme.screenPadding)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(store.activeSales) { sale in
                                        NavigationLink(destination: SaleDetailView(sale: sale)) {
                                            FlashSaleCard(sale: sale)
                                                .frame(width: 280)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, Theme.screenPadding)
                            }
                        }
                    }

                    // Values section
                    valuesSection

                    // Quick links
                    quickLinks
                }
                .padding(.bottom, 30)
            }
            .background(Theme.background)
            .navigationBarHidden(true)
            .refreshable {
                await store.refreshSales()
            }
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.forestGreen, Theme.forestGreen.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Image("Appicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                Text("3 Strands Cattle Co.")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(.white)

                Text("Veteran Owned  •  Faith Driven  •  Florida Sourced")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))

                if !store.activeSales.isEmpty {
                    Text("\(store.activeSales.count) Flash Sale\(store.activeSales.count == 1 ? "" : "s") Live Now")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.forestGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(Theme.gold)
                        )
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 32)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 8)
    }

    // MARK: - Values

    private var valuesSection: some View {
        VStack(spacing: 20) {
            Text("Our Mission")
                .font(Theme.headingFont)
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 16) {
                Text("Our mission is simple: glorify God through honest business, support local farmers, and provide your family with beef you can trust. Every cut is traceable, every relationship is stewarded with integrity, and a portion of every sale supports local food banks and ministries.")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                    .lineSpacing(4)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(Theme.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
        }
        .padding(.horizontal, Theme.screenPadding)
    }

    // MARK: - Quick Links

    private var quickLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Links")
                .font(Theme.headingFont)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Theme.screenPadding)

            VStack(spacing: 10) {
                linkRow(icon: "globe", title: "Visit Our Website", subtitle: "threestrandscattle.com", color: Theme.forestGreen)
                linkRow(icon: "phone.fill", title: "Contact Us", subtitle: "M-Sat 7am-9pm ET", color: Theme.primary)
                linkRow(icon: "shippingbox.fill", title: "Track Your Order", subtitle: "Via Square Online", color: Theme.gold)
            }
            .padding(.horizontal, Theme.screenPadding)
        }
    }

    private func linkRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary.opacity(0.5))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        )
    }
}
