import SwiftUI

// MARK: - Menu / Shop View (Square Catalog)

struct MenuView: View {
    @State private var items: [CatalogItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

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
                            .foregroundColor(Theme.gold)
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
                } else if items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "storefront")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.primary)
                        Text("No menu items yet")
                            .font(.headline)
                        Text("Pull down to refresh, or check back soon.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(items) { item in
                        MenuItemRow(item: item)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Our Menu")
            .refreshable {
                await loadCatalog()
            }
        }
        .task {
            await loadCatalog()
        }
    }

    private func loadCatalog() async {
        isLoading = items.isEmpty
        errorMessage = nil
        do {
            items = try await APIService.shared.fetchCatalog()
        } catch {
            errorMessage = error.localizedDescription
            print("Catalog fetch error: \(error)")
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(Theme.primary)

                    if let category = item.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(item.formattedPrice)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.forestGreen)
            }

            if let desc = item.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
            }

            if item.variations.count > 1 {
                DisclosureGroup("Options (\(item.variations.count))", isExpanded: $isExpanded) {
                    ForEach(item.variations) { v in
                        HStack {
                            Text(v.name)
                                .font(.subheadline)
                            Spacer()
                            Text(v.formattedPrice)
                                .font(.subheadline.weight(.medium))
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
