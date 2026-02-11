import SwiftUI
import MapKit
import CoreLocation

// MARK: - Event Model

struct CattleEvent: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let endDate: Date?
    let location: String
    let latitude: Double
    let longitude: Double
    let icon: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Events View with Calendar

struct EventsView: View {
    private let events = CattleEvent.upcoming
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @StateObject private var locationService = LocationService.shared
    @State private var cameraPosition: MapCameraPosition = .automatic

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    /// Unique event locations for map pins (deduplicated by coordinate)
    private var uniqueLocations: [CattleEvent] {
        var seen = Set<String>()
        return events.filter { event in
            let key = "\(event.latitude),\(event.longitude)"
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    eventMapSection
                    calendarView
                    eventsForSelectedDate
                }
                .padding(.bottom, 30)
            }
            .background(Theme.background)
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                locationService.requestPermission()
                locationService.startMonitoringEvents(events)
            }
        }
    }

    // MARK: - Event Map

    private var eventMapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(Theme.bronzeGold)
                Text("Event Locations")
                    .font(Theme.headingFont)
                    .foregroundColor(Theme.primary)
                Spacer()
            }
            .padding(.horizontal, Theme.screenPadding)

            Map(position: $cameraPosition) {
                ForEach(uniqueLocations) { event in
                    Marker(event.title, coordinate: event.coordinate)
                        .tint(Theme.primary)
                }
                UserAnnotation()
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.primary.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, Theme.screenPadding)
        }
    }

    // MARK: - Calendar Grid

    private var calendarView: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    withAnimation { changeMonth(by: -1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.primary)
                }

                Spacer()

                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.primary)

                Spacer()

                Button {
                    withAnimation { changeMonth(by: 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.primary)
                }
            }
            .padding(.horizontal, 4)

            // Day-of-week headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        dayCell(date)
                    } else {
                        Text("")
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .padding(.horizontal, Theme.screenPadding)
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let hasEvent = eventsOn(date).count > 0

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 15, weight: isSelected ? .bold : isToday ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : isToday ? Theme.primary : Theme.textPrimary)

                if hasEvent {
                    Circle()
                        .fill(isSelected ? .white : Theme.bronze)
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Theme.primary : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Events for Selected Date

    private var eventsForSelectedDate: some View {
        let dayEvents = eventsOn(selectedDate)
        return VStack(alignment: .leading, spacing: 12) {
            Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(Theme.headingFont)
                .foregroundColor(Theme.primary)
                .padding(.horizontal, Theme.screenPadding)

            if dayEvents.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.minus")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.textSecondary.opacity(0.4))
                    Text("No events on this day")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(dayEvents) { event in
                    eventCard(event)
                        .padding(.horizontal, Theme.screenPadding)
                }
            }
        }
    }

    private func eventCard(_ event: CattleEvent) -> some View {
        HStack(spacing: 14) {
            // Time block
            VStack(spacing: 2) {
                Image(systemName: event.icon)
                    .font(.system(size: 22))
                    .foregroundColor(Theme.bronze)
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.bronze.opacity(0.1))
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.primary)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text(eventTimeString(event))
                        .font(Theme.captionFont)
                }
                .foregroundColor(Theme.textSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                    Text(event.location)
                        .font(Theme.captionFont)
                }
                .foregroundColor(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }

    // MARK: - Helpers

    private func eventsOn(_ date: Date) -> [CattleEvent] {
        events.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func eventTimeString(_ event: CattleEvent) -> String {
        let start = event.date.formatted(.dateTime.hour().minute())
        if let end = event.endDate {
            return "\(start) – \(end.formatted(.dateTime.hour().minute()))"
        }
        return start
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        return days
    }
}

// MARK: - Real Events from 3strandsbeef.com

extension CattleEvent {
    // NOTE: Update latitude/longitude for each event here.
    // Current coordinates are approximate — replace with exact values.
    static let upcoming: [CattleEvent] = [
        // February 2026
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 2, 1, 9, 0), endDate: makeDate(2026, 2, 1, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 2, 6, 16, 0), endDate: makeDate(2026, 2, 6, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 2, 8, 9, 0), endDate: makeDate(2026, 2, 8, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 2, 13, 16, 0), endDate: makeDate(2026, 2, 13, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 2, 15, 9, 0), endDate: makeDate(2026, 2, 15, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 2, 20, 16, 0), endDate: makeDate(2026, 2, 20, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 2, 22, 9, 0), endDate: makeDate(2026, 2, 22, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 2, 27, 16, 0), endDate: makeDate(2026, 2, 27, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),

        // March 2026
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 3, 1, 9, 0), endDate: makeDate(2026, 3, 1, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 3, 6, 16, 0), endDate: makeDate(2026, 3, 6, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 3, 8, 9, 0), endDate: makeDate(2026, 3, 8, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 3, 13, 16, 0), endDate: makeDate(2026, 3, 13, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 3, 15, 9, 0), endDate: makeDate(2026, 3, 15, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 3, 20, 16, 0), endDate: makeDate(2026, 3, 20, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 3, 22, 9, 0), endDate: makeDate(2026, 3, 22, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 3, 27, 16, 0), endDate: makeDate(2026, 3, 27, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 3, 29, 9, 0), endDate: makeDate(2026, 3, 29, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),

        // April 2026
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 4, 3, 16, 0), endDate: makeDate(2026, 4, 3, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 4, 5, 9, 0), endDate: makeDate(2026, 4, 5, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 4, 10, 16, 0), endDate: makeDate(2026, 4, 10, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 4, 12, 9, 0), endDate: makeDate(2026, 4, 12, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 4, 17, 16, 0), endDate: makeDate(2026, 4, 17, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 4, 19, 9, 0), endDate: makeDate(2026, 4, 19, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 4, 24, 16, 0), endDate: makeDate(2026, 4, 24, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
        CattleEvent(title: "Lauderdale by the Sea Market", date: makeDate(2026, 4, 26, 9, 0), endDate: makeDate(2026, 4, 26, 13, 0), location: "4500 El Mar Dr., Lauderdale-by-the-Sea", latitude: 26.1934, longitude: -80.0962, icon: "leaf.fill"),

        // May 2026
        CattleEvent(title: "Olive Branch Market", date: makeDate(2026, 5, 1, 16, 0), endDate: makeDate(2026, 5, 1, 19, 0), location: "3750 NE Indian River Dr.", latitude: 27.2506, longitude: -80.2289, icon: "leaf.fill"),
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
