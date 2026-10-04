import XCTest

final class BreakReminderTests: XCTestCase {
    func testSettingsPersistAndResumeAfterRestart() {
        let name = "TurtleNeckTests.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)

        let reminder = BreakReminder(defaults: defaults)
        reminder.workMinutes = 25
        reminder.breakMinutes = 5
        reminder.start()

        let restarted = BreakReminder(defaults: defaults)
        XCTAssertEqual(restarted.workMinutes, 25)
        XCTAssertEqual(restarted.breakMinutes, 5)
        XCTAssertFalse(restarted.isActive)
        restarted.resumeIfEnabled()
        XCTAssertTrue(restarted.isActive)
        XCTAssertEqual(restarted.minutesRemaining, 25)

        restarted.stop()
        let afterStop = BreakReminder(defaults: defaults)
        afterStop.resumeIfEnabled()
        XCTAssertFalse(afterStop.isActive)
    }
}
