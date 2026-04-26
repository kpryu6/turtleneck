import Foundation

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    private let key = "appSettings"

    @Published var settings: AppSettings

    init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let s = try? JSONDecoder().decode(AppSettings.self, from: d) {
            settings = s
        } else {
            settings = .default
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
