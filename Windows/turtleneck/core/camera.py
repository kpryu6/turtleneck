"""Camera capture + MediaPipe Face Mesh detection."""
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
    """Captures webcam frames and runs MediaPipe Face Mesh."""

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

    def start(self):
        if self._running:
            return
        self._cap = cv2.VideoCapture(0)
        if not self._cap.isOpened():
            return
        self._cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self._cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self._running = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def stop(self):
        self._running = False
        if self._thread:
            self._thread.join(timeout=2)
        if self._cap:
            self._cap.release()
            self._cap = None

    def _loop(self):
        last_process = 0
        while self._running and self._cap and self._cap.isOpened():
            ret, frame = self._cap.read()
            if not ret:
                time.sleep(0.01)
                continue

            # Send frame for preview
            if self.on_frame:
                self.on_frame(frame)

            # Process at ~1 FPS for posture detection
            now = time.time()
            if now - last_process < 1.0:
                continue
            last_process = now

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = self._face_mesh.process(rgb)

            if results.multi_face_landmarks:
                landmarks = results.multi_face_landmarks[0].landmark
                face_data = self._extract_face_data(landmarks)
                self.latest_face = face_data
                if self.on_face_detected:
                    self.on_face_detected(face_data)

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
