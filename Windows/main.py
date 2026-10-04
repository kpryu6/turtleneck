"""TurtleNeck for Windows — main entry point."""
import sys

# Import order matters on Windows: PyQt6 ships its own (older) msvcp140.dll. If Qt
# loads first, MediaPipe's native module binds to that copy and fails with
# "DLL load failed while importing _framework_bindings: A dynamic link library
# (DLL) initialization routine failed". Loading MediaPipe/OpenCV first makes the
# system C++ runtime the one in the process.
import cv2  # noqa: F401
import mediapipe  # noqa: F401
from PyQt6.QtWidgets import QApplication


def self_test() -> int:
    """Smoke test for packaged builds (used in CI, where there is no webcam).

    Verifies that MediaPipe's bundled model files load, a face mesh can run on a
    frame, and the Qt UI pieces can be constructed.
    """
    import numpy as np
    from turtleneck.core.camera import CameraService
    from turtleneck.core.posture import TurtleLevel
    from turtleneck.core.messages import PRESETS
    from turtleneck.ui.notification import TurtleOverlay

    _app = QApplication(sys.argv)
    cam = CameraService()
    cam._face_mesh.process(np.zeros((480, 640, 3), dtype=np.uint8))
    TurtleOverlay().show_alert(TurtleLevel.GENTLE, "self-test", PRESETS[0])
    print("TurtleNeck self-test OK")
    return 0


def main():
    if "--self-test" in sys.argv:
        sys.exit(self_test())

    if sys.platform == "win32":
        # Own taskbar identity instead of being grouped under python.exe
        import ctypes
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID("kpryu6.TurtleNeck")

    from turtleneck.core.app import TurtleNeckApp
    app = QApplication(sys.argv)
    app.setApplicationName("TurtleNeck")
    app.setQuitOnLastWindowClosed(False)
    turtle = TurtleNeckApp()
    turtle.start()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
