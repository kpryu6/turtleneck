import Foundation

class MessageProvider {
    static let shared = MessageProvider()

    private let customKey = "customMessages"
    private let characterKey = "selectedCharacter"

    var selectedCharacter: CustomCharacter {
        get {
            if let d = UserDefaults.standard.data(forKey: characterKey),
               let c = try? JSONDecoder().decode(CustomCharacter.self, from: d) { return c }
            return .turtle
        }
        set {
            if let d = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(d, forKey: characterKey)
            }
        }
    }

    var customMessages: [CustomMessage] {
        get {
            guard let d = UserDefaults.standard.data(forKey: customKey) else { return [] }
            return (try? JSONDecoder().decode([CustomMessage].self, from: d)) ?? []
        }
        set {
            if let d = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(d, forKey: customKey)
            }
        }
    }

    // MARK: - Built-in messages
    private static let builtIn: [TurtleLevel: [String]] = [
        .gentle: [
            "Hey buddy, I came out just for you {char}",
            "Your neck is slowly creeping forward~",
            "One {name} is enough, don't become the second one",
            "Shoulders back, just a little~",
            "Psst... your posture is slipping",
            "Keep this up and you'll be swimming back to the ocean~ {char}",
        ],
        .annoyed: [
            "Again? I JUST told you 💢",
            "Please stop. One {name} per household is ENOUGH",
            "You're gonna regret this when you're old, trust me",
            "How many times do I have to say this... 💢",
            "Go look in a mirror right now. Seriously.",
            "Your spine called. It wants a divorce.",
            "I'm not mad, I'm just... disappointed 💢",
            "Hey, didn't you say you were SpongeBob's friend? {char}",
        ],
        .angry: [
            "SIT. UP. RIGHT. NOW. 🔥",
            "I'm actually furious. Not kidding anymore.",
            "You made me come to the CENTER of your screen {char}🔥",
            "Last warning. Fix it or I'm living here permanently.",
            "I came all the way here because of YOU. STRAIGHTEN UP!!!",
            "Your posture is a CRIME and I'm the police 🚨",
            "I will NOT leave until you sit properly. Try me.",
        ],
    ]

    func badPostureMessage(level: TurtleLevel) -> String {
        var all = Self.builtIn[level] ?? []
        let custom = customMessages.filter { $0.level == level }.map { $0.text }
        all += custom
        let raw = all.randomElement() ?? "Fix your posture~"
        return applyCharacter(raw)
    }

    static func goodPostureMessage() -> String {
        let char = MessageProvider.shared.selectedCharacter
        let raw = [
            "Look at you! Perfect posture! I'm so proud {char}👍",
            "30 minutes of great posture! You're a legend!",
            "Keep it up! You're doing amazing!",
            "A world where I don't need to show up... beautiful 🥹",
            "Posture KING! Keep slaying today!",
        ].randomElement()!
        return raw
            .replacingOccurrences(of: "{char}", with: char.emoji)
            .replacingOccurrences(of: "{name}", with: char.name)
    }

    func applyCharacter(_ text: String) -> String {
        let char = selectedCharacter
        return text
            .replacingOccurrences(of: "{char}", with: char.emoji)
            .replacingOccurrences(of: "{name}", with: char.name)
    }
}
