import XCTest
@testable import PawMento

final class AICoachClientStreamRetryTests: XCTestCase {
    
    private let timeoutError = URLError(.timedOut)
    private let connectionLostError = URLError(.networkConnectionLost)
    private let serverError = NSError(
        domain: "AIProxy",
        code: 503,
        userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
    )
    private let nonRetryableError = NSError(
        domain: "AIProxy",
        code: 400,
        userInfo: [NSLocalizedDescriptionKey: "Bad request"]
    )
    
    func testShouldRetry_beforeAnyContent_onRetryableError() {
        XCTAssertTrue(
            AICoachClient.shouldRetryStream(
                after: timeoutError,
                hasYieldedContent: false,
                attempt: 0,
                maxAttempts: 3
            )
        )
    }
    
    func testShouldRetry_afterPartialContent_neverRetries() {
        XCTAssertFalse(
            AICoachClient.shouldRetryStream(
                after: connectionLostError,
                hasYieldedContent: true,
                attempt: 0,
                maxAttempts: 3
            )
        )
        XCTAssertFalse(
            AICoachClient.shouldRetryStream(
                after: serverError,
                hasYieldedContent: true,
                attempt: 0,
                maxAttempts: 3
            )
        )
    }
    
    func testShouldRetry_onNonRetryableError() {
        XCTAssertFalse(
            AICoachClient.shouldRetryStream(
                after: nonRetryableError,
                hasYieldedContent: false,
                attempt: 0,
                maxAttempts: 3
            )
        )
    }
    
    func testShouldRetry_onFinalAttempt() {
        XCTAssertFalse(
            AICoachClient.shouldRetryStream(
                after: timeoutError,
                hasYieldedContent: false,
                attempt: 2,
                maxAttempts: 3
            )
        )
    }
    
    func testSimulatedMidStreamFailure_doesNotDuplicatePrefix() async {
        let stream = AsyncThrowingStream<String, Error> { continuation in
            Task {
                var hasYieldedContent = false
                let partialPrefix = "Hello"
                
                continuation.yield(partialPrefix)
                hasYieldedContent = true
                
                let midStreamError = URLError(.networkConnectionLost)
                guard AICoachClient.shouldRetryStream(
                    after: midStreamError,
                    hasYieldedContent: hasYieldedContent,
                    attempt: 0,
                    maxAttempts: AIConfig.maxRetries
                ) else {
                    continuation.finish(throwing: midStreamError)
                    return
                }
                
                // Retry path would re-emit the prefix — must not run after partial output.
                continuation.yield(partialPrefix)
                continuation.finish()
            }
        }
        
        var collected = ""
        do {
            for try await token in stream {
                collected += token
            }
            XCTFail("Expected stream to fail after partial output")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .networkConnectionLost)
            XCTAssertEqual(collected, "Hello")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
