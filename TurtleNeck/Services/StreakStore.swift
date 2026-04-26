import Foundation

class StreakStore: ObservableObject {
    static let shared = StreakStore()
    private let streakKey = "postureStreak"
    private let lastGoodDayKey = "lastGoodPostureDay"

    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0

    init() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        bestStreak = UserDefaults.standard.integer(forKey: "bestStreak")
    }

    /// 하루가 끝날 때 호출 — 오늘 자세 점수가 70 이상이면 streak 유지
    func endOfDay(score: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = UserDefaults.standard.object(forKey: lastGoodDayKey) as? Date

        if score >= 70 {
            if let last = lastDay {
                let diff = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 0
                if diff == 1 {
                    currentStreak += 1
                } else if diff > 1 {
                    currentStreak = 1
                }
                // diff == 0 이면 이미 오늘 처리됨
            } else {
                currentStreak = 1
            }
            UserDefaults.standard.set(today, forKey: lastGoodDayKey)
        } else {
            currentStreak = 0
        }

        if currentStreak > bestStreak { bestStreak = currentStreak }
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(bestStreak, forKey: "bestStreak")
    }

    var streakEmoji: String {
        if currentStreak >= 30 { return "💎" }
        if currentStreak >= 14 { return "👑" }
        if currentStreak >= 7 { return "⭐" }
        if currentStreak >= 3 { return "🔥" }
        return "🐢"
    }
}
