import SwiftUI
import SwiftData

struct JournalListView: View {
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedEntry: JournalEntry?
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: JournalEntry?
    private let exportService = ExportService()

    var filteredEntries: [JournalEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.transcript.localizedCaseInsensitiveContains(searchText) ||
            $0.themes.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.dlWarmBackground.ignoresSafeArea()
                if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "mic.slash.fill").font(.system(size: 48)).foregroundStyle(.quaternary)
                        Text("No entries yet").font(.headline).foregroundStyle(.secondary)
                        Text("Tap the Record tab to start your first voice journal entry")
                            .font(.callout).foregroundStyle(.tertiary).multilineTextAlignment(.center).padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(filteredEntries) { entry in
                            DLJournalRowView(entry: entry)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .contentShape(Rectangle())
                                .onTapGesture { selectedEntry = entry }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { entryToDelete = entry; showingDeleteAlert = true } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button { exportService.shareEntry(entry) } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }.tint(.blue)
                                }
                        }
                    }
                    .listStyle(.plain).scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Journal")
            .searchable(text: $searchText, prompt: "Search entries...")
            .toolbar {
                if !entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { exportService.shareEntries(entries) } label: { Image(systemName: "square.and.arrow.up") }
                    }
                }
            }
            .sheet(item: $selectedEntry) { entry in EntryDetailView(entry: entry) }
            .alert("Delete Entry", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { if let e = entryToDelete { deleteEntry(e) } }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This entry will be permanently deleted from your device.") }
        }
    }

    private func deleteEntry(_ entry: JournalEntry) {
        if let path = entry.audioURL { try? FileManager.default.removeItem(atPath: path) }
        modelContext.delete(entry)
    }
}

struct DLJournalRowView: View {
    let entry: JournalEntry
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.forSentiment(entry.sentiment).opacity(0.15)).frame(width: 44, height: 44)
                Text(entry.sentiment.emoji).font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.title.isEmpty ? "Untitled Entry" : entry.title)
                        .font(.callout.weight(.semibold)).lineLimit(1)
                    Spacer()
                    Text(entry.formattedDuration).font(.caption).foregroundStyle(.secondary)
                }
                Text(entry.transcript.isEmpty ? "No transcript" : entry.transcript)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                HStack(spacing: 8) {
                    Text(entry.shortDate).font(.caption2).foregroundStyle(.tertiary)
                    if !entry.themes.isEmpty {
                        Text(entry.themes.prefix(2).joined(separator: " · "))
                            .font(.caption2).foregroundStyle(Color.forSentiment(entry.sentiment).opacity(0.8))
                    }
                }
            }
        }
        .padding(12).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
