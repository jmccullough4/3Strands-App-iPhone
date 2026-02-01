import Foundation
import SwiftUI

// MARK: - Flash Sale Store (Observable state)

@MainActor
class SaleStore: ObservableObject {
    @Published var sales: [FlashSale] = FlashSale.samples
    @Published var notificationPrefs: NotificationPreferences

    private let prefsKey = NotificationPreferences.storageKey

    init() {
        if let data = UserDefaults.standard.data(forKey: NotificationPreferences.storageKey),
           let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            self.notificationPrefs = prefs
        } else {
            self.notificationPrefs = NotificationPreferences()
        }
    }

    var activeSales: [FlashSale] {
        sales.filter { $0.isActive && !$0.isExpired }
            .sorted { $0.expiresAt < $1.expiresAt }
    }

    var expiredSales: [FlashSale] {
        sales.filter { $0.isExpired || !$0.isActive }
    }

    func savePreferences() {
        if let data = try? JSONEncoder().encode(notificationPrefs) {
            UserDefaults.standard.set(data, forKey: prefsKey)
        }
    }

    func refreshSales() async {
        // In production, this would fetch from a backend API:
        // let url = URL(string: "https://api.threestrandscattle.com/flash-sales")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // self.sales = try JSONDecoder().decode([FlashSale].self, from: data)

        // For now, simulate a network refresh
        try? await Task.sleep(nanoseconds: 800_000_000)
        sales = FlashSale.samples
    }
}
