"""Posture analysis and calibration."""
import json
import os
import time
from dataclasses import dataclass, asdict
from enum import Enum
from typing import Optional
from turtleneck.core.camera import FaceData

class PostureState(Enum):
    GOOD = "good"
    WARNING = "warning"
    BAD = "bad"

class TurtleLevel(Enum):
    GENTLE = 1
    ANNOYED = 2
    ANGRY = 3

@dataclass
class CalibrationData:
    face_y: float
    face_height: float
    nose_x: float
    timestamp: float

class CalibrationStore:
    """Persists calibration data to JSON."""
    _path = os.path.join(os.path.expanduser("~"), ".turtleneck", "calibration.json")

    def __init__(self):
        self.data: Optional[CalibrationData] = None
        self._load()

    @property
    def is_calibrated(self) -> bool:
        return self.data is not None

    def save(self, data: CalibrationData):
        self.data = data
        os.makedirs(os.path.dirname(self._path), exist_ok=True)
        with open(self._path, "w") as f:
            json.dump(asdict(data), f)

    def _load(self):
        if os.path.exists(self._path):
            try:
                with open(self._path) as f:
                    d = json.load(f)
                self.data = CalibrationData(**d)
            except Exception:
                self.data = None

class PostureAnalyzer:
    """Compares current face data against calibration baseline."""

    @staticmethod
    def analyze(face: FaceData, calibration: CalibrationData, threshold: float) -> PostureState:
        # Face Y drops = head moves forward/down
        y_diff = (face.face_y - calibration.face_y) * 100

        # Face gets bigger = closer to camera = leaning forward
        size_diff = 0.0
        if calibration.face_height > 0:
            size_diff = (face.face_height - calibration.face_height) / calibration.face_height * 100

        score = max(y_diff, 0) + max(size_diff, 0)

        if score > threshold * 1.5:
            return PostureState.BAD
        elif score > threshold:
            return PostureState.WARNING
        return PostureState.GOOD
