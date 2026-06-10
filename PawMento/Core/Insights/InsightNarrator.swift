import Foundation

struct NarratedInsightDTO: Codable {
    let headline: String
    let narrative: String
    let confidence: Double // 0.0 to 1.0
}

class InsightNarrator {
    static func scoreAndNarrate(candidates: [InsightCandidate], petContext: String) async throws -> [Insight] {
        guard !candidates.isEmpty else { return [] }
        
        let systemPrompt = """
        You are PawMento's Insight Narrator. Your job is to take raw statistical anomalies from the app's detection engine and turn them into empathetic, highly-readable insights for a pet owner.
        
        Rules:
        - Return ONLY a JSON array of objects.
        - Each object must have: `headline` (string, max 60 chars), `narrative` (string, max 240 chars), `confidence` (number between 0.5 and 0.99).
        - The narrative should explain the data calmly. Do NOT alarm the user.
        - Base the insights strictly on the provided candidates. Do not make up symptoms.
        
        Pet Context:
        \(petContext)
        """
        
        var userPrompt = "Here are the candidates detected by the engine:\n"
        for (i, c) in candidates.enumerated() {
            userPrompt += "Candidate \(i+1): Type=\(c.type.rawValue), EvidenceCount=\(c.evidenceCount), Details=\(c.internalDescription)\n"
        }
        
        // Use Anthropic directly to get JSON
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(Secrets.anthropicApiKey, forHTTPHeaderField: "x-api-key")
        
        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307", // Using haiku for speed and cost
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Parse Anthropic's response structure
        // { "content": [ { "text": "[ { ... } ]" } ] }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstBlock = contentArray.first,
              let text = firstBlock["text"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        
        // Find JSON array in the text (LLMs sometimes wrap it in markdown)
        var jsonText = text
        if let startIndex = jsonText.firstIndex(of: "["), let endIndex = jsonText.lastIndex(of: "]") {
            jsonText = String(jsonText[startIndex...endIndex])
        }
        
        guard let jsonData = jsonText.data(using: .utf8) else { throw URLError(.cannotParseResponse) }
        let dtos = try JSONDecoder().decode([NarratedInsightDTO].self, from: jsonData)
        
        var finalInsights: [Insight] = []
        for (i, dto) in dtos.enumerated() {
            if i < candidates.count {
                let candidate = candidates[i]
                
                let tier: ConfidenceTier
                if dto.confidence >= 0.85 { tier = .strong }
                else if dto.confidence >= 0.70 { tier = .moderate }
                else { tier = .emerging }
                
                // Fallback chart type
                let chartType: String
                switch candidate.type {
                case .correlation: chartType = "sparkline"
                case .temporal: chartType = "bar"
                case .trend: chartType = "line"
                case .positive: chartType = "streak"
                }
                
                let insight = Insight(
                    id: UUID(),
                    type: candidate.type,
                    tier: tier,
                    headline: dto.headline,
                    narrative: dto.narrative,
                    confidence: dto.confidence,
                    evidenceCount: candidate.evidenceCount,
                    visualization: VisualizationData(dataPoints: [0, 1, 2, 1, 3], labels: nil, chartType: chartType),
                    actions: [InsightAction(title: "Share with vet ›", isPrimary: false)],
                    generatedAt: Date()
                )
                finalInsights.append(insight)
            }
        }
        
        return finalInsights
    }
}
