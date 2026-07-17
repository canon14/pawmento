import Foundation
import Supabase

enum NarratorError: Error {
    case badServerResponse(Int)
    case cannotParseResponse
    case missingJsonArray
}

struct NarratedInsightDTO: Codable {
    let id: String
    let headline: String
    let narrative: String
    var confidence: Double // 0.0 to 1.0
}

class InsightNarrator {
    static var session: URLSession = .shared
    
    private static func evidenceAnchor(for candidate: InsightCandidate) -> Double {
        if candidate.isRuleBased { return 0.90 }
        switch candidate.evidenceCount {
        case 0...2: return 0.55
        case 3...4: return 0.68
        case 5...7: return 0.78
        default: return 0.86
        }
    }
    
    static func scoreAndNarrate(candidates: [InsightCandidate], petContext: String) async -> [Insight] {
        guard !candidates.isEmpty else { return [] }
        
        do {
            return try await fetchAndParseInsights(candidates: candidates, petContext: petContext)
        } catch {
            return localFallback(candidates: candidates)
        }
    }
    
    private static func fetchAndParseInsights(candidates: [InsightCandidate], petContext: String) async throws -> [Insight] {
        // Fix I10 + I4: Non-causal instruction added to narrator prompt
        let systemPrompt = """
        You are PawMento's Insight Narrator. Your job is to take raw statistical anomalies from the app's detection engine and turn them into empathetic, highly-readable insights for a pet owner.
        
        Rules:
        - Return ONLY a JSON array of objects.
        - Each object must have: `id` (string, exact copy from the candidate), `headline` (string, max 60 chars), `narrative` (string, max 240 chars), `confidence` (number between 0.5 and 0.99).
        - Provide exactly one object per candidate. Do not invent or omit candidates.
        - The narrative should explain the data calmly. Do NOT alarm the user.
        - Base the insights strictly on the provided candidates. Do not make up symptoms.
        - NEVER imply causation. Use "may be associated with", "pattern observed", or "worth discussing with your vet" — NOT "causes", "triggers", or "leads to". This is correlational data, not a diagnosis.
        
        Pet Context:
        \(petContext)
        """
        
        var userPrompt = "Here are the candidates detected by the engine:\n"
        for c in candidates {
            userPrompt += "Candidate: id=\(c.id.uuidString), Type=\(c.type.rawValue), EvidenceCount=\(c.evidenceCount), Details=\(c.internalDescription)\n"
        }
        
        var lastError: Error?
        var dtos: [NarratedInsightDTO] = []
        
        for attempt in 0..<AIConfig.maxRetries {
            do {
                dtos = try await performRequest(systemPrompt: systemPrompt, userPrompt: userPrompt, candidateCount: candidates.count)
                lastError = nil
                break
            } catch {
                lastError = error
                
                // Retry only on network/transient/non-200 errors.
                let shouldRetry = (error as? NarratorError).map {
                    if case .badServerResponse = $0 { return true }
                    return false
                } ?? (error is URLError)
                
                guard shouldRetry else { throw error }
                
                let backoff = 0.4 * pow(2.0, Double(attempt))
                try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
            }
        }
        
        if let error = lastError {
            throw error
        }
        
        var candidateDict: [String: InsightCandidate] = [:]
        for c in candidates {
            candidateDict[c.id.uuidString.lowercased()] = c
        }
        
        var finalInsights: [Insight] = []
        var matchedCandidateIds = Set<String>()
        
        for (_, var dto) in dtos.enumerated() {
            // Fix I5: Only match by exact id — NO positional fallback.
            // If the LLM reordered or invented ids, discard the DTO.
            // The unmatched candidate will be routed through localFallback below.
            guard let candidate = candidateDict[dto.id.lowercased()] else {
                print("Warning: InsightNarrator DTO id \(dto.id) does not match any candidate — discarding (not falling back to index).")
                continue
            }
            
            let candidateKey = candidate.id.uuidString.lowercased()
            guard !matchedCandidateIds.contains(candidateKey) else {
                print("Warning: InsightNarrator duplicate DTO for candidate \(dto.id) — skipping.")
                continue
            }
            matchedCandidateIds.insert(candidateKey)
            
            // Validate decoded confidence is finite and within 0...1
            if !dto.confidence.isFinite { dto.confidence = 0.5 }
            dto.confidence = max(0.0, min(1.0, dto.confidence))
                
            // Statistics anchor the paywall, the LLM only fine-tunes narration.
            let anchor = evidenceAnchor(for: candidate)
            let llmDiff = max(-0.10, min(0.10, dto.confidence - anchor))
            let finalConfidence = max(0.5, min(0.99, anchor + llmDiff))
            
            let tier: ConfidenceTier
            if candidate.type == .positive {
                tier = .positive
            } else if finalConfidence >= 0.85 {
                tier = .strong
            } else if finalConfidence >= 0.70 {
                tier = .moderate
            } else {
                tier = .emerging
            }
            
            let chartType = fallbackChartType(for: candidate.type)
            let visualization = candidate.precomputedVisualization ?? VisualizationData(dataPoints: [], labels: nil, chartType: chartType)
            
            let insight = Insight(
                id: Insight.stableId(
                    type: candidate.type,
                    evidenceCount: candidate.evidenceCount,
                    isRuleBased: candidate.isRuleBased,
                    fingerprint: candidate.dismissalFingerprint
                ),
                type: candidate.type,
                tier: tier,
                headline: dto.headline,
                narrative: dto.narrative,
                confidence: finalConfidence,
                evidenceCount: candidate.evidenceCount,
                visualization: visualization,
                actions: [InsightAction(title: "Share with vet ›", isPrimary: false)],
                generatedAt: Date()
            )
            finalInsights.append(insight)
        }
        
        // Ensure every candidate produces an Insight
        let unmatchedCandidates = candidates.filter { !matchedCandidateIds.contains($0.id.uuidString.lowercased()) }
        if !unmatchedCandidates.isEmpty {
            let fallbackInsights = localFallback(candidates: unmatchedCandidates)
            finalInsights.append(contentsOf: fallbackInsights)
        }
        
        return finalInsights
    }
    
    // Fix I2: Route through Supabase Edge Function proxy instead of calling Anthropic directly.
    // The Edge Function holds the API key server-side and verifies the user's auth token.
    private static func performRequest(systemPrompt: String, userPrompt: String, candidateCount: Int) async throws -> [NarratedInsightDTO] {
        // Fix I10: Scale max_tokens proportionally to candidate count
        let maxTokens = min(4096, max(512, candidateCount * 300))
        
        // Build the proxy request body — the Edge Function will forward to Anthropic
        let body: [String: Any] = [
            "provider": "anthropic",
            "model": AIConfig.haikuModel,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]
        
        let url = URL(string: "\(Secrets.supabaseURL)/functions/v1/ai-proxy")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = AIConfig.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Fix I2: Use the user's Supabase session token for auth — no API key in the client bundle
        if let session = try? await SupabaseManager.shared.client.auth.session {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NarratorError.badServerResponse(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstBlock = contentArray.first,
              var text = firstBlock["text"] as? String else {
            throw NarratorError.cannotParseResponse
        }
        
        text = text.replacingOccurrences(of: "```json", with: "")
        text = text.replacingOccurrences(of: "```", with: "")
        
        guard let startIndex = text.firstIndex(of: "["),
              let endIndex = text.lastIndex(of: "]") else {
            throw NarratorError.missingJsonArray
        }
        
        let jsonText = String(text[startIndex...endIndex])
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw NarratorError.cannotParseResponse
        }
        
        return try JSONDecoder().decode([NarratedInsightDTO].self, from: jsonData)
    }
    
    private static func localFallback(candidates: [InsightCandidate]) -> [Insight] {
        var finalInsights: [Insight] = []
        for candidate in candidates {
            let anchor = evidenceAnchor(for: candidate)
            
            let tier: ConfidenceTier
            if candidate.type == .positive {
                tier = .positive
            } else if anchor >= 0.85 {
                tier = .strong
            } else if anchor >= 0.70 {
                tier = .moderate
            } else {
                tier = .emerging
            }
            
            let headline = candidate.precomputedHeadline ?? "New Observation"
            let narrative = candidate.precomputedNarrative ?? "We noticed some interesting activity. Keep logging to help us learn more."
            let chartType = fallbackChartType(for: candidate.type)
            let visualization = candidate.precomputedVisualization ?? VisualizationData(dataPoints: [], labels: nil, chartType: chartType)
            
            let insight = Insight(
                id: Insight.stableId(
                    type: candidate.type,
                    evidenceCount: candidate.evidenceCount,
                    isRuleBased: candidate.isRuleBased,
                    fingerprint: candidate.dismissalFingerprint
                ),
                type: candidate.type,
                tier: tier,
                headline: headline,
                narrative: narrative,
                confidence: anchor,
                evidenceCount: candidate.evidenceCount,
                visualization: visualization,
                actions: [InsightAction(title: "Share with vet ›", isPrimary: false)],
                generatedAt: Date()
            )
            finalInsights.append(insight)
        }
        return finalInsights
    }
    
    private static func fallbackChartType(for type: InsightType) -> String {
        switch type {
        case .correlation: return "sparkline"
        case .temporal: return "bar"
        case .trend: return "line"
        case .positive: return "streak"
        }
    }
}
