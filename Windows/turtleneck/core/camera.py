"""Camera capture + MediaPipe Face Mesh detection."""
import sys
import cv2
import mediapipe as mp
import threading
import time
from dataclasses import dataclass
from typing import Optional, Callable

@dataclass
class FaceData:
    """Extracted face position data from a single frame."""
    face_y: float        # nose tip Y (normalized 0-1, 0=top)
    face_height: float   # face bounding box height (normalized)
    nose_x: float        # nose tip X (normalized)
    landmarks: list      # raw landmark list for future use

class CameraService:
    """Captures webcam frames and runs MediaPipe Face Mesh.

    Callbacks are invoked from the capture thread. Anything that touches Qt
    widgets must hop to the GUI thread (e.g. by emitting a pyqtSignal).
    """

    PREVIEW_INTERVAL = 1 / 15  # preview FPS cap — keeps the GUI event queue from flooding

    def __init__(self):
        self._cap: Optional[cv2.VideoCapture] = None
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._face_mesh = mp.solutions.face_mesh.FaceMesh(
            static_image_mode=False,
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5,
        )
        self.on_face_detected: Optional[Callable[[FaceData], None]] = None
        self.on_frame: Optional[Callable] = None  # for camera preview
        self.latest_face: Optional[FaceData] = None
        self.analysis_interval = 1.0  # seconds between Face Mesh runs
        self.last_error: Optional[str] = None

    def start(self) -> bool:
        """Open the webcam and start the capture thread. Returns False if no camera could be opened."""
        if self._running:
            return True
        self._cap = self._open_camera()
        if self._cap is None:
            self.last_error = "Could not open the webcam. Check that it's connected and not used by another app, and that camera access is allowed in Windows Settings → Privacy & security → Camera."
            return False
        self.last_error = None
        self._cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self._cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self._running = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()
        return True

    def stop(self):
        self._running = False
        if self._thread:
            self._thread.join(timeout=2)
            self._thread = None
        if self._cap:
            self._cap.release()
            self._cap = None

    @staticmethod
    def _open_camera() -> Optional[cv2.VideoCapture]:
        # On Windows the default MSMF backend can take 10s+ to open or fail outright
        # on many webcams; DirectShow is much more reliable.
        backends = [cv2.CAP_DSHOW, cv2.CAP_ANY] if sys.platform == "win32" else [cv2.CAP_ANY]
        for backend in backends:
            cap = cv2.VideoCapture(0, backend)
            if cap.isOpened():
                return cap
            cap.release()
        return None

    def _loop(self):
        last_process = 0.0
        last_preview = 0.0
        while self._running and self._cap and self._cap.isOpened():
            # grab() only pulls the frame off the driver; decoding happens in retrieve(),
            # so we skip the decode cost for frames nobody looks at.
            if not self._cap.grab():
                time.sleep(0.05)
                continue

            now = time.time()
            want_preview = self.on_frame is not None and now - last_preview >= self.PREVIEW_INTERVAL
            want_analysis = now - last_process >= self.analysis_interval
            if not (want_preview or want_analysis):
                time.sleep(0.01)
                continue

            ret, frame = self._cap.retrieve()
            if not ret:
                continue

            if want_preview:
                last_preview = now
                self._safe_call(self.on_frame, frame)

            if want_analysis:
                last_process = now
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                results = self._face_mesh.process(rgb)
                if results.multi_face_landmarks:
                    landmarks = results.multi_face_landmarks[0].landmark
                    face_data = self._extract_face_data(landmarks)
                    self.latest_face = face_data
                    self._safe_call(self.on_face_detected, face_data)

    @staticmethod
    def _safe_call(cb: Optional[Callable], arg):
        if cb is None:
            return
        try:
            cb(arg)
        except RuntimeError:
            # The receiving Qt object was deleted (window closed) between checks
            pass

    def _extract_face_data(self, landmarks) -> FaceData:
        # Nose tip = landmark 1
        nose = landmarks[1]

        # Bounding box from all landmarks
        ys = [lm.y for lm in landmarks]
        min_y, max_y = min(ys), max(ys)

        return FaceData(
            face_y=nose.y,
            face_height=max_y - min_y,
            nose_x=nose.x,
            landmarks=[(lm.x, lm.y, lm.z) for lm in landmarks],
        )
