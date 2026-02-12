import SwiftUI

// MARK: - Menu / Shop View (Square Catalog)

// Category definitions matching the website layout
enum MenuCategory: String, CaseIterable {
    case premiumSteaks = "Premium Steaks"
    case roasts = "Roasts"
    case additionalOfferings = "Additional Offerings"
    case specialtyOffal = "Specialty & Offal"
    case farmFreshEggs = "Farm Fresh Eggs"

    var icon: String {
        switch self {
        case .premiumSteaks: return "flame.fill"
        case .roasts: return "oven.fill"
        case .additionalOfferings: return "leaf.fill"
        case .specialtyOffal: return "heart.fill"
        case .farmFreshEggs: return "bird.fill"
        }
    }

    // Map item names to categories, matching website order
    static let itemCategories: [(String, MenuCategory)] = [
        // Premium Steaks (high to low price)
        ("Filet Mignon", .premiumSteaks),
        ("Ribeye Steak", .premiumSteaks),
        ("Sirloin Cap - Picanha", .premiumSteaks),
        ("NY Strip Steak", .premiumSteaks),
        ("Sirloin Flap Steak", .premiumSteaks),
        ("Sirloin Tip Steak", .premiumSteaks),
        ("Inside Skirt Steak", .premiumSteaks),
        ("Outside Skirt Steak", .premiumSteaks),
        ("Flank Steak", .premiumSteaks),
        ("Flat Iron Steak", .premiumSteaks),
        ("Chuck Eye Steak", .premiumSteaks),
        ("Petite Sirloin Steak", .premiumSteaks),
        ("Denver Steak", .premiumSteaks),

        // Roasts
        ("Tri Tip Roast", .roasts),
        ("Sirloin Tip Roast", .roasts),
        ("Eye Round Roast", .roasts),
        ("Rump Roast - Beef", .roasts),
        ("Chuck Roast", .roasts),

        // Additional Offerings
        ("Oxtails - Beef", .additionalOfferings),
        ("Short Rib Bone In - Beef", .additionalOfferings),
        ("Brisket", .additionalOfferings),
        ("Ground Beef", .additionalOfferings),
        ("London Broil", .additionalOfferings),
        ("Stew Meat - Beef", .additionalOfferings),
        ("Osso Bucco - Cross Cut Shank", .additionalOfferings),
        ("Beef Belly", .additionalOfferings),

        // Specialty & Offal
        ("Beef Heart", .specialtyOffal),
        ("Heart - Beef", .specialtyOffal),
        ("Beef Liver", .specialtyOffal),
        ("Liver - Beef", .specialtyOffal),
        ("Beef Tongue", .specialtyOffal),
        ("Marrow Bones Split - Beef", .specialtyOffal),
        ("Soup Bones - Beef", .specialtyOffal),

        // Farm Fresh Eggs
        ("Eggs Half Dozen", .farmFreshEggs),
        ("Eggs Dozen", .farmFreshEggs),
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
    @State private var sections: [MenuSection] = []
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

    private func loadCatalog() async {
        isLoading = sections.isEmpty
        errorMessage = nil
        do {
            let allItems = try await APIService.shared.fetchCatalog()

            // Filter out service items and group by category
            let productItems = allItems.filter { !MenuCategory.excludedItems.contains($0.name) }

            var grouped: [MenuCategory: [CatalogItem]] = [:]
            for item in productItems {
                let cat = MenuCategory.category(for: item.name) ?? .additionalOfferings
                grouped[cat, default: []].append(item)
            }

            // Sort items within each category by the website order
            for (cat, items) in grouped {
                grouped[cat] = items.sorted {
                    MenuCategory.sortOrder(for: $0.name) < MenuCategory.sortOrder(for: $1.name)
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

// MARK: - Menu Item Row

struct MenuItemRow: View {
    let item: CatalogItem

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
