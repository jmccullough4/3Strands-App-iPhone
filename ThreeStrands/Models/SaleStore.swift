import Foundation
import SwiftUI

// MARK: - Inbox Item Model

struct InboxItem: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let receivedAt: Date
    var isRead: Bool

    init(title: String, body: String) {
        self.id = UUID().uuidString
        self.title = title
        self.body = body
        self.receivedAt = Date()
        self.isRead = false
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(receivedAt)
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 { return "\(days)d ago" }
        if hours > 0 { return "\(hours)h ago" }
        if minutes > 0 { return "\(minutes)m ago" }
        return "Just now"
    }
}

// MARK: - Flash Sale Store (Observable state)

@MainActor
class SaleStore: ObservableObject {
    @Published var sales: [FlashSale] = []
    @Published var popUpSales: [PopUpSale] = []
    @Published var announcements: [Announcement] = []
    @Published var events: [CattleEvent] = []
    @Published var inboxItems: [InboxItem] = []
    @Published var isLoading = false
    @Published var notificationPrefs: NotificationPreferences

    /// IDs of inbox items the user dismissed from the Home screen (but not deleted from Inbox)
    @Published var dismissedFromHome: Set<String> = []

    private let prefsKey = NotificationPreferences.storageKey
    private let inboxKey = "notification_inbox"
    private let dismissedKey = "dismissed_from_home"
    private let seenAnnouncementIDsKey = "seen_announcement_ids"

    init() {
        if let data = UserDefaults.standard.data(forKey: NotificationPreferences.storageKey),
           let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            self.notificationPrefs = prefs
        } else {
            self.notificationPrefs = NotificationPreferences()
        }

        // Load saved inbox
        if let data = UserDefaults.standard.data(forKey: inboxKey),
           let items = try? JSONDecoder().decode([InboxItem].self, from: data) {
            self.inboxItems = items
        }

        // Load dismissed set
        if let ids = UserDefaults.standard.array(forKey: dismissedKey) as? [String] {
            self.dismissedFromHome = Set(ids)
        }
    }

    /// Inbox items that haven't been dismissed from the Home screen
    var homeNotifications: [InboxItem] {
        inboxItems.filter { !dismissedFromHome.contains($0.id) }
    }

    var activeSales: [FlashSale] {
        sales.filter { $0.isActive && !$0.isExpired }
            .sorted { $0.expiresAt < $1.expiresAt }
    }

    var expiredSales: [FlashSale] {
        sales.filter { $0.isExpired || !$0.isActive }
    }

    var unreadCount: Int {
        inboxItems.filter { !$0.isRead }.count
    }

    // MARK: - Preferences

    func savePreferences() {
        if let data = try? JSONEncoder().encode(notificationPrefs) {
            UserDefaults.standard.set(data, forKey: prefsKey)
        }
    }

    // MARK: - Inbox

    func addInboxItem(title: String, body: String) {
        let item = InboxItem(title: title, body: body)
        inboxItems.insert(item, at: 0)
        saveInbox()
    }

    func markAsRead(_ id: String) {
        if let index = inboxItems.firstIndex(where: { $0.id == id }) {
            inboxItems[index].isRead = true
            saveInbox()
        }
    }

    func dismissFromHome(_ id: String) {
        dismissedFromHome.insert(id)
        saveDismissed()
    }

    func removeInboxItem(_ id: String) {
        inboxItems.removeAll { $0.id == id }
        dismissedFromHome.remove(id)
        saveInbox()
        saveDismissed()
    }

    func clearInbox() {
        inboxItems.removeAll()
        dismissedFromHome.removeAll()
        saveInbox()
        saveDismissed()
    }

    private func saveInbox() {
        if let data = try? JSONEncoder().encode(inboxItems) {
            UserDefaults.standard.set(data, forKey: inboxKey)
        }
    }

    private func saveDismissed() {
        UserDefaults.standard.set(Array(dismissedFromHome), forKey: dismissedKey)
    }

    /// Sync fetched announcements into inbox — creates inbox items for new announcements.
    /// Does NOT schedule local notifications because APNs push already delivers
    /// the visible notification; scheduling a local one here would cause duplicates.
    func syncAnnouncementsToInbox() {
        var seenIDs = Set(UserDefaults.standard.stringArray(forKey: seenAnnouncementIDsKey) ?? [])
        var added = false

        for announcement in announcements where announcement.isActive {
            // Include created_at in the key so updated/recreated announcements are treated as new
            let announcementKey = "announcement-\(announcement.id)-\(announcement.createdAt ?? "")"
            if !seenIDs.contains(announcementKey) {
                print("NEW announcement detected: id=\(announcement.id), title=\(announcement.title), key=\(announcementKey)")
                let item = InboxItem(title: announcement.title, body: announcement.message)
                inboxItems.insert(item, at: 0)
                seenIDs.insert(announcementKey)
                added = true
            }
        }

        if added {
            saveInbox()
            UserDefaults.standard.set(Array(seenIDs), forKey: seenAnnouncementIDsKey)
        }
    }

    // MARK: - Data Refresh

    func refreshSales() async {
        isLoading = sales.isEmpty
        do {
            async let flashSalesTask = APIService.shared.fetchFlashSales()
            async let popUpSalesTask = APIService.shared.fetchPopUpSales()
            async let announcementsTask = APIService.shared.fetchAnnouncements()
            async let eventsTask = APIService.shared.fetchEvents()

            let (fetchedSales, fetchedPopUps, fetchedAnnouncements, fetchedEvents) = try await (flashSalesTask, popUpSalesTask, announcementsTask, eventsTask)
            sales = fetchedSales
            popUpSales = fetchedPopUps
            announcements = fetchedAnnouncements
            events = fetchedEvents
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
            do {
                events = try await APIService.shared.fetchEvents()
            } catch {
                print("Events fetch failed: \(error.localizedDescription)")
            }
        }
        isLoading = false

        // Auto-create inbox items for any new announcements
        syncAnnouncementsToInbox()
    }
}
