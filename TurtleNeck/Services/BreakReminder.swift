import Foundation
import AppKit

class BreakReminder: ObservableObject {
    static let shared = BreakReminder()

    @Published var isActive = false
    @Published var workMinutes: Int = 50
    @Published var breakMinutes: Int = 10
    @Published var minutesRemaining: Int = 50
    @Published var isBreakTime = false

    private var timer: Timer?

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
