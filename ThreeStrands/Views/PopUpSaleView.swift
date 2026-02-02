import SwiftUI
import MapKit

struct PopUpSaleView: View {
    @State private var events: [PopUpEvent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedEvent: PopUpEvent?

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
                            Task { await loadEvents() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if events.isEmpty {
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
                    List(events) { event in
                        PopUpEventRow(event: event)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Pop-Up Sales")
            .refreshable {
                await loadEvents()
            }
        }
        .task {
            await loadEvents()
        }
    }

    private func loadEvents() async {
        isLoading = events.isEmpty
        errorMessage = nil
        do {
            events = try await APIService.shared.fetchPopUpEvents()
        } catch {
            if events.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}

// MARK: - Pop-Up Event Row

struct PopUpEventRow: View {
    let event: PopUpEvent
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: event.icon ?? "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.primary)
                    .frame(width: 40, height: 40)
                    .background(Theme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    if let dateStr = event.date {
                        Text(formatDate(dateStr))
                            .font(.caption)
                            .foregroundColor(Theme.gold)
                    }
                }

                Spacer()
            }

            Text(event.location)
                .font(.subheadline)
                .foregroundColor(.secondary)

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
                        .background(Capsule().fill(Theme.forestGreen))
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        guard let date = formatter.date(from: isoString) else { return isoString }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }

    private func openInAppleMaps() {
        let query = event.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(query)") {
            openURL(url)
        }
    }

    private func openInGoogleMaps() {
        let query = event.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)") {
            openURL(url)
        }
    }
}
