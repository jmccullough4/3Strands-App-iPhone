import Foundation
import SwiftUI

// MARK: - Flash Sale Store (Observable state)

@MainActor
class SaleStore: ObservableObject {
    @Published var sales: [FlashSale] = []
    @Published var popUpSales: [PopUpSale] = []
    @Published var announcements: [Announcement] = []
    @Published var isLoading = false
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
        isLoading = sales.isEmpty
        do {
            async let flashSalesTask = APIService.shared.fetchFlashSales()
            async let popUpSalesTask = APIService.shared.fetchPopUpSales()
            async let announcementsTask = APIService.shared.fetchAnnouncements()

            let (fetchedSales, fetchedPopUps, fetchedAnnouncements) = try await (flashSalesTask, popUpSalesTask, announcementsTask)
            sales = fetchedSales
            popUpSales = fetchedPopUps
            announcements = fetchedAnnouncements
        } catch {
            // Fetch individually so one failure doesn't block the others
            do {
                sales = try await APIService.shared.fetchFlashSales()
            } catch {
                print("Flash sales fetch failed: \(error.localizedDescription)")
            }
            do {
                popUpSales = try await APIService.shared.fetchPopUpSales()
            } catch {
                print("Pop-up sales fetch failed: \(error.localizedDescription)")
            }
            do {
                announcements = try await APIService.shared.fetchAnnouncements()
            } catch {
                print("Announcements fetch failed: \(error.localizedDescription)")
            }
        }
        isLoading = false
    }
}
