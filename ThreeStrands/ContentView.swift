import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: SaleStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            MenuView()
                .tabItem {
                    Label("Menu", systemImage: "menucard")
                }
                .tag(1)

            FlashSalesView()
                .tabItem {
                    Label("Flash Sales", systemImage: "bolt.fill")
                }
                .tag(2)
                .badge(store.activeSales.count)

            NotificationInboxView()
                .tabItem {
                    Label("Inbox", systemImage: "bell.fill")
                }
                .tag(3)
                .badge(store.unreadCount)

            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(4)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(5)
        }
        .tint(Theme.primary)
        .task {
            await store.refreshSales()
        }
    }
}
