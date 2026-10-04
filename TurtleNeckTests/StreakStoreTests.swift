import XCTest

final class StreakStoreTests: XCTestCase {
    private let cal = Calendar.current
    private var today: Date { cal.startOfDay(for: Date()) }

    private func day(_ offset: Int) -> Date {
        cal.date(byAdding: .hour, value: 10, to: cal.date(byAdding: .day, value: offset, to: today)!)!
    }
    private func good(_ offset: Int) -> PostureRecord { PostureRecord(state: .good, duration: 1800, timestamp: day(offset)) }
    private func bad(_ offset: Int) -> PostureRecord { PostureRecord(state: .bad, duration: 1200, timestamp: day(offset)) } // score 0

    private func freshDefaults() -> UserDefaults {
        let name = "TurtleNeckTests.\(UUID())"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testDaysWithoutRecordsDoNotBreakStreak() {
        // Mon–Fri good, weekend without data, two more good days, today still in progress
        let stats = StatsStore(records: [good(-9), good(-8), good(-7), good(-6), good(-5), good(-2), good(-1), bad(0)])
        let streak = StreakStore(defaults: freshDefaults())
        streak.settle(stats: stats)
        XCTAssertEqual(streak.currentStreak, 7)
        XCTAssertEqual(streak.bestStreak, 7)
    }

    func testBadDayResetsStreak() {
        let stats = StatsStore(records: [good(-5), good(-4), bad(-3), good(-2), good(-1)])
        let streak = StreakStore(defaults: freshDefaults())
        streak.settle(stats: stats)
        XCTAssertEqual(streak.currentStreak, 2)
        XCTAssertEqual(streak.bestStreak, 2)
    }

    func testSettleIsIdempotentPersistedAndIncremental() {
        let defaults = freshDefaults()
        let stats = StatsStore(records: [good(-3), good(-2), good(-1), good(0)])
        let streak = StreakStore(defaults: defaults)
        streak.settle(stats: stats)
        streak.settle(stats: stats)
        XCTAssertEqual(streak.currentStreak, 3)

        let relaunched = StreakStore(defaults: defaults)
        relaunched.settle(stats: stats)
        XCTAssertEqual(relaunched.currentStreak, 3)

        relaunched.settle(stats: stats, now: day(1)) // tomorrow: today's good day settles
        XCTAssertEqual(relaunched.currentStreak, 4)
    }

    func testNoRecords() {
        let streak = StreakStore(defaults: freshDefaults())
        streak.settle(stats: StatsStore(records: []))
        XCTAssertEqual(streak.currentStreak, 0)
    }

    func testScoreOnDay() {
        let stats = StatsStore(records: [PostureRecord(state: .bad, duration: 180, timestamp: day(-1))])
        XCTAssertEqual(stats.score(on: day(-1)), 85)
        XCTAssertNil(stats.score(on: day(-2)))
    }
}
