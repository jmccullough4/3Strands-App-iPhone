import SwiftUI
import BackgroundTasks

@main
struct ThreeStrandsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = SaleStore()
    @StateObject private var notificationService = NotificationService.shared
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @State private var isLaunching = true

    init() {
        // Force light mode and set navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.background)
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Theme.primary)
        ]
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.primary)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Theme.primary)
    }

    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some Scene {
        WindowGroup {
            Group {
                if isLaunching {
                    LaunchScreenView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    isLaunching = false
                                }
                            }
                        }
                } else if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(store)
                        .environmentObject(notificationService)
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .environmentObject(notificationService)
                }
            }
            .preferredColorScheme(.light)
            .task {
                // Re-register the persisted APNs token with the dashboard (if we have one).
                // This ensures the dashboard always has a valid APNs token on file,
                // rather than overwriting it with a non-APNs device identifier.
                await notificationService.reRegisterStoredToken()
                // Only request push after onboarding is done — let the onboarding
                // flow handle the initial prompt so the user understands WHY first.
                if hasCompletedOnboarding {
                    await notificationService.ensurePushRegistration()
                }
            }
            .onReceive(refreshTimer) { _ in
                // Poll every 30 seconds for live updates
                Task { await store.refreshSales() }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh data every time user opens the app
                Task { await store.refreshSales() }
                // Re-register for push to keep APNs token fresh (only after onboarding)
                if hasCompletedOnboarding {
                    Task { await notificationService.ensurePushRegistration() }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                // Schedule background refresh so iOS wakes the app periodically
                AppDelegate.scheduleBackgroundRefresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: .dashboardDidUpdate)) { notification in
                // Refresh when a push notification signals a dashboard update
                Task { await store.refreshSales() }

                // Save to inbox if notification has alert content
                if let userInfo = notification.userInfo,
                   let aps = userInfo["aps"] as? [String: Any],
                   let alert = aps["alert"] as? [String: Any],
                   let title = alert["title"] as? String,
                   let body = alert["body"] as? String {
                    store.addInboxItem(title: title, body: body)
                }
            }
        }
    }
}

// MARK: - Custom Notification Name

extension Notification.Name {
    static let dashboardDidUpdate = Notification.Name("dashboardDidUpdate")
}

// MARK: - App Delegate for Push Notification Registration

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    static let backgroundTaskID = "com.threestrandscattle.app.refresh"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // Register the background refresh task — iOS will call the handler
        // periodically even when the app is terminated.
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskID,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }

        return true
    }

    // MARK: - Background App Refresh

    /// Schedule the next background refresh. iOS decides the exact timing based on
    /// how often the user opens the app (typically every 15–30 min for active apps).
    static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Could not schedule background refresh: \(error)")
        }
    }

    /// Called by iOS when the background refresh fires.
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule the next one immediately so the chain continues
        Self.scheduleBackgroundRefresh()

        let operation = Task {
            await Self.backgroundContentCheck()
        }

        task.expirationHandler = {
            operation.cancel()
        }

        Task {
            _ = await operation.result
            task.setTaskCompleted(success: true)
        }
    }

    /// Fetch announcements and flash sales from the dashboard, compare against
    /// what we've already seen, and fire local notifications for anything new.
    /// Runs without any UI — safe to call from a background task.
    static func backgroundContentCheck() async {
        let seenAnnouncementKey = "seen_announcement_ids"
        let seenFlashSaleKey = "seen_flash_sale_ids_bg"
        let inboxKey = "notification_inbox"

        do {
            // Fetch current data from dashboard
            async let announcementsTask = APIService.shared.fetchAnnouncements()
            async let flashSalesTask = APIService.shared.fetchFlashSales()
            let (announcements, flashSales) = try await (announcementsTask, flashSalesTask)

            var seenAnnouncements = Set(UserDefaults.standard.stringArray(forKey: seenAnnouncementKey) ?? [])
            var seenSales = Set(UserDefaults.standard.stringArray(forKey: seenFlashSaleKey) ?? [])

            // Load current inbox from UserDefaults
            var inboxItems: [InboxItem] = []
            if let data = UserDefaults.standard.data(forKey: inboxKey),
               let items = try? JSONDecoder().decode([InboxItem].self, from: data) {
                inboxItems = items
            }

            var newCount = 0

            // Check for new announcements
            for a in announcements where a.isActive {
                let key = "announcement-\(a.id)-\(a.createdAt ?? "")"
                if !seenAnnouncements.contains(key) {
                    seenAnnouncements.insert(key)
                    inboxItems.insert(InboxItem(title: a.title, body: a.message), at: 0)
                    await scheduleLocalNotification(title: a.title, body: a.message, id: "bg-\(key)")
                    newCount += 1
                }
            }

            // Check for new flash sales
            for s in flashSales where s.isActive && !s.isExpired {
                let key = "sale-\(s.id)"
                if !seenSales.contains(key) {
                    seenSales.insert(key)
                    let title = "3 Strands Flash Sale!"
                    let body = "\(s.title) — \(s.discountPercent)% off!"
                    inboxItems.insert(InboxItem(title: title, body: body), at: 0)
                    await scheduleLocalNotification(title: title, body: body, id: "bg-\(key)")
                    newCount += 1
                }
            }

            // Persist everything back
            if newCount > 0 {
                if let data = try? JSONEncoder().encode(inboxItems) {
                    UserDefaults.standard.set(data, forKey: inboxKey)
                }
                UserDefaults.standard.set(Array(seenAnnouncements), forKey: seenAnnouncementKey)
                UserDefaults.standard.set(Array(seenSales), forKey: seenFlashSaleKey)
                print("Background refresh: \(newCount) new notification(s)")
            } else {
                print("Background refresh: no new content")
            }
        } catch {
            print("Background content check failed: \(error)")
        }
    }

    private static func scheduleLocalNotification(title: String, body: String, id: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - APNs Token Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationService.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Handle silent push / content-available for background refresh
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Post notification so SwiftUI views refresh (flash sales, pop-ups, and announcements)
        NotificationCenter.default.post(name: .dashboardDidUpdate, object: nil, userInfo: userInfo)
        completionHandler(.newData)
    }

    // Handle foreground notifications — show banner even when app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        // Refresh data when notification arrives in foreground
        NotificationCenter.default.post(name: .dashboardDidUpdate, object: nil, userInfo: userInfo)
        completionHandler([.banner, .list, .badge, .sound])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        // Refresh data on tap
        NotificationCenter.default.post(name: .dashboardDidUpdate, object: nil, userInfo: userInfo)
        completionHandler()
    }
}
