"""Logic and Qt-wiring tests. Run from the Windows/ folder:

    QT_QPA_PLATFORM=offscreen python -m unittest discover -s tests -t .
"""
import os
import sys
import tempfile
import threading
import time
import unittest
from datetime import date, datetime, timedelta

# Stores resolve ~/.turtleneck at import time — point them at a temp home first
_HOME = tempfile.mkdtemp()
os.environ["HOME"] = os.environ["USERPROFILE"] = _HOME
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

import numpy as np
import cv2  # noqa: F401  — must load before PyQt6 on Windows, see main.py
import mediapipe  # noqa: F401
from PyQt6.QtWidgets import QApplication, QLabel

from turtleneck.core.stats import StatsStore, StreakStore, PostureRecord
from turtleneck.core.break_reminder import BreakReminder
from turtleneck.core.camera import FaceData

app = QApplication.instance() or QApplication(sys.argv)


def pump(seconds: float):
    end = time.time() + seconds
    while time.time() < end:
        app.processEvents()
        time.sleep(0.005)


def pump_until(condition, timeout: float = 10.0):
    """Process events until `condition()` is true. CI runners can be slow, so tests
    wait for the state they need instead of a fixed amount of time."""
    end = time.time() + timeout
    while not condition():
        if time.time() > end:
            raise AssertionError("timed out waiting for condition")
        app.processEvents()
        time.sleep(0.005)


def at(d: date, hour: int = 10) -> float:
    return datetime.combine(d, datetime.min.time()).timestamp() + hour * 3600


class StreakTests(unittest.TestCase):
    def setUp(self):
        self.today = date(2026, 10, 12)  # a Monday
        self.stats = StatsStore()
        self.stats.records = []
        self.streak = StreakStore()
        self.streak.current = self.streak.best = 0
        self.streak._settled_through = None

    def day(self, offset: int, good: bool = True):
        d = self.today + timedelta(days=offset)
        # bad = 20 minutes of bad posture -> score 0
        self.stats.records.append(PostureRecord(at(d), "good" if good else "bad", 1800 if good else 1200))

    def test_days_without_records_do_not_break_streak(self):
        for o in (-9, -8, -7, -6, -5, -2, -1):  # weekend (-4, -3) has no data
            self.day(o)
        self.day(0, good=False)  # today is still in progress
        self.streak.settle(self.stats, today=self.today)
        self.assertEqual((self.streak.current, self.streak.best), (7, 7))
        self.assertEqual(self.streak.emoji, "⭐")

    def test_bad_day_resets(self):
        for o, g in ((-5, True), (-4, True), (-3, False), (-2, True), (-1, True)):
            self.day(o, g)
        self.streak.settle(self.stats, today=self.today)
        self.assertEqual((self.streak.current, self.streak.best), (2, 2))

    def test_persisted_and_incremental(self):
        for o in (-3, -2, -1, 0):
            self.day(o)
        self.streak.settle(self.stats, today=self.today)
        self.streak.settle(self.stats, today=self.today)
        self.assertEqual(self.streak.current, 3)
        reloaded = StreakStore()
        reloaded.settle(self.stats, today=self.today)
        self.assertEqual(reloaded.current, 3)
        reloaded.settle(self.stats, today=self.today + timedelta(days=1))
        self.assertEqual(reloaded.current, 4)

    def test_score_on(self):
        d = self.today - timedelta(days=1)
        self.stats.records.append(PostureRecord(at(d), "bad", 180))
        self.assertEqual(self.stats.score_on(d), 85)
        self.assertIsNone(self.stats.score_on(d - timedelta(days=1)))


class BreakReminderTests(unittest.TestCase):
    def test_cycle_and_stop(self):
        # Drive the minute ticks directly: real-time QTimer waits are flaky on CI
        # (Windows timer resolution is ~15 ms and runners can stall).
        events = []
        br = BreakReminder(lambda: events.append("start"), lambda: events.append("end"))
        br.configure(True, 2, 1)  # 2 min work, 1 min rest
        self.assertTrue(br.is_active)
        self.assertEqual(br.status_text(), "💻 2 min")
        for _ in range(5):
            br._tick()
        self.assertEqual(events, ["start", "end", "start"])
        self.assertTrue(br.is_break_time)
        self.assertEqual(br.status_text(), "☕ 1 min")

        br.configure(True, 2, 1)  # unchanged settings keep the current cycle
        self.assertTrue(br.is_break_time)
        br.configure(True, 3, 1)  # changed settings restart with work time
        self.assertFalse(br.is_break_time)
        self.assertEqual(br.minutes_remaining, 3)

        br.configure(False, 3, 1)
        self.assertFalse(br.is_active)
        self.assertIsNone(br.status_text())


class FakeCamera:
    """Pushes frames from a background thread, like the real CameraService."""

    def __init__(self, ok=True):
        self.ok = ok
        self.on_frame = None
        self.on_face_detected = None
        self.latest_face = None
        self.analysis_interval = 1.0
        self.last_error = None
        self.running = False
        self.started = self.stopped = 0

    def start(self):
        self.started += 1
        if not self.ok:
            self.last_error = "no camera"
            return False
        self.running = True

        def loop():
            frame = np.zeros((480, 640, 3), dtype=np.uint8)
            while self.running:
                cb = self.on_frame
                if cb:
                    try:
                        cb(frame)
                    except RuntimeError:
                        pass
                self.latest_face = FaceData(0.5, 0.3, 0.5, [])
                time.sleep(0.001)

        threading.Thread(target=loop, daemon=True).start()
        return True

    def stop(self):
        self.stopped += 1
        self.running = False


class CalibrationWindowTests(unittest.TestCase):
    def setUp(self):
        from turtleneck.ui.calibration_window import CalibrationWindow
        self.Window = CalibrationWindow
        self.off_thread = []
        original = QLabel.setPixmap

        def guarded(label, pixmap):
            if threading.current_thread() is not threading.main_thread():
                self.off_thread.append(1)
            return original(label, pixmap)

        QLabel.setPixmap = guarded
        self.addCleanup(setattr, QLabel, "setPixmap", original)

    def test_frames_reach_widgets_only_on_gui_thread_and_cancel_is_reported(self):
        cam, cancelled = FakeCamera(), []
        w = self.Window(cam, on_done=lambda d: None, on_cancel=lambda: cancelled.append(1))
        w.show()
        pump(0.5)
        self.assertEqual(cam.analysis_interval, 0.2)
        w.close()
        pump(0.1)
        self.assertEqual(self.off_thread, [])
        self.assertEqual(cancelled, [1])
        self.assertIsNone(cam.on_frame)
        self.assertEqual(cam.analysis_interval, 1.0)

    def test_complete_calibration(self):
        cam, done, cancelled = FakeCamera(), [], []
        w = self.Window(cam, on_done=done.append, on_cancel=lambda: cancelled.append(1))
        w.show()
        pump(0.1)
        w._start_countdown()
        w._timer.setInterval(10)
        pump_until(lambda: w._finished or (w.btn.isEnabled() and w.countdown <= 0))
        w.btn.click()
        w.close()
        pump(0.05)
        self.assertEqual(len(done), 1)
        self.assertEqual(cancelled, [])

    def test_camera_error_and_retry(self):
        cam = FakeCamera(ok=False)
        w = self.Window(cam, on_done=lambda d: None)
        self.assertIn("no camera", w.info.text())
        self.assertEqual(w.btn.text(), "Retry")
        cam.ok = True
        w.btn.click()
        pump(0.1)
        self.assertEqual(cam.started, 2)
        self.assertNotEqual(w.btn.text(), "Retry")
        w.close()


class AppWiringTests(unittest.TestCase):
    def finish_calibration(self, tn):
        win = tn._cal_win
        win._start_countdown()
        win._timer.setInterval(10)
        pump_until(lambda: win.btn.isEnabled() and win.countdown <= 0)
        win.btn.click()
        pump(0.1)

    def test_tray_cancel_and_break_wiring(self):
        from turtleneck.core import app as appmod
        alerts = []
        appmod.show_turtle_notification = lambda *a: alerts.append(a)
        appmod.QMessageBox.warning = staticmethod(lambda *a: alerts.append(a))
        appmod.set_launch_at_login = lambda enabled: True

        tn = appmod.TurtleNeckApp()
        tn.calibration.data = None
        tn.camera = FakeCamera()
        tn.start()
        tn._on_onboarding_done()
        pump(0.1)
        self.finish_calibration(tn)
        tray = tn.tray
        self.assertIsNotNone(tray)
        self.assertTrue(tn.camera.running)

        tn._show_calibration_from_menu()
        pump(0.1)
        tn._on_face(FaceData(0.9, 0.6, 0.5, []))  # terrible posture while recalibrating
        tn._cal_win.close()
        pump(0.1)
        self.assertIs(tn.tray, tray, "second tray icon created")
        self.assertTrue(tn.camera.running, "camera not restarted after cancelled recalibration")
        self.assertIsNone(tn.bad_start, "posture evaluated during recalibration")

        tn._show_calibration_from_menu()
        pump(0.1)
        self.finish_calibration(tn)
        self.assertIs(tn.tray, tray)

        tn.settings_store.settings.break_enabled = True
        tn._apply_settings()
        self.assertTrue(tn.break_reminder.is_active)
        tn.camera.stop()


if __name__ == "__main__":
    unittest.main()
