"""Calibration window with camera preview."""
import time
import cv2
import numpy as np
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QLabel, QPushButton, QProgressBar
from PyQt6.QtGui import QImage, QPixmap
from PyQt6.QtCore import Qt, QTimer
from turtleneck.core.camera import CameraService
from turtleneck.core.posture import CalibrationData
from turtleneck.core.i18n import t

class CalibrationWindow(QWidget):
    def __init__(self, camera: CameraService, on_done):
        super().__init__()
        self.camera = camera
        self.on_done = on_done
        self.countdown = 0
        self.setWindowTitle(t("calibration"))
        self.setFixedSize(500, 520)
        self._build_ui()
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
        self.camera.on_frame = self._update_frame
        self.camera.start()

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
        self._timer = QTimer()
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
        self.camera.on_frame = None
        self.camera.stop()
        self.info.setText(t("calibration_done"))
        self.btn.setText(t("start"))
        self.btn.setEnabled(True)
        self.btn.clicked.disconnect()
        self.btn.clicked.connect(lambda: self.on_done(data))

    def closeEvent(self, event):
        self.camera.on_frame = None
        super().closeEvent(event)
