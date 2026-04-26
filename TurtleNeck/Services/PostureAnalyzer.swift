import Vision
import Foundation

struct PostureAnalyzer {
    /// 얼굴 관찰 결과로 거북목 판별
    /// - 얼굴 Y 위치가 내려감 → 머리가 앞으로 숙여짐
    /// - 얼굴 크기가 커짐 → 카메라에 가까워짐 (앞으로 나옴)
    /// - 코의 상대 위치 변화 → 머리 기울기
    static func analyze(face: VNFaceObservation, calibration: CalibrationData, threshold: Double) -> PostureState {
        let box = face.boundingBox

        // 1) 얼굴 Y 위치 변화 (내려가면 거북목)
        let yDiff = (calibration.faceY - Double(box.origin.y)) * 100

        // 2) 얼굴 크기 변화 (커지면 앞으로 나옴)
        let sizeDiff = (Double(box.height) - calibration.faceHeight) / calibration.faceHeight * 100

        // 종합 점수 (두 지표 합산)
        let score = max(yDiff, 0) + max(sizeDiff, 0)

        if score > threshold * 1.5 {
            return .bad
        } else if score > threshold {
            return .warning
        }
        return .good
    }
}
