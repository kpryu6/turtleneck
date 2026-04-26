import Foundation

class StatsStore: ObservableObject {
    static let shared = StatsStore()
    private let key = "postureRecords"

    @Published var records: [PostureRecord] = []

    struct DailyData {
        let date: Date
        let badCount: Int
        let totalBadDuration: TimeInterval
    }

    init() {
        if let d = UserDefaults.standard.data(forKey: key) {
            records = (try? JSONDecoder().decode([PostureRecord].self, from: d)) ?? []
        }
    }

    func record(_ entry: PostureRecord) {
        records.append(entry)
        save()
    }

    var todayRecords: [PostureRecord] {
        let cal = Calendar.current
        return records.filter { cal.isDateInToday($0.timestamp) }
    }

    var weeklyData: [DailyData] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset -> DailyData? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let dayRecords = records.filter { cal.isDate($0.timestamp, inSameDayAs: date) && $0.state != .good }
            return DailyData(date: date, badCount: dayRecords.count,
                           totalBadDuration: dayRecords.reduce(0) { $0 + $1.duration })
        }
    }

    private func save() {
        // 최근 30일만 보관
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        records = records.filter { $0.timestamp > cutoff }
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
