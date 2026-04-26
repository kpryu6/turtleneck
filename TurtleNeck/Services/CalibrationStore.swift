import Foundation

class CalibrationStore: ObservableObject {
    static let shared = CalibrationStore()
    private let key = "calibrationData"

    @Published var data: CalibrationData?

    var isCalibrated: Bool { data != nil }

    init() {
        if let d = UserDefaults.standard.data(forKey: key) {
            data = try? JSONDecoder().decode(CalibrationData.self, from: d)
        }
    }

    func save(_ calibration: CalibrationData) {
        data = calibration
        if let encoded = try? JSONEncoder().encode(calibration) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
        NotificationCenter.default.post(name: .calibrationCompleted, object: nil)
    }
}
