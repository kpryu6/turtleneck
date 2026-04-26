import SwiftUI
import Vision
import AVFoundation
import AppKit

struct CameraPreview: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeNSView(context: Context) -> NSView {
        let view = FlippedView()
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if previewLayer.superlayer == nil {
            previewLayer.videoGravity = .resizeAspectFill
            nsView.layer?.addSublayer(previewLayer)
        }
        previewLayer.frame = nsView.bounds
    }
}

class FlippedView: NSView {
    override func layout() {
        super.layout()
        layer?.sublayers?.forEach { $0.frame = bounds }
    }
}

struct CalibrationView: View {
    @StateObject private var camera = CameraService()
    @State private var countdown = 5
    @State private var isCalibrating = false
    @State private var isDone = false
    @State private var failMessage: String?
    @State private var timer: Timer?
    @State private var showResetConfirm = false

    var isRecalibration: Bool { CalibrationStore.shared.isCalibrated }

    var body: some View {
        VStack(spacing: 16) {
            Text("Calibration").font(.title.bold())

            if !isDone {
                CameraPreview(previewLayer: camera.previewLayer)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCalibrating ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    )
            }

            if isDone {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("Calibration Complete!")
                        .font(.title2)
                    Text("The turtle is now watching your posture...")
                        .foregroundColor(.secondary)
                    Button("Start") {
                        PostureService.shared.start()
                        NSApp.keyWindow?.close()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if isCalibrating {
                VStack(spacing: 8) {
                    Text("Hold your good posture!")
                        .font(.title3)
                    Text("\(countdown)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    ProgressView(value: Double(5 - countdown), total: 5)
                        .padding(.horizontal, 40)
                }
            } else {
                VStack(spacing: 10) {
                    if let fail = failMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(fail)
                                .font(.callout)
                                .foregroundColor(.orange)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
                    }

                    Text("Sit up straight and look at the camera")
                        .font(.title3)
                    Text("• Keep your back straight\n• Look directly at the screen\n• Relax your shoulders")
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.secondary)

                    if isRecalibration {
                        Button("Recalibrate") {
                            showResetConfirm = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .alert("Reset Calibration?", isPresented: $showResetConfirm) {
                            Button("Cancel", role: .cancel) {}
                            Button("Reset & Recalibrate", role: .destructive) {
                                startCalibration()
                            }
                        } message: {
                            Text("This will replace your current posture baseline.")
                        }
                    } else {
                        Button("Start Calibration") { startCalibration() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    }
                }
            }

            Text("📷 Camera is processed locally. No video is stored.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .onAppear {
            camera.start()
            // 레이어가 뷰에 붙을 시간 확보
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                camera.objectWillChange.send()
            }
        }
        .onDisappear { camera.stop(); timer?.invalidate() }
    }

    private func startCalibration() {
        failMessage = nil
        isCalibrating = true
        countdown = 5
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            countdown -= 1
            if countdown <= 0 {
                t.invalidate()
                captureBaseline()
            }
        }
    }

    private func captureBaseline() {
        guard let face = camera.faceLandmarks else {
            isCalibrating = false
            failMessage = "Face not detected. Make sure your face is visible and well-lit."
            return
        }

        let box = face.boundingBox

        guard box.height > 0.05 else {
            isCalibrating = false
            failMessage = "You seem too far from the camera. Move a bit closer."
            return
        }

        var noseX = 0.5
        if let nose = face.landmarks?.nose {
            let points = nose.normalizedPoints
            let sumX = points.reduce(Float(0)) { $0 + Float($1.x) }
            noseX = Double(sumX / Float(points.count))
        }

        let data = CalibrationData(
            faceY: Double(box.origin.y),
            faceHeight: Double(box.height),
            noseRelativeX: noseX,
            timestamp: Date()
        )
        CalibrationStore.shared.save(data)
        isDone = true
    }
}
