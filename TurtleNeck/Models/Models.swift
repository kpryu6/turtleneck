import Foundation

// MARK: - Posture State
enum PostureState: String, Codable {
    case good, warning, bad

    var labelEN: String {
        switch self {
        case .good: return "Good"
        case .warning: return "Warning"
        case .bad: return "Bad"
        }
    }
}

// MARK: - Turtle Level
enum TurtleLevel: Int, CaseIterable, Codable {
    case gentle = 1
    case annoyed = 2
    case angry = 3

    var size: CGFloat {
        switch self {
        case .gentle: return 150
        case .annoyed: return 250
        case .angry: return 400
        }
    }

    var emoji: String {
        switch self {
        case .gentle: return "🐢"
        case .annoyed: return "🐢💢"
        case .angry: return "🐢🔥"
        }
    }
}

// MARK: - Calibration Data
struct CalibrationData: Codable {
    var faceY: Double
    var faceHeight: Double
    var noseRelativeX: Double
    var timestamp: Date
}

// MARK: - Posture Record
struct PostureRecord: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let state: PostureState
    let duration: TimeInterval

    init(state: PostureState, duration: TimeInterval) {
        self.id = UUID()
        self.timestamp = Date()
        self.state = state
        self.duration = duration
    }
}

// MARK: - Settings
struct AppSettings: Codable, Equatable {
    var sensitivity: Sensitivity
    var cooldownSeconds: Int
    var scheduleEnabled: Bool
    var scheduleStart: DateComponents
    var scheduleEnd: DateComponents
    var disabledApps: [String]
    var launchAtLogin: Bool
    var pauseDuringFocus: Bool

    enum Sensitivity: String, Codable, CaseIterable {
        case strict, normal, loose

        var labelEN: String {
            switch self {
            case .strict: return "Strict"
            case .normal: return "Normal"
            case .loose: return "Loose"
            }
        }

        var angleThreshold: Double {
            switch self {
            case .strict: return 8
            case .normal: return 25
            case .loose: return 40
            }
        }
    }

    static var `default`: AppSettings {
        AppSettings(
            sensitivity: .normal,
            cooldownSeconds: 30,
            scheduleEnabled: false,
            scheduleStart: DateComponents(hour: 9, minute: 0),
            scheduleEnd: DateComponents(hour: 18, minute: 0),
            disabledApps: [],
            launchAtLogin: false,
            pauseDuringFocus: false
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let postureStateChanged = Notification.Name("postureStateChanged")
    static let calibrationCompleted = Notification.Name("calibrationCompleted")
}

// MARK: - Custom Character
struct CustomCharacter: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var emoji: String
    var imagePath: String? // 커스텀 이미지 경로

    init(name: String, emoji: String, imagePath: String? = nil) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.imagePath = imagePath
    }

    var hasImage: Bool { imagePath != nil }

    static let turtle = CustomCharacter(name: "Turtle", emoji: "🐢")
    static let presets: [CustomCharacter] = [
        .turtle,
        CustomCharacter(name: "Cat", emoji: "🐱"),
        CustomCharacter(name: "Dog", emoji: "🐶"),
        CustomCharacter(name: "Owl", emoji: "🦉"),
        CustomCharacter(name: "Penguin", emoji: "🐧"),
        CustomCharacter(name: "Sloth", emoji: "🦥"),
        CustomCharacter(name: "SpongeBob", emoji: "🧽"),
    ]
}

// MARK: - Custom Message
struct CustomMessage: Codable, Equatable, Identifiable {
    let id: UUID
    var text: String
    var level: TurtleLevel

    init(text: String, level: TurtleLevel) {
        self.id = UUID()
        self.text = text
        self.level = level
    }
}
