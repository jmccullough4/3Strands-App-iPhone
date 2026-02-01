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

            FlashSalesView()
                .tabItem {
                    Label("Flash Sales", systemImage: "bolt.fill")
                }
                .tag(1)
                .badge(store.activeSales.count)

            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(Theme.primary)
    }
}
