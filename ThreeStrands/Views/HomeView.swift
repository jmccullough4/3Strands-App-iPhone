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

                    // Notification banners (iOS-style, dismissable)
                    notificationBanners

                    // Active Flash Sales
                    if !store.activeSales.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(Theme.bronzeGold)
                                Text("Live Flash Sales")
                                    .font(Theme.headingFont)
                                    .foregroundColor(Theme.primary)
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

                    // Pop-Up Sales
                    popUpSalesSection

                    // Values section
                    valuesSection

                    // Quick links
                    quickLinks
                }
                .padding(.bottom, 30)
            }
            .background(Theme.background)
            .navigationTitle("Ecclesiastes 4:12")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await store.refreshSales()
            }
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Theme.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Image("Copper")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .shadow(color: Theme.primary.opacity(0.3), radius: 8, y: 4)

                Text("Veteran Owned  •  Faith Driven  •  Florida Sourced")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textSecondary)

                if !store.activeSales.isEmpty {
                    Text("\(store.activeSales.count) Flash Sale\(store.activeSales.count == 1 ? "" : "s") Live Now")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(Theme.bronzeGold)
                        )
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 32)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.primary.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 8)
    }

    // MARK: - Notification Banners (iOS-style)

    private var notificationBanners: some View {
        Group {
            let visible = store.homeNotifications
            if !visible.isEmpty {
                VStack(spacing: 10) {
                    ForEach(visible) { item in
                        NotificationBanner(item: item) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                store.dismissFromHome(item.id)
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
            }
        }
    }

    // MARK: - Pop-Up Sales

    private var popUpSalesSection: some View {
        Group {
            if !store.popUpSales.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(Theme.bronzeGold)
                        Text("Pop-Up Sales")
                            .font(Theme.headingFont)
                            .foregroundColor(Theme.primary)
                        Spacer()
                    }
                    .padding(.horizontal, Theme.screenPadding)

                    ForEach(store.popUpSales) { sale in
                        NavigationLink(destination: PopUpSaleView()) {
                            HStack(spacing: 14) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.primary)
                                    .frame(width: 40, height: 40)
                                    .background(Theme.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sale.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Theme.primary)
                                    if let address = sale.address, !address.isEmpty {
                                        Text(address)
                                            .font(Theme.captionFont)
                                            .foregroundColor(Theme.textSecondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Text("Directions")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Theme.bronze))
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                    .fill(Theme.cardBackground)
                                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Theme.screenPadding)
                    }
                }
            }
        }
    }

    // MARK: - Values

    private var valuesSection: some View {
        VStack(spacing: 20) {
            Text("Our Mission")
                .font(Theme.headingFont)
                .foregroundColor(Theme.primary)

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
                .foregroundColor(Theme.primary)
                .padding(.horizontal, Theme.screenPadding)

            VStack(spacing: 10) {
                linkButton(icon: "globe", title: "Visit Our Website", subtitle: "3strandsbeef.com", color: Theme.bronze, urlString: "https://3strandsbeef.com")
                linkButton(icon: "envelope.fill", title: "Email Us", subtitle: "info@3strands.co", color: Theme.primary, urlString: "mailto:info@3strands.co")
                linkButton(icon: "phone.fill", title: "Call Us", subtitle: "(863) 799-3300", color: Theme.bronze, urlString: "tel:8637993300")
            }
            .padding(.horizontal, Theme.screenPadding)
        }
    }

    @Environment(\.openURL) private var openURL

    private func linkButton(icon: String, title: String, subtitle: String, color: Color, urlString: String) -> some View {
        Button {
            if let url = URL(string: urlString) {
                openURL(url)
            }
        } label: {
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
                        .foregroundColor(Theme.primary)
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
        .buttonStyle(.plain)
    }
}

// MARK: - iOS-Style Notification Banner

struct NotificationBanner: View {
    let item: InboxItem
    let onDismiss: () -> Void

    @State private var offset: CGFloat = 0

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // App icon
            Image("Appicon")
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("3 Strands Cattle Co.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(item.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(item.body)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        )
        .overlay(alignment: .topTrailing) {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color(.systemGray5)))
            }
            .padding(8)
        }
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.width < 0 {
                        offset = value.translation.width
                    }
                }
                .onEnded { value in
                    if value.translation.width < -100 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = -500
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDismiss()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3)) {
                            offset = 0
                        }
                    }
                }
        )
    }
}
