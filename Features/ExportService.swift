import Foundation
import UIKit

class ExportService {
    func exportText(for entry: JournalEntry) -> String {
        var lines: [String] = []
        lines.append("DumpLog — Voice Journal Entry")
        lines.append(String(repeating: "=", count: 30))
        lines.append("Date: \(entry.formattedDate)")
        lines.append("Duration: \(entry.formattedDuration)")
        lines.append("Mood: \(entry.sentiment.emoji) \(entry.sentiment.label)")
        lines.append("")
        if !entry.themes.isEmpty {
            lines.append("Key Themes:")
            entry.themes.forEach { lines.append("  • \($0)") }
            lines.append("")
        }
        lines.append("Transcript:")
        lines.append(entry.transcript)
        lines.append("")
        if !entry.actionItems.isEmpty {
            lines.append("Action Items:")
            entry.actionItems.forEach { lines.append("  ☐ \($0)") }
            lines.append("")
        }
        lines.append("---")
        lines.append("Exported from DumpLog — All data stored privately on device.")
        return lines.joined(separator: "\n")
    }

    func shareEntry(_ entry: JournalEntry, from viewController: UIViewController? = nil) {
        let text = exportText(for: entry)
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let vc = viewController ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController {
            vc.present(activity, animated: true)
        }
    }

    func shareEntries(_ entries: [JournalEntry], from viewController: UIViewController? = nil) {
        let combined = entries.sorted(by: { $0.date > $1.date }).map { exportText(for: $0) }.joined(separator: "\n\n---\n\n")
        let activity = UIActivityViewController(activityItems: [combined], applicationActivities: nil)
        if let vc = viewController ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController {
            vc.present(activity, animated: true)
        }
    }
}
