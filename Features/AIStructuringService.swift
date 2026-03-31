import Foundation
import NaturalLanguage

struct StructuredEntry {
    var themes: [String]
    var sentiment: Sentiment
    var actionItems: [String]
    var title: String
}

class AIStructuringService {
    private let tagger = NLTagger(tagSchemes: [.sentimentScore, .nameTypeOrLexicalClass, .lemma])
    private let tokenizer = NLTokenizer(unit: .sentence)

    func structure(transcript: String) -> StructuredEntry {
        let sentiment = analyzeSentiment(text: transcript)
        let themes = extractThemes(text: transcript)
        let actionItems = extractActionItems(text: transcript)
        let title = generateTitle(text: transcript, themes: themes)
        return StructuredEntry(themes: themes, sentiment: sentiment, actionItems: actionItems, title: title)
    }

    private func analyzeSentiment(text: String) -> Sentiment {
        tagger.string = text
        var totalScore: Double = 0; var count = 0
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
            if let tag, let score = Double(tag.rawValue) { totalScore += score; count += 1 }
            return true
        }
        let average = count > 0 ? totalScore / Double(count) : 0
        if average > 0.3 { return .positive }
        else if average > 0.1 { return .energetic }
        else if average < -0.2 { return .negative }
        else if average < 0 { return .reflective }
        else { return .neutral }
    }

    private func extractThemes(text: String) -> [String] {
        var wordFrequency: [String: Int] = [:]
        let stopWords: Set<String> = ["the","a","an","and","or","but","in","on","at","to","for","of","with","by","from","is","was","are","were","be","been","have","has","had","do","does","did","will","would","could","should","may","might","shall","can","i","me","my","we","our","you","your","it","its","this","that","these","those","just","really","very","so","also","like","know","think","going"]
        tagger.string = text
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma) { tag, range in
            let word = (tag?.rawValue ?? String(text[range])).lowercased()
            if word.count > 3 && !stopWords.contains(word) && word.allSatisfy({ $0.isLetter }) {
                wordFrequency[word, default: 0] += 1
            }
            return true
        }
        return Array(wordFrequency.sorted { $0.value > $1.value }.prefix(5).map { $0.key.capitalized })
    }

    private func extractActionItems(text: String) -> [String] {
        var actionItems: [String] = []
        let patterns = ["need to","should","have to","must","want to","going to","will","plan to","remind me to","don't forget","make sure"]
        tokenizer.string = text
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = sentence.lowercased()
            for pattern in patterns {
                if lower.contains(pattern) {
                    let clean = sentence.trimmingCharacters(in: .punctuationCharacters)
                    if clean.count > 10 && clean.count < 150 { actionItems.append(clean); break }
                }
            }
            return true
        }
        return Array(Set(actionItems).prefix(5))
    }

    private func generateTitle(text: String, themes: [String]) -> String {
        if let firstTheme = themes.first {
            let words = text.components(separatedBy: .whitespaces).prefix(6).joined(separator: " ")
            return words.isEmpty ? firstTheme : "\(firstTheme) — \(words)..."
        }
        let words = text.components(separatedBy: .whitespaces).prefix(8).joined(separator: " ")
        return words.isEmpty ? "Journal Entry" : words + "..."
    }
}
