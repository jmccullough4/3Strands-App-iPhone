import SwiftUI
import MapKit

struct PopUpSaleView: View {
    @State private var sales: [PopUpSale] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedSale: PopUpSale?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading pop-up sales...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.gold)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task { await loadSales() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sales.isEmpty {
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
                    VStack(spacing: 0) {
                        mapView
                        salesList
                    }
                }
            }
            .navigationTitle("Pop-Up Sales")
            .refreshable {
                await loadSales()
            }
        }
        .task {
            await loadSales()
        }
        .sheet(item: $selectedSale) { sale in
            PopUpSaleDetailSheet(sale: sale)
        }
    }

    private var mapView: some View {
        Map {
            ForEach(sales) { sale in
                Annotation(sale.title, coordinate: CLLocationCoordinate2D(latitude: sale.latitude, longitude: sale.longitude)) {
                    Button {
                        selectedSale = sale
                    } label: {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(Theme.primary)
                    }
                }
            }
        }
        .frame(height: 300)
    }

    private var salesList: some View {
        List(sales) { sale in
            Button {
                selectedSale = sale
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(sale.title)
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)

                        if let address = sale.address, !address.isEmpty {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        if let desc = sale.description, !desc.isEmpty {
                            Text(desc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.insetGrouped)
    }

    private func loadSales() async {
        isLoading = sales.isEmpty
        errorMessage = nil
        do {
            sales = try await APIService.shared.fetchPopUpSales()
        } catch {
            if sales.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}

// MARK: - Detail Sheet with directions

struct PopUpSaleDetailSheet: View {
    let sale: PopUpSale
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Map preview
                Map {
                    Marker(sale.title, coordinate: CLLocationCoordinate2D(latitude: sale.latitude, longitude: sale.longitude))
                        .tint(Theme.primary)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Text(sale.title)
                        .font(.title2.weight(.bold))
                        .foregroundColor(Theme.textPrimary)

                    if let address = sale.address, !address.isEmpty {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if let desc = sale.description, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                // Open in Maps buttons
                VStack(spacing: 12) {
                    Button {
                        openInAppleMaps()
                    } label: {
                        Label("Open in Apple Maps", systemImage: "map.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primary)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        openInGoogleMaps()
                    } label: {
                        Label("Open in Google Maps", systemImage: "globe")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.forestGreen)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Pop-Up Sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func openInAppleMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: sale.latitude, longitude: sale.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = sale.title
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func openInGoogleMaps() {
        let urlString = "https://www.google.com/maps/dir/?api=1&destination=\(sale.latitude),\(sale.longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
