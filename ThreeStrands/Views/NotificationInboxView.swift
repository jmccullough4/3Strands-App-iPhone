import SwiftUI

struct NotificationInboxView: View {
    @EnvironmentObject var store: SaleStore

    var body: some View {
        NavigationStack {
            Group {
                if store.inboxItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.primary)
                        Text("No Notifications")
                            .font(.headline)
                            .foregroundColor(Theme.primary)
                        Text("Push notifications from 3 Strands\nwill appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.inboxItems) { item in
                            InboxItemRow(item: item)
                                .onAppear {
                                    if !item.isRead {
                                        store.markAsRead(item.id)
                                    }
                                }
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { store.inboxItems[$0].id }
                            for id in ids {
                                store.removeInboxItem(id)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !store.inboxItems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") {
                            store.clearInbox()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Inbox Item Row

struct InboxItemRow: View {
    let item: InboxItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForTitle(item.title))
                .font(.system(size: 20))
                .foregroundColor(item.isRead ? Theme.textSecondary : Theme.bronzeGold)
                .frame(width: 36, height: 36)
                .background((item.isRead ? Theme.textSecondary : Theme.bronzeGold).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.system(size: 15, weight: item.isRead ? .medium : .bold))
                        .foregroundColor(Theme.primary)
                    Spacer()
                    Text(item.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Text(item.body)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }

    private func iconForTitle(_ title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("flash sale") { return "bolt.fill" }
        if lower.contains("pop-up") || lower.contains("coming to") { return "mappin.circle.fill" }
        if lower.contains("test") { return "paperplane.fill" }
        return "megaphone.fill"
    }
}
