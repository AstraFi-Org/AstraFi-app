import Foundation

struct SearchUtility {
    /// Calculates the Levenshtein distance between two strings.
    /// Lower score = more similar.
    static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let empty = [Int](repeating: 0, count: s2.count + 1)
        var last = [Int](0...s2.count)
        
        for (i, char1) in s1.enumerated() {
            var current = [i + 1] + empty.suffix(s2.count)
            for (j, char2) in s2.enumerated() {
                current[j + 1] = char1 == char2 ? last[j] : min(last[j], last[j + 1], current[j]) + 1
            }
            last = current
        }
        return last.last!
    }

    /// Returns a score between 0.0 and 1.0 representing similarity.
    /// 1.0 is an exact match.
    static func fuzzyMatchScore(query: String, target: String) -> Double {
        if query.isEmpty { return 0.0 }
        let q = query.lowercased()
        let t = target.lowercased()
        
        // Exact match
        if q == t { return 1.0 }
        
        // Contains
        if t.contains(q) {
            // Priority boost for prefix match
            if t.hasPrefix(q) {
                return 0.9 + (Double(q.count) / Double(t.count) * 0.09)
            }
            return 0.8 + (Double(q.count) / Double(t.count) * 0.09)
        }
        
        // Fuzzy Levenshtein (only if query is long enough to avoid noise)
        if q.count >= 3 {
            let distance = Double(levenshteinDistance(q, t))
            let maxLength = Double(max(q.count, t.count))
            let score = 1.0 - (distance / maxLength)
            
            // Apply a threshold to ignore very poor matches
            return score > 0.6 ? score * 0.7 : 0.0
        }
        
        return 0.0
    }
}
