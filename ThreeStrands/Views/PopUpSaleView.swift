import SwiftUI
import MapKit

struct PopUpSaleView: View {
    @EnvironmentObject var store: SaleStore

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.popUpSales.isEmpty {
                    ProgressView("Loading pop-up sales...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.popUpSales.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.primary)
                        Text("No Pop-Up Sales Right Now")
                            .font(.headline)
                        Text("Check back soon for our next location!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(store.popUpSales) { sale in
                        PopUpSaleRow(sale: sale)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background)
            .navigationTitle("Pop-Up Sales")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await store.refreshSales()
            }
        }
    }
}

// MARK: - Pop-Up Sale Row

struct PopUpSaleRow: View {
    let sale: PopUpSale
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.primary)
                    .frame(width: 40, height: 40)
                    .background(Theme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(sale.title)
                        .font(.headline)
                        .foregroundColor(Theme.primary)

                    if let dateStr = sale.startsAt {
                        Text(formatDate(dateStr))
                            .font(.caption)
                            .foregroundColor(Theme.bronzeGold)
                    }
                }

                Spacer()
            }

            if let address = sale.address, !address.isEmpty {
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let desc = sale.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    openInAppleMaps()
                } label: {
                    Label("Apple Maps", systemImage: "map.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.primary))
                }

                Button {
                    openInGoogleMaps()
                } label: {
                    Label("Google Maps", systemImage: "globe")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.bronze))
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        guard let date = formatter.date(from: isoString) else {
            // Try with Z suffix
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            guard let date = iso.date(from: isoString) else { return isoString }
            let display = DateFormatter()
            display.dateStyle = .medium
            display.timeStyle = .short
            return display.string(from: date)
        }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }

    private func openInAppleMaps() {
        let urlStr = "maps://?ll=\(sale.latitude),\(sale.longitude)&q=\(sale.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlStr) {
            openURL(url)
        }
    }

    private func openInGoogleMaps() {
        let urlStr = "https://www.google.com/maps/search/?api=1&query=\(sale.latitude),\(sale.longitude)"
        if let url = URL(string: urlStr) {
            openURL(url)
        }
    }
}
