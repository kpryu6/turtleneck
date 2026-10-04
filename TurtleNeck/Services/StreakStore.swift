import Foundation

class StreakStore: ObservableObject {
    static let shared = StreakStore()
    private let streakKey = "postureStreak"
    private let bestKey = "bestStreak"
    private let settledKey = "streakSettledThrough"

    private let defaults: UserDefaults
    private var lastSettleCheck: Date?

    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        currentStreak = defaults.integer(forKey: streakKey)
        bestStreak = defaults.integer(forKey: bestKey)
    }

    /// 지나간 날짜들의 점수로 streak을 정산한다. 오늘은 아직 진행 중이라 제외.
    /// - 점수 70 이상인 날: streak +1
    /// - 70 미만인 날: streak 0
    /// - 기록이 없는 날(앱을 안 켠 주말 등): 끊지도 늘리지도 않음
    /// 매초 불려도 되도록 날짜가 바뀌었을 때만 실제로 계산한다.
    func settle(stats: StatsStore = .shared, now: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        if lastSettleCheck == today { return }
        lastSettleCheck = today

        var day: Date
        if let last = defaults.object(forKey: settledKey) as? Date {
            day = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: last))!
        } else if let first = stats.records.map(\.timestamp).min() {
            day = cal.startOfDay(for: first)
        } else {
            return
        }

        var current = currentStreak, best = bestStreak
        while day < today {
            if let score = stats.score(on: day) {
                current = score >= 70 ? current + 1 : 0
                best = max(best, current)
            }
            defaults.set(day, forKey: settledKey)
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }

        if (current, best) != (currentStreak, bestStreak) {
            currentStreak = current
            bestStreak = best
            defaults.set(current, forKey: streakKey)
            defaults.set(best, forKey: bestKey)
        }
    }

    var streakEmoji: String {
        if currentStreak >= 30 { return "💎" }
        if currentStreak >= 14 { return "👑" }
        if currentStreak >= 7 { return "⭐" }
        if currentStreak >= 3 { return "🔥" }
        return "🐢"
    }
}
