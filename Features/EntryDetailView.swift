import SwiftUI

struct EntryDetailView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    private let exportService = ExportService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    moodHeader
                    if !entry.themes.isEmpty { themesSection }
                    transcriptSection
                    if !entry.actionItems.isEmpty { actionItemsSection }
                }
                .padding()
            }
            .background(LinearGradient.dlWarmBackground.ignoresSafeArea())
            .navigationTitle(entry.shortDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { exportService.shareEntry(entry) } label: { Image(systemName: "square.and.arrow.up") }
                }
            }
        }
    }

    private var moodHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.forSentiment(entry.sentiment).opacity(0.15)).frame(width: 56, height: 56)
                Text(entry.sentiment.emoji).font(.system(size: 28))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.sentiment.label).font(.headline)
                Text(entry.formattedDate).font(.caption).foregroundStyle(.secondary)
                Text(entry.formattedDuration).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Key Themes").font(.headline)
            FlowLayout(spacing: 8) {
                ForEach(entry.themes, id: \.self) { theme in
                    Text(theme).font(.caption.weight(.medium)).padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.dlAccent.opacity(0.12), in: Capsule())
                        .foregroundStyle(Color.dlAccent)
                }
            }
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transcript").font(.headline)
            Text(entry.transcript.isEmpty ? "No transcript available" : entry.transcript)
                .font(.body).foregroundStyle(.primary)
                .padding(16).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Action Items").font(.headline)
            VStack(spacing: 8) {
                ForEach(entry.actionItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "square").font(.system(size: 16)).foregroundStyle(Color.dlAccent)
                        Text(item).font(.callout)
                        Spacer()
                    }
                    .padding(12).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0; var maxY: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > width && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            rowH = max(rowH, s.height); x += s.width + spacing; maxY = max(maxY, y + rowH)
        }
        return CGSize(width: width, height: maxY)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s)); rowH = max(rowH, s.height); x += s.width + spacing
        }
    }
}
