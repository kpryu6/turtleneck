import Foundation
import AppKit

class BreakReminder: ObservableObject {
    static let shared = BreakReminder()

    private enum Key {
        static let active = "breakReminderActive"
        static let work = "breakWorkMinutes"
        static let rest = "breakRestMinutes"
    }
    private let defaults: UserDefaults

    // 켜짐 여부와 시간 설정은 재시작 후에도 유지된다
    @Published private(set) var isActive = false {
        didSet { defaults.set(isActive, forKey: Key.active) }
    }
    @Published var workMinutes: Int = 50 {
        didSet { defaults.set(workMinutes, forKey: Key.work) }
    }
    @Published var breakMinutes: Int = 10 {
        didSet { defaults.set(breakMinutes, forKey: Key.rest) }
    }
    @Published var minutesRemaining: Int = 50
    @Published var isBreakTime = false

    private var timer: Timer?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Key.work) != nil { workMinutes = defaults.integer(forKey: Key.work) }
        if defaults.object(forKey: Key.rest) != nil { breakMinutes = defaults.integer(forKey: Key.rest) }
        minutesRemaining = workMinutes
    }

    /// 앱 시작 시 호출 — 지난번에 켜 두었다면 작업 타이머를 다시 시작
    func resumeIfEnabled() {
        if defaults.bool(forKey: Key.active) && !isActive { start() }
    }

    func start() {
        isActive = true
        minutesRemaining = workMinutes
        isBreakTime = false
        scheduleTimer()
    }

    func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }

    func toggle() {
        if isActive { stop() } else { start() }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        minutesRemaining -= 1

        if minutesRemaining <= 0 {
            if isBreakTime {
                // 휴식 끝 → 다시 작업
                isBreakTime = false
                minutesRemaining = workMinutes
                TurtleOverlay.shared.show(level: .gentle,
                    message: "Break's over! Back to work with good posture 💪")
            } else {
                // 작업 끝 → 휴식 시작
                isBreakTime = true
                minutesRemaining = breakMinutes
                TurtleOverlay.shared.show(level: .annoyed,
                    message: "Time for a break! Stand up, stretch, move around 🧘")
                NSSound.beep()
            }
        }
    }
}
