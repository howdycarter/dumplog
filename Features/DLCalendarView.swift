import SwiftUI
import SwiftData

struct DLCalendarView: View {
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var selectedDate = Date()
    @State private var selectedEntry: JournalEntry?
    @State private var displayedMonth = Date()
    private let calendar = Calendar.current

    private var entriesByDate: [DateComponents: [JournalEntry]] {
        Dictionary(grouping: entries) { entry in
            calendar.dateComponents([.year, .month, .day], from: entry.date)
        }
    }

    private var daysInMonth: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) { days.append(date) }
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.dlWarmBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    monthHeader
                    weekdayHeader
                    calendarGrid
                    selectedDateEntries
                }
            }
            .navigationTitle("Calendar").navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $selectedEntry) { entry in EntryDetailView(entry: entry) }
    }

    private var monthHeader: some View {
        HStack {
            Button { withAnimation { displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth } } label: {
                Image(systemName: "chevron.left").font(.title3.weight(.semibold)).foregroundStyle(.primary)
            }
            Spacer()
            Text(displayedMonth, format: .dateTime.year().month(.wide)).font(.title3.weight(.semibold))
            Spacer()
            Button { withAnimation { displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth } } label: {
                Image(systemName: "chevron.right").font(.title3.weight(.semibold)).foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(["S","M","T","W","T","F","S"], id: \.self) { day in
                Text(day).font(.caption.weight(.medium)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date = date {
                    let comps = calendar.dateComponents([.year, .month, .day], from: date)
                    let dayEntries = entriesByDate[comps] ?? []
                    let isToday = calendar.isDateInToday(date)
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 4) {
                            Text(date, format: .dateTime.day())
                                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                                .foregroundStyle(isSelected ? .white : isToday ? Color.dlAccent : .primary)
                                .frame(width: 32, height: 32)
                                .background(isSelected ? Color.dlAccent : Color.clear, in: Circle())
                            if !dayEntries.isEmpty {
                                Circle().fill(Color.forSentiment(dayEntries.first!.sentiment)).frame(width: 5, height: 5)
                            } else {
                                Circle().fill(Color.clear).frame(width: 5, height: 5)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private var selectedDateEntries: some View {
        let comps = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let dayEntries = entriesByDate[comps] ?? []
        return Group {
            if dayEntries.isEmpty {
                VStack(spacing: 8) {
                    Text("No entries").foregroundStyle(.secondary).font(.callout)
                }
                .frame(maxWidth: .infinity).padding(.top, 24)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(dayEntries) { entry in
                            DLJournalRowView(entry: entry)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedEntry = entry }
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 12)
                }
            }
        }
    }
}
