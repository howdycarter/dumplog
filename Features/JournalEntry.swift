import Foundation
import SwiftUI
import SwiftData

enum Sentiment: String, Codable, CaseIterable {
    case positive
    case neutral
    case reflective
    case energetic
    case negative

    var color: Color {
        switch self {
        case .positive:   return .moodGreen
        case .neutral:    return .moodBlue
        case .reflective: return .moodPurple
        case .energetic:  return .moodOrange
        case .negative:   return .moodRed
        }
    }

    var emoji: String {
        switch self {
        case .positive:   return "😊"
        case .neutral:    return "😐"
        case .reflective: return "🤔"
        case .energetic:  return "⚡️"
        case .negative:   return "😔"
        }
    }

    var label: String {
        switch self {
        case .positive:   return "Positive"
        case .neutral:    return "Neutral"
        case .reflective: return "Reflective"
        case .energetic:  return "Energetic"
        case .negative:   return "Low"
        }
    }
}

@Model
final class JournalEntry {
    var id: UUID
    var date: Date
    var audioURL: String?
    var transcript: String
    var themes: [String]
    var sentimentRaw: String
    var actionItems: [String]
    var duration: TimeInterval
    var title: String

    var sentiment: Sentiment {
        get { Sentiment(rawValue: sentimentRaw) ?? .neutral }
        set { sentimentRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        audioURL: String? = nil,
        transcript: String = "",
        themes: [String] = [],
        sentiment: Sentiment = .neutral,
        actionItems: [String] = [],
        duration: TimeInterval = 0,
        title: String = ""
    ) {
        self.id = id
        self.date = date
        self.audioURL = audioURL
        self.transcript = transcript
        self.themes = themes
        self.sentimentRaw = sentiment.rawValue
        self.actionItems = actionItems
        self.duration = duration
        self.title = title
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
