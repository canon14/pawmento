import SwiftUI
import Combine

enum TimelineBucket: Equatable, Hashable {
    case today
    case yesterday
    case thisWeek
    case earlierThisMonth
    case monthYear(String, Date)
    
    var title: String {
        switch self {
        case .today: return "TODAY"
        case .yesterday: return "YESTERDAY"
        case .thisWeek: return "THIS WEEK"
        case .earlierThisMonth: return "EARLIER THIS MONTH"
        case .monthYear(let str, _): return str.uppercased()
        }
    }
}

struct BucketGroup: Identifiable {
    let id = UUID()
    let bucket: TimelineBucket
    let headerSubtitle: String?
    let logs: [LogEntry]
}

@MainActor
class FullTimelineViewModel: ObservableObject {
    @Published var filteredLogs: [LogEntry] = []
    @Published var bucketedLogs: [BucketGroup] = []
    
    @Published var selectedFilter: String = "All"
    @Published var searchQuery: String = ""
    
    @Published var showBanner: Bool = true
    @Published var bannerPermanentlyDismissed: Bool = false
    
    // Support premium alerts
    @Published var showPremiumAlert: Bool = false
    
    private var allLogs: [LogEntry] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Debounce search
        $searchQuery
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .combineLatest($selectedFilter)
            .sink { [weak self] query, filter in
                self?.recompute(query: query, filter: filter)
            }
            .store(in: &cancellables)
            
        $selectedFilter
            .dropFirst()
            .sink { [weak self] filter in
                self?.recompute(query: self?.searchQuery ?? "", filter: filter)
            }
            .store(in: &cancellables)
    }
    
    func ingest(logs: [LogEntry]) {
        self.allLogs = logs
        recompute(query: searchQuery, filter: selectedFilter)
    }
    
    var lastLoggedTimeText: String {
        guard let last = allLogs.max(by: { $0.recordedAt < $1.recordedAt }) else { return "No logs added yet." }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "last logged \(formatter.localizedString(for: last.recordedAt, relativeTo: Date()))"
    }
    
    private func recompute(query: String, filter: String) {
        var result = allLogs
        
        // Category Filter
        if filter != "All" {
            result = result.filter { log in
                switch filter {
                case "Symptoms": return log.category == .symptom || log.category == .energy
                case "Meals": return log.category == .meal || log.category == .water || log.category == .appetite
                case "Meds": return log.category == .med
                case "Walks": return log.category == .walk || log.category == .play
                case "Sleep": return log.category == .sleep
                case "Notes": return log.category == .other || log.category == .training || log.category == .mood || log.category == .potty || log.category == .grooming
                case "Vet visits": return log.category == .vetVisit
                default: return true
                }
            }
        }
        
        // Search Filter
        if !query.isEmpty {
            let lowerQuery = query.lowercased()
            result = result.filter {
                $0.category.rawValue.lowercased().contains(lowerQuery) ||
                ($0.note?.lowercased().contains(lowerQuery) ?? false)
            }
        }
        
        self.filteredLogs = result
        
        // Bucketing
        var groups: [TimelineBucket: [LogEntry]] = [:]
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: today))!
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM yyyy"
        
        for log in result {
            let logDate = cal.startOfDay(for: log.recordedAt)
            var bucket: TimelineBucket
            
            if logDate == today {
                bucket = .today
            } else if logDate == yesterday {
                bucket = .yesterday
            } else if logDate >= startOfWeek {
                bucket = .thisWeek
            } else if logDate >= startOfMonth {
                bucket = .earlierThisMonth
            } else {
                let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: logDate))!
                bucket = .monthYear(formatter.string(from: logDate), monthStart)
            }
            
            groups[bucket, default: []].append(log)
        }
        
        // Sort chronologically descending
        let sortedBuckets: [TimelineBucket] = groups.keys.sorted { a, b in
            if a == b { return false }
            
            let fixedOrder: [TimelineBucket] = [.today, .yesterday, .thisWeek, .earlierThisMonth]
            if let aIdx = fixedOrder.firstIndex(of: a), let bIdx = fixedOrder.firstIndex(of: b) {
                return aIdx < bIdx
            } else if fixedOrder.firstIndex(of: a) != nil {
                return true
            } else if fixedOrder.firstIndex(of: b) != nil {
                return false
            }
            
            if case .monthYear(_, let aDate) = a, case .monthYear(_, let bDate) = b {
                return aDate > bDate
            }
            
            return false
        }
        
        let dFormatter = DateFormatter()
        dFormatter.locale = Locale(identifier: "en_US_POSIX")
        dFormatter.dateFormat = "EEE MMM d"
        
        self.bucketedLogs = sortedBuckets.compactMap { bucket in
            guard let logs = groups[bucket] else { return nil }
            
            var subtitle: String? = nil
            if bucket == .today { subtitle = dFormatter.string(from: today) }
            if bucket == .yesterday { subtitle = dFormatter.string(from: yesterday) }
            
            let sortedLogs = logs.sorted { $0.recordedAt > $1.recordedAt }
            return BucketGroup(bucket: bucket, headerSubtitle: subtitle, logs: sortedLogs)
        }
    }
    
    // Per-row dynamic insight computation replacing mock string
    func getInsightBadge(for log: LogEntry) -> String? {
        guard log.category == .symptom, let note = log.note?.lowercased(), !note.isEmpty else { return nil }
        
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: log.recordedAt)) else { return nil }
        guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { return nil }
        
        let occurrences = allLogs.filter { 
            $0.category == .symptom && 
            $0.note?.lowercased() == note && 
            $0.recordedAt >= monthStart && 
            $0.recordedAt < nextMonth &&
            $0.recordedAt <= log.recordedAt
        }.count
        
        if occurrences >= 3 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .ordinal
            let ordinal = formatter.string(from: NSNumber(value: occurrences)) ?? "\(occurrences)th"
            return "\(ordinal) time this month"
        }
        return nil
    }
}
