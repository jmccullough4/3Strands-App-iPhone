import SwiftUI

struct FlashSalesView: View {
    @EnvironmentObject var store: SaleStore
    @State private var filterCut: CutType?
    @State private var showFavoritesOnly = false

    var filteredSales: [FlashSale] {
        var sales = store.activeSales
        if showFavoritesOnly {
            sales = sales.filter { store.isFavoriteSale($0.id) }
        }
        if let cut = filterCut {
            sales = sales.filter { $0.cutType == cut }
        }
        return sales
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip(label: "All", isSelected: filterCut == nil && !showFavoritesOnly) {
                                filterCut = nil
                                showFavoritesOnly = false
                            }
                            filterChip(
                                label: "\(Image(systemName: "heart.fill")) Favorites",
                                isSelected: showFavoritesOnly
                            ) {
                                showFavoritesOnly.toggle()
                                if showFavoritesOnly { filterCut = nil }
                            }
                            ForEach(CutType.allCases, id: \.self) { cut in
                                filterChip(
                                    label: "\(cut.emoji) \(cut.rawValue)",
                                    isSelected: filterCut == cut
                                ) {
                                    filterCut = (filterCut == cut) ? nil : cut
                                }
                            }
                        }
                        .padding(.horizontal, Theme.screenPadding)
                    }

                    if filteredSales.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredSales) { sale in
                                NavigationLink(destination: SaleDetailView(sale: sale)) {
                                    FlashSaleCard(sale: sale, isCompact: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.screenPadding)
                    }

                    // Past sales section
                    if !store.expiredSales.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Past Sales")
                                .font(Theme.headingFont)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, Theme.screenPadding)

                            LazyVStack(spacing: 12) {
                                ForEach(store.expiredSales) { sale in
                                    FlashSaleCard(sale: sale, isCompact: false)
                                        .opacity(0.5)
                                }
                            }
                            .padding(.horizontal, Theme.screenPadding)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Theme.background)
            .navigationTitle("Flash Sales")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await store.refreshSales()
            }
        }
    }

    private func filterChip(label: LocalizedStringKey, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.primary : Theme.cardBackground)
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.slash.fill")
                .font(.system(size: 44))
                .foregroundColor(Theme.textSecondary.opacity(0.4))
            Text("No Active Sales")
                .font(Theme.headingFont)
                .foregroundColor(Theme.textSecondary)
            Text("Check back soon or enable notifications\nso you never miss a deal.")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}
