"""Calibration window with camera preview."""
import time
import cv2
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QLabel, QPushButton, QProgressBar
from PyQt6.QtGui import QImage, QPixmap
from PyQt6.QtCore import Qt, QTimer, pyqtSignal
from turtleneck.core.camera import CameraService
from turtleneck.core.posture import CalibrationData
from turtleneck.core.i18n import t

class CalibrationWindow(QWidget):
    # Camera frames arrive on the capture thread; Qt widgets may only be touched on
    # the GUI thread, so frames are handed over through a (queued) signal.
    frame_ready = pyqtSignal(object)

    def __init__(self, camera: CameraService, on_done, on_cancel=None):
        super().__init__()
        self.camera = camera
        self.on_done = on_done
        self.on_cancel = on_cancel
        self.countdown = 0
        self._finished = False
        self.setWindowTitle(t("calibration"))
        self.setFixedSize(500, 520)
        self._build_ui()
        self.frame_ready.connect(self._update_frame)
        self._start_preview()

    def _build_ui(self):
        layout = QVBoxLayout(self)
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.title = QLabel(t("calibration"))
        self.title.setStyleSheet("font-size: 24px; font-weight: bold;")
        self.title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(self.title)

        self.preview = QLabel()
        self.preview.setFixedSize(440, 330)
        self.preview.setStyleSheet("border: 2px solid #ccc; border-radius: 8px;")
        self.preview.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(self.preview)

        self.info = QLabel(t("sit_straight"))
        self.info.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.info.setWordWrap(True)
        layout.addWidget(self.info)

        self.progress = QProgressBar()
        self.progress.setRange(0, 5)
        self.progress.setValue(0)
        self.progress.setVisible(False)
        layout.addWidget(self.progress)

        self.btn = QPushButton(t("start_calibration"))
        self.btn.setStyleSheet("padding: 10px; font-size: 16px;")
        self.btn.clicked.connect(self._start_countdown)
        layout.addWidget(self.btn)

        self.privacy = QLabel(t("camera_local"))
        self.privacy.setStyleSheet("color: gray; font-size: 11px;")
        self.privacy.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(self.privacy)

    def _start_preview(self):
        self.camera.on_frame = self.frame_ready.emit
        # Baseline is taken from the latest face at the end of the countdown,
        # so analyze more often than during normal monitoring
        self.camera.analysis_interval = 0.2
        if not self.camera.start():
            self.preview.setText("📷 ❌")
            self.info.setText(self.camera.last_error or "")
            self.info.setStyleSheet("color: #d32f2f;")
            self.btn.setText("Retry")
            self.btn.clicked.disconnect()
            self.btn.clicked.connect(self._retry_camera)

    def _retry_camera(self):
        self.info.setStyleSheet("")
        self.info.setText(t("sit_straight"))
        self.btn.setText(t("start_calibration"))
        self.btn.clicked.disconnect()
        self.btn.clicked.connect(self._start_countdown)
        self.preview.clear()
        self._start_preview()

    def _update_frame(self, frame):
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        h, w, ch = rgb.shape
        img = QImage(rgb.data, w, h, ch * w, QImage.Format.Format_RGB888)
        scaled = QPixmap.fromImage(img).scaled(
            440, 330, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation
        )
        self.preview.setPixmap(scaled)

    def _start_countdown(self):
        self.countdown = 5
        self.btn.setEnabled(False)
        self.progress.setVisible(True)
        self.info.setText(t("hold_posture"))
        self._timer = QTimer(self)
        self._timer.timeout.connect(self._tick)
        self._timer.start(1000)

    def _tick(self):
        self.countdown -= 1
        self.progress.setValue(5 - self.countdown)
        self.info.setText(f"{t('hold_posture')} {self.countdown}")
        if self.countdown <= 0:
            self._timer.stop()
            self._capture()

    def _capture(self):
        face = self.camera.latest_face
        if not face:
            self.info.setText(t("face_not_detected"))
            self.btn.setEnabled(True)
            self.progress.setVisible(False)
            return

        data = CalibrationData(
            face_y=face.face_y,
            face_height=face.face_height,
            nose_x=face.nose_x,
            timestamp=time.time(),
        )
        self._release_camera()
        self.info.setText(t("calibration_done"))
        self.btn.setText(t("start"))
        self.btn.setEnabled(True)
        self.btn.clicked.disconnect()
        self.btn.clicked.connect(lambda: self._finish(data))

    def _finish(self, data: CalibrationData):
        self._finished = True
        self.on_done(data)

    def _release_camera(self):
        self.camera.on_frame = None
        self.camera.analysis_interval = 1.0
        self.camera.stop()

    def closeEvent(self, event):
        self._release_camera()
        if not self._finished and self.on_cancel:
            self.on_cancel()
        super().closeEvent(event)
