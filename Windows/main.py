"""TurtleNeck for Windows — main entry point."""
import sys
import traceback


def load_native_libs():
    """Import MediaPipe/OpenCV before anything from PyQt6.

    Import order matters on Windows: PyQt6 ships its own (older) msvcp140.dll. If Qt
    loads first, MediaPipe's native module binds to that copy and fails with
    "DLL load failed while importing _framework_bindings: A dynamic link library
    (DLL) initialization routine failed".
    """
    import cv2  # noqa: F401
    import mediapipe  # noqa: F401


def self_test(log_path: str = "") -> int:
    """Smoke test for packaged builds (used in CI, where there is no webcam).

    Verifies that MediaPipe's native libraries and bundled model files load, a
    face mesh can run on a frame, and the Qt UI pieces can be constructed.
    Errors are written to `log_path` instead of raising: a --windowed build would
    otherwise show an error dialog and hang CI waiting for a click.
    """
    def log(msg: str):
        print(msg)
        if log_path:
            with open(log_path, "a", encoding="utf-8") as f:
                f.write(msg + "\n")

    try:
        load_native_libs()
        import numpy as np
        from PyQt6.QtWidgets import QApplication
        from turtleneck.core.camera import CameraService
        from turtleneck.core.posture import TurtleLevel
        from turtleneck.core.messages import PRESETS
        from turtleneck.ui.notification import TurtleOverlay

        _app = QApplication(sys.argv)
        cam = CameraService()
        cam._face_mesh.process(np.zeros((480, 640, 3), dtype=np.uint8))
        TurtleOverlay().show_alert(TurtleLevel.GENTLE, "self-test", PRESETS[0])
        log("TurtleNeck self-test OK")
        return 0
    except BaseException:
        log("TurtleNeck self-test FAILED\n" + traceback.format_exc())
        return 1


def main():
    if "--self-test" in sys.argv:
        i = sys.argv.index("--self-test")
        log_path = sys.argv[i + 1] if len(sys.argv) > i + 1 else ""
        sys.exit(self_test(log_path))

    load_native_libs()
    from PyQt6.QtWidgets import QApplication

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
