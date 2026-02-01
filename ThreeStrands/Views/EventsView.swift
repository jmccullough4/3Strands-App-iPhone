import SwiftUI

// MARK: - Event Model

struct CattleEvent: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let endDate: Date?
    let location: String
    let description: String
    let icon: String
}

// MARK: - Events View

struct EventsView: View {
    private let events = CattleEvent.upcoming

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if upcomingEvents.isEmpty && pastEvents.isEmpty {
                        emptyState
                    } else {
                        if !upcomingEvents.isEmpty {
                            eventSection(title: "Upcoming Events", events: upcomingEvents)
                        }

                        if !pastEvents.isEmpty {
                            eventSection(title: "Past Events", events: pastEvents)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Theme.background)
            .navigationTitle("Events")
        }
    }

    private var upcomingEvents: [CattleEvent] {
        events.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.date < $1.date }
    }

    private var pastEvents: [CattleEvent] {
        events.filter { $0.date < Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.date > $1.date }
    }

    private func eventSection(title: String, events: [CattleEvent]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Theme.headingFont)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Theme.screenPadding)

            ForEach(events) { event in
                eventCard(event)
                    .padding(.horizontal, Theme.screenPadding)
            }
        }
    }

    private func eventCard(_ event: CattleEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                // Date badge
                VStack(spacing: 2) {
                    Text(event.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.primary)
                    Text(event.date.formatted(.dateTime.day()))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.primary.opacity(0.1))
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(eventTimeString(event))
                            .font(Theme.captionFont)
                    }
                    .foregroundColor(Theme.textSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                        Text(event.location)
                            .font(Theme.captionFont)
                    }
                    .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: event.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.forestGreen)
            }

            Text(event.description)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }

    private func eventTimeString(_ event: CattleEvent) -> String {
        let start = event.date.formatted(.dateTime.hour().minute())
        if let end = event.endDate {
            let endStr = end.formatted(.dateTime.hour().minute())
            return "\(start) – \(endStr)"
        }
        return start
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(Theme.textSecondary.opacity(0.5))
            Text("No Events Scheduled")
                .font(Theme.headingFont)
                .foregroundColor(Theme.textPrimary)
            Text("Check back soon for upcoming\nfarmers markets, pop-ups, and more.")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
    }
}

// MARK: - Sample Events
// Update these with real events from 3strandsbeef.com

extension CattleEvent {
    static let upcoming: [CattleEvent] = [
        CattleEvent(
            title: "Lakeland Farmers Market",
            date: makeDate(2025, 2, 8, 8, 0),
            endDate: makeDate(2025, 2, 8, 13, 0),
            location: "Lakeland, FL",
            description: "Come visit our booth at the Lakeland Farmers Market! Sample our premium Florida-raised beef and grab fresh cuts at market-only prices.",
            icon: "leaf.fill"
        ),
        CattleEvent(
            title: "Winter Haven Pop-Up Shop",
            date: makeDate(2025, 2, 15, 10, 0),
            endDate: makeDate(2025, 2, 15, 15, 0),
            location: "Winter Haven, FL",
            description: "One-day pop-up sale featuring our full product line. Pre-orders welcome — message us to reserve your cuts!",
            icon: "storefront.fill"
        ),
        CattleEvent(
            title: "Community Cookout & Tasting",
            date: makeDate(2025, 3, 1, 11, 0),
            endDate: makeDate(2025, 3, 1, 14, 0),
            location: "Bartow, FL",
            description: "Join us for a free community cookout! Taste the difference of locally raised, faith-driven beef. Family friendly — bring the kids.",
            icon: "flame.fill"
        ),
        CattleEvent(
            title: "Plant City Strawberry Festival",
            date: makeDate(2025, 3, 6, 10, 0),
            endDate: makeDate(2025, 3, 6, 21, 0),
            location: "Plant City, FL",
            description: "Find us at the Florida Strawberry Festival! We'll be serving up smoked brisket sandwiches and selling fresh cuts all day.",
            icon: "party.popper.fill"
        ),
    ]

    private static func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
