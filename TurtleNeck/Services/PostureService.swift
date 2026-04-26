import Foundation
import Combine
import AppKit
import Vision

class PostureService: ObservableObject {
    static let shared = PostureService()

    private let camera = CameraService()
    private var cancellables = Set<AnyCancellable>()
    private var badPostureStart: Date?
    private var lastAlertTime: Date?
    private var currentLevel: TurtleLevel = .gentle
    private var goodPostureStart: Date?
    private var hasRecordedBadSession = false

    @Published var isPaused = false
    @Published var currentState: PostureState = .good

    private var settings: AppSettings { SettingsStore.shared.settings }
    private var calibration: CalibrationData? { CalibrationStore.shared.data }

    func start() {
        camera.start()
        camera.$faceLandmarks
            .compactMap { $0 }
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] face in self?.evaluate(face) }
            .store(in: &cancellables)
    }

    func stop() {
        camera.stop()
        cancellables.removeAll()
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused { camera.stop() } else { camera.start() }
    }

    private func evaluate(_ face: VNFaceObservation) {
        guard !isPaused, let cal = calibration else { return }
        if settings.scheduleEnabled && !isWithinSchedule() { return }
        if isDisabledAppActive() { return }
        if settings.pauseDuringFocus && isFocusModeActive() { return }

        let state = PostureAnalyzer.analyze(
            face: face, calibration: cal,
            threshold: settings.sensitivity.angleThreshold
        )

        if state != currentState {
            currentState = state
            NotificationCenter.default.post(name: .postureStateChanged,
                                            object: nil, userInfo: ["state": state])
        }

        switch state {
        case .bad, .warning:
            goodPostureStart = nil
            handleBadPosture(state)
        case .good:
            handleGoodPosture()
        }
    }

    private func handleBadPosture(_ state: PostureState) {
        let now = Date()
        if badPostureStart == nil {
            badPostureStart = now
            hasRecordedBadSession = false
        }

        guard let start = badPostureStart else { return }
        let elapsed = now.timeIntervalSince(start)

        if elapsed > 60 { currentLevel = .angry }
        else if elapsed > 20 { currentLevel = .annoyed }
        else { currentLevel = .gentle }

        // 쿨다운 체크
        if let last = lastAlertTime,
           now.timeIntervalSince(last) < Double(settings.cooldownSeconds) { return }

        // 5초 이상 나쁜 자세 유지 시 알림
        if elapsed >= 5 {
            lastAlertTime = now
            let message = MessageProvider.shared.badPostureMessage(level: currentLevel)
            TurtleOverlay.shared.show(level: currentLevel, message: message)
            StatsStore.shared.record(PostureRecord(state: state, duration: elapsed))
        }
    }

    private func handleGoodPosture() {
        // 나쁜 자세 세션 종료
        badPostureStart = nil
        currentLevel = .gentle
        hasRecordedBadSession = false

        let now = Date()
        if goodPostureStart == nil { goodPostureStart = now }
        if let start = goodPostureStart, now.timeIntervalSince(start) >= 1800 {
            let message = MessageProvider.goodPostureMessage()
            TurtleOverlay.shared.show(level: .gentle, message: message)
            goodPostureStart = now
            StatsStore.shared.record(PostureRecord(state: .good, duration: 1800))
        }
    }

    private func isWithinSchedule() -> Bool {
        let cal = Calendar.current
        let now = cal.dateComponents([.hour, .minute], from: Date())
        guard let nowMin = now.hour.map({ $0 * 60 + (now.minute ?? 0) }),
              let startMin = settings.scheduleStart.hour.map({ $0 * 60 + (settings.scheduleStart.minute ?? 0) }),
              let endMin = settings.scheduleEnd.hour.map({ $0 * 60 + (settings.scheduleEnd.minute ?? 0) }) else { return true }
        return nowMin >= startMin && nowMin <= endMin
    }

    private func isDisabledAppActive() -> Bool {
        let running = NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier }
        return settings.disabledApps.contains { running.contains($0) }
    }

    private func isFocusModeActive() -> Bool {
        // macOS Focus/DND 상태 확인 — 알림 설정에서 DND 활성 여부
        let center = DistributedNotificationCenter.default()
        // 직접 API가 없으므로 assertionStatus 확인
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["-currentHost", "read", "com.apple.notificationcenterui", "doNotDisturb"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        try? task.run()
        task.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return output.trimmingCharacters(in: .whitespacesAndNewlines) == "1"
    }
}
