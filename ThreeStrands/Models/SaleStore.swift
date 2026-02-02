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
        do {
            let fetched = try await APIService.shared.fetchFlashSales()
            if !fetched.isEmpty {
                sales = fetched
            }
        } catch {
            // Keep existing data (samples) if network fails
            print("Flash sales fetch failed: \(error.localizedDescription)")
        }
    }
}
