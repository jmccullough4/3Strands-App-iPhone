import SwiftUI

// MARK: - Menu / Shop View (Square Catalog)

// Category definitions matching the desired layout
enum MenuCategory: String, CaseIterable {
    case premiumSteaks = "Premium Steaks"
    case everydaySteaks = "Everyday Steaks"
    case roasts = "Roasts"
    case groundAndStew = "Ground & Stew"
    case specialtyCuts = "Specialty Cuts"
    case bonesAndOffal = "Bones & Offal"
    case farmFresh = "Farm Fresh"

    var icon: String {
        switch self {
        case .premiumSteaks: return "flame.fill"
        case .everydaySteaks: return "fork.knife"
        case .roasts: return "oven.fill"
        case .groundAndStew: return "frying.pan.fill"
        case .specialtyCuts: return "star.fill"
        case .bonesAndOffal: return "hare.fill"
        case .farmFresh: return "bird.fill"
        }
    }

    // Map item names to categories, in display order
    static let itemCategories: [(String, MenuCategory)] = [
        // Premium Steaks
        ("Filet Mignon", .premiumSteaks),
        ("Ribeye Steak", .premiumSteaks),
        ("Porterhouse Steak", .premiumSteaks),
        ("NY Strip Steak", .premiumSteaks),
        ("Sirloin Cap - Picanha", .premiumSteaks),

        // Everyday Steaks
        ("London Broil", .everydaySteaks),
        ("Petite Sirloin Steak", .everydaySteaks),
        ("Sirloin Flap Steak", .everydaySteaks),
        ("Sirloin Tip Steak", .everydaySteaks),
        ("Chuck Eye Steak", .everydaySteaks),
        ("Denver Steak", .everydaySteaks),
        ("Flank Steak", .everydaySteaks),
        ("Flat Iron Steak", .everydaySteaks),
        ("Hanger Steak", .everydaySteaks),
        ("Inside Skirt Steak", .everydaySteaks),
        ("Outside Skirt Steak", .everydaySteaks),
        ("Teres Major - Beef", .everydaySteaks),

        // Roasts
        ("Brisket", .roasts),
        ("Tri Tip Roast", .roasts),
        ("Eye Round Roast", .roasts),
        ("Rump Roast - Beef", .roasts),
        ("Sirloin Tip Roast", .roasts),
        ("Chuck Roast", .roasts),

        // Ground & Stew
        ("Ground Beef", .groundAndStew),
        ("Stew Meat - Beef", .groundAndStew),

        // Specialty Cuts
        ("Osso Bucco - Cross Cut Shank", .specialtyCuts),
        ("Short Rib Bone In - Beef", .specialtyCuts),
        ("Beef Belly", .specialtyCuts),
        ("Oxtails - Beef", .specialtyCuts),

        // Bones & Offal
        ("Heart - Beef", .bonesAndOffal),
        ("Beef Heart", .bonesAndOffal),
        ("Liver - Beef", .bonesAndOffal),
        ("Beef Liver", .bonesAndOffal),
        ("Beef Tongue", .bonesAndOffal),
        ("Marrow Bones Split - Beef", .bonesAndOffal),
        ("Soup Bones - Beef", .bonesAndOffal),

        // Farm Fresh
        ("Duck Eggs - Dozen", .farmFresh),
        ("Duck Eggs - Half Dozen", .farmFresh),
        ("Eggs Dozen", .farmFresh),
        ("Eggs Half Dozen", .farmFresh),
    ]

    // Service items to exclude from the menu
    static let excludedItems: Set<String> = [
        "Beef Home Delivery",
        "Beef Pickup",
        "Market Appearance",
        "Shipping",
    ]

    static func category(for itemName: String) -> MenuCategory? {
        itemCategories.first(where: { $0.0 == itemName })?.1
    }

    static func sortOrder(for itemName: String) -> Int {
        itemCategories.firstIndex(where: { $0.0 == itemName }) ?? 999
    }
}

struct MenuSection: Identifiable {
    let id = UUID()
    let category: MenuCategory
    let items: [CatalogItem]
}

struct MenuView: View {
    @EnvironmentObject var store: SaleStore
    @State private var sections: [MenuSection] = []
    @State private var flashSaleItems: [(CatalogItem, FlashSale)] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let pollTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading menu...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.bronzeGold)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task { await loadCatalog() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sections.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "storefront")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.primary)
                        Text("Menu Coming Soon")
                            .font(.headline)
                            .foregroundColor(Theme.primary)
                        Text("Our full menu with prices is on the way.\nIn the meantime, browse our website!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Link(destination: URL(string: "https://3strandsbeef.com")!) {
                            Label("Shop on Our Website", systemImage: "globe")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Theme.bronze))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Flash sale items pinned to the very top
                        if !flashSaleItems.isEmpty {
                            Section {
                                ForEach(flashSaleItems, id: \.0.id) { item, sale in
                                    FlashSaleMenuRow(item: item, sale: sale)
                                }
                            } header: {
                                FlashSaleHeader()
                            }
                        }

                        ForEach(sections) { section in
                            Section {
                                ForEach(section.items) { item in
                                    MenuItemRow(item: item)
                                }
                            } header: {
                                HStack(spacing: 8) {
                                    Image(systemName: section.category.icon)
                                        .foregroundColor(Theme.primary)
                                    Text(section.category.rawValue)
                                        .font(.system(size: 16, weight: .bold, design: .serif))
                                        .foregroundColor(Theme.primary)
                                }
                                .padding(.vertical, 4)
                                .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background)
            .navigationTitle("Our Menu")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await loadCatalog()
            }
        }
        .task {
            await loadCatalog()
        }
        .onReceive(pollTimer) { _ in
            Task { await loadCatalog() }
        }
    }

    /// Find an active flash sale that matches a catalog item by name
    private func matchFlashSale(for itemName: String, in sales: [FlashSale]) -> FlashSale? {
        sales.first { sale in
            itemName == sale.cutType.rawValue ||
            sale.title.localizedCaseInsensitiveContains(itemName) ||
            itemName.localizedCaseInsensitiveContains(sale.cutType.rawValue)
        }
    }

    private func loadCatalog() async {
        isLoading = sections.isEmpty && flashSaleItems.isEmpty
        errorMessage = nil
        do {
            let allItems = try await APIService.shared.fetchCatalog()
            let activeSales = store.activeSales

            // Filter out service items
            let productItems = allItems.filter { !MenuCategory.excludedItems.contains($0.name) }

            // Separate flash sale items from regular items
            var flashPairs: [(CatalogItem, FlashSale)] = []
            var regularItems: [CatalogItem] = []

            for item in productItems {
                if !item.isSoldOut, let sale = matchFlashSale(for: item.name, in: activeSales) {
                    flashPairs.append((item, sale))
                } else {
                    regularItems.append(item)
                }
            }

            flashSaleItems = flashPairs

            // Group regular items by category
            var grouped: [MenuCategory: [CatalogItem]] = [:]
            for item in regularItems {
                let cat = MenuCategory.category(for: item.name) ?? .specialtyCuts
                grouped[cat, default: []].append(item)
            }

            // Sort: in-stock by website order, then sold-out
            for (cat, items) in grouped {
                grouped[cat] = items.sorted { a, b in
                    if a.isSoldOut != b.isSoldOut { return !a.isSoldOut }
                    return MenuCategory.sortOrder(for: a.name) < MenuCategory.sortOrder(for: b.name)
                }
            }

            // Build sections in the correct category order
            sections = MenuCategory.allCases.compactMap { cat in
                guard let items = grouped[cat], !items.isEmpty else { return nil }
                return MenuSection(category: cat, items: items)
            }
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("Catalog fetch error: \(error)")
            #endif
        }
        isLoading = false
    }
}

// MARK: - Flash Sale Section Header (animated)

struct FlashSaleHeader: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(isPulsing ? 1.2 : 1.0)

            Text("FLASH SALE")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(1.5)

            Image(systemName: "bolt.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(isPulsing ? 1.2 : 1.0)

            Spacer()
        }
        .padding(.vertical, 6)
        .textCase(nil)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Flash Sale Menu Row (promoted item)

struct FlashSaleMenuRow: View {
    let item: CatalogItem
    let sale: FlashSale
    @Environment(\.openURL) private var openURL
    @State private var glowOpacity: Double = 0.4

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Item name + prices
            HStack {
                Text(item.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.bronzeGold)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.formattedPrice)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                        .strikethrough()
                    Text(sale.formattedSalePrice)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                }
            }

            // Discount banner + timer
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("\(sale.discountPercent)% OFF")
                        .font(.system(size: 12, weight: .heavy))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.bronzeGold)

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9))
                    Text(sale.timeRemaining)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(Theme.bronzeGold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.bronzeGold.opacity(0.15))

                Spacer()

                Button {
                    if let url = URL(string: "https://3strandsbeef.com") {
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 12))
                        Text("Order")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Theme.bronze)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.vertical, 6)
        .listRowBackground(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.bronzeGold.opacity(glowOpacity), lineWidth: 1.5)
                )
                .shadow(color: Theme.bronzeGold.opacity(glowOpacity * 0.5), radius: 6)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowOpacity = 0.9
            }
        }
    }
}

// MARK: - Menu Item Row

struct MenuItemRow: View {
    let item: CatalogItem
    @Environment(\.openURL) private var openURL

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(item.isSoldOut ? .secondary : Theme.primary)

                Spacer()

                if item.isSoldOut {
                    Text("Sold Out")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.red.opacity(0.8))
                        .italic()
                } else {
                    HStack(spacing: 8) {
                        if item.isLowStock {
                            Text("Low Stock")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(4)
                        }
                        Text(item.formattedPrice)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.bronze)
                        Button {
                            if let url = URL(string: "https://3strandsbeef.com") {
                                openURL(url)
                            }
                        } label: {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.bronze)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if item.variations.count > 1 {
                DisclosureGroup("Options (\(item.variations.count))", isExpanded: $isExpanded) {
                    ForEach(item.variations) { v in
                        HStack {
                            Text(v.name)
                                .font(.subheadline)
                                .foregroundColor(v.isSoldOut ? .secondary : .primary)
                            Spacer()
                            if v.isSoldOut {
                                Text("Sold Out")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(.red.opacity(0.7))
                                    .italic()
                            } else {
                                Text(v.formattedPrice)
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .font(.caption.weight(.medium))
                .tint(Theme.primary)
            }
        }
        .padding(.vertical, 4)
    }
}
