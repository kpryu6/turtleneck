import AVFoundation
import Vision
import Combine

class CameraService: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    private let sessionQueue = DispatchQueue(label: "camera.session")
    private var isConfigured = false

    /// Vision 분석 최소 간격(초). 카메라는 ~30fps로 들어오지만 매 프레임 얼굴 인식을 돌리면
    /// CPU/배터리를 크게 잡아먹으므로 이 간격마다 한 프레임만 분석한다.
    private let analysisInterval: CFTimeInterval
    private var lastAnalysis: CFTimeInterval = 0 // camera.queue 에서만 접근

    @Published var faceLandmarks: VNFaceObservation?

    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    private lazy var faceRequest: VNDetectFaceLandmarksRequest = {
        VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let results = request.results as? [VNFaceObservation],
                  let face = results.first else { return }
            DispatchQueue.main.async { self?.faceLandmarks = face }
        }
    }()

    init(analysisInterval: CFTimeInterval = 1.0) {
        self.analysisInterval = analysisInterval
        super.init()
    }

    func start() {
        _ = previewLayer // 세션 연결 후 레이어 초기화 (메인 스레드)
        // startRunning()은 블로킹 호출이라 메인 스레드에서 부르면 UI가 멈춘다
        sessionQueue.async { [self] in
            guard !session.isRunning else { return }
            if !isConfigured {
                guard configure() else { return }
            }
            session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    /// 입력/출력은 한 번만 붙인다 (pause → resume 때마다 다시 붙이지 않도록)
    private func configure() -> Bool {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return false }

        session.beginConfiguration()
        session.sessionPreset = .medium
        if session.canAddInput(input) { session.addInput(input) }
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        session.commitConfiguration()
        isConfigured = true
        return true
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = CACurrentMediaTime()
        guard now - lastAnalysis >= analysisInterval else { return }
        lastAnalysis = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([faceRequest])
    }
}
