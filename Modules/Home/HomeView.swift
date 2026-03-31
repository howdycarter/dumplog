//
//  HomeView.swift
//  DumpLog — main content area (Record tab only; Journal/Calendar accessed via tab bar below)
//

import SwiftUI
import SwiftData

/// DumpLog uses a custom 3-tab layout embedded in HomeView so it fits
/// inside The Swift Kit's [Home | Settings] outer tab bar.
struct HomeView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordView()
                .tabItem { Label("Record", systemImage: "mic.fill") }
                .tag(0)
            JournalListView()
                .tabItem { Label("Journal", systemImage: "book.fill") }
                .tag(1)
            DLCalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(2)
        }
        .tint(Color.dlAccent)
    }
}
