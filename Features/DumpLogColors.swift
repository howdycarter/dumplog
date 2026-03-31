import SwiftUI

extension Color {
    // Mood colors for DumpLog (defined inline, no asset catalog needed)
    static let moodGreen  = Color(red: 0.20, green: 0.73, blue: 0.47)
    static let moodBlue   = Color(red: 0.29, green: 0.56, blue: 0.89)
    static let moodPurple = Color(red: 0.56, green: 0.27, blue: 0.68)
    static let moodOrange = Color(red: 0.96, green: 0.62, blue: 0.14)
    static let moodRed    = Color(red: 0.91, green: 0.30, blue: 0.24)
    static let dlWarmBg   = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let dlAccent   = Color(red: 0.56, green: 0.27, blue: 0.68)

    static func forSentiment(_ sentiment: Sentiment) -> Color {
        switch sentiment {
        case .positive:   return .moodGreen
        case .neutral:    return .moodBlue
        case .reflective: return .moodPurple
        case .energetic:  return .moodOrange
        case .negative:   return .moodRed
        }
    }
}

extension LinearGradient {
    static let dlWarmBackground = LinearGradient(
        colors: [Color(red: 0.98, green: 0.96, blue: 0.93), Color(red: 0.95, green: 0.93, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
