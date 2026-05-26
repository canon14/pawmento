import Foundation

class BreedStore {
    static let shared = BreedStore()
    
    private var dogBreeds: [String] = []
    private var catBreeds: [String] = []
    private var rabbitBreeds: [String] = []
    
    private init() {
        loadBreeds()
    }
    
    private func loadBreeds() {
        guard let url = Bundle.main.url(forResource: "breeds", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String]] else {
            return
        }
        
        self.dogBreeds = json["dog"] ?? []
        self.catBreeds = json["cat"] ?? []
        self.rabbitBreeds = json["rabbit"] ?? []
    }
    
    func suggestBreeds(for species: Species, query: String) -> [String] {
        let allBreeds: [String]
        switch species {
        case .dog: allBreeds = dogBreeds
        case .cat: allBreeds = catBreeds
        case .rabbit: allBreeds = rabbitBreeds
        case .other: return []
        }
        
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return Array(allBreeds.prefix(5))
        }
        
        let lowerQuery = query.lowercased()
        
        // Exact prefix match first
        var results = allBreeds.filter { $0.lowercased().hasPrefix(lowerQuery) }
        
        // Contains match second
        let contains = allBreeds.filter { $0.lowercased().contains(lowerQuery) && !$0.lowercased().hasPrefix(lowerQuery) }
        results.append(contentsOf: contains)
        
        // Levenshtein distance fallback for fuzzy match (simple implementation)
        if results.count < 5 {
            let others = allBreeds.filter { !results.contains($0) }
            let fuzzy = others.filter { levenshtein(a: $0.lowercased(), b: lowerQuery) <= 2 }
            results.append(contentsOf: fuzzy)
        }
        
        return Array(results.prefix(5))
    }
    
    private func levenshtein(a: String, b: String) -> Int {
        let aCount = a.count
        let bCount = b.count
        guard aCount > 0 else { return bCount }
        guard bCount > 0 else { return aCount }
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: bCount + 1), count: aCount + 1)
        for i in 1...aCount { matrix[i][0] = i }
        for j in 1...bCount { matrix[0][j] = j }
        
        let aChars = Array(a)
        let bChars = Array(b)
        
        for i in 1...aCount {
            for j in 1...bCount {
                let cost = (aChars[i - 1] == bChars[j - 1]) ? 0 : 1
                matrix[i][j] = min(matrix[i - 1][j] + 1,
                                   matrix[i][j - 1] + 1,
                                   matrix[i - 1][j - 1] + cost)
            }
        }
        return matrix[aCount][bCount]
    }
}
