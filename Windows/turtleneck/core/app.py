"""Main app orchestrator — ties camera, posture, tray, and alerts together."""
import time
import threading
import webbrowser
from typing import Optional

from PyQt6.QtWidgets import QSystemTrayIcon, QMenu, QApplication, QMessageBox
from PyQt6.QtGui import QIcon, QPixmap, QPainter, QColor, QAction
from PyQt6.QtCore import QTimer, QObject, pyqtSignal

from turtleneck.core.camera import CameraService, FaceData
from turtleneck.core.posture import (
    PostureAnalyzer, PostureState, TurtleLevel,
    CalibrationStore, CalibrationData,
)
from turtleneck.core.settings import SettingsStore
from turtleneck.core.stats import StatsStore, StreakStore
from turtleneck.core.messages import MessageProvider
from turtleneck.core.i18n import t, set_language
from turtleneck.core.break_reminder import BreakReminder
from turtleneck.core.autostart import set_launch_at_login
from turtleneck.ui.notification import show_turtle_notification
from turtleneck.ui.turtle_art import tray_pixmap
from turtleneck.ui.calibration_window import CalibrationWindow
from turtleneck.ui.settings_window import SettingsWindow
from turtleneck.ui.stats_window import StatsWindow
from turtleneck.ui.customize_window import CustomizeWindow
from turtleneck.ui.onboarding_window import OnboardingWindow


class TurtleNeckApp(QObject):
    face_signal = pyqtSignal(object)  # thread-safe face data signal

    def __init__(self):
        super().__init__()
        self.camera = CameraService()
        self.calibration = CalibrationStore()
        self.settings_store = SettingsStore()
        self.stats = StatsStore()
        self.streak = StreakStore()
        self.messages = MessageProvider()

        self.current_state = PostureState.GOOD
        self.bad_start: Optional[float] = None
        self.last_alert: Optional[float] = None
        self.level = TurtleLevel.GENTLE
        self.good_start: Optional[float] = None
        self.paused = False
        self.tray: Optional[QSystemTrayIcon] = None

        self.break_reminder = BreakReminder(
            on_break_start=lambda: show_turtle_notification(TurtleLevel.ANNOYED, t("break_start"), self.messages.character),
            on_break_end=lambda: show_turtle_notification(TurtleLevel.GENTLE, t("break_end"), self.messages.character),
        )

        set_language(self.settings_store.settings.language)
        self.face_signal.connect(self._on_face)

    def start(self):
        self._apply_settings()
        self.streak.settle(self.stats)
        if not self.calibration.is_calibrated:
            self._show_onboarding()
        else:
            self._setup_tray()
            self._start_camera()

    def _show_onboarding(self):
        self._onboarding = OnboardingWindow(on_done=self._on_onboarding_done)
        self._onboarding.show()

    def _on_onboarding_done(self):
        self._onboarding.close()
        self._show_calibration()

    def _show_calibration(self):
        self._cal_win = CalibrationWindow(
            camera=self.camera,
            on_done=self._on_calibration_done,
            on_cancel=self._on_calibration_cancel,
        )
        self._cal_win.show()

    def _on_calibration_done(self, data: CalibrationData):
        self.calibration.save(data)
        self._cal_win.close()
        self._setup_tray()
        self._start_camera()

    def _on_calibration_cancel(self):
        # Window closed mid-recalibration: keep monitoring with the previous baseline.
        # On first run there is no baseline yet, so there is nothing to monitor.
        if self.calibration.is_calibrated:
            self._setup_tray()
            self._start_camera()
        elif self.tray is None:
            QApplication.quit()

    def _setup_tray(self):
        if self.tray is not None:  # recalibration reuses the existing icon
            return
        self.tray = QSystemTrayIcon()
        self._update_tray_icon(PostureState.GOOD)
        self.tray.setToolTip("TurtleNeck — " + t("good"))

        menu = QMenu()
        self._status_action = menu.addAction(f"● {t('posture')}: {t('good')}")
        self._status_action.setEnabled(False)
        menu.addSeparator()
        menu.addAction(t("calibration"), self._show_calibration_from_menu)
        menu.addAction(t("customize"), self._show_customize)
        menu.addAction(t("stats"), self._show_stats)
        menu.addAction(t("settings"), self._show_settings)
        menu.addSeparator()
        self._pause_action = menu.addAction(t("pause"), self._toggle_pause)
        menu.addSeparator()
        menu.addAction(t("buy_coffee"), lambda: webbrowser.open("https://ko-fi.com/kpryu"))
        menu.addSeparator()
        menu.addAction(t("quit"), self._quit)

        self._break_action = QAction("", menu)
        self._break_action.setEnabled(False)
        menu.insertAction(menu.actions()[1], self._break_action)
        menu.aboutToShow.connect(self._refresh_break_status)

        self._menu = menu  # QSystemTrayIcon does not take ownership of the menu
        self.tray.setContextMenu(menu)
        self.tray.show()

    def _start_camera(self):
        if self.paused:
            return
        self.camera.on_face_detected = lambda face: self.face_signal.emit(face)
        if not self.camera.start():
            QMessageBox.warning(None, "TurtleNeck", self.camera.last_error or "Could not open the webcam.")

    def _refresh_break_status(self):
        text = self.break_reminder.status_text()
        self._break_action.setVisible(text is not None)
        if text:
            self._break_action.setText(f"{t('break_reminder')}: {text}")

    def _apply_settings(self):
        s = self.settings_store.settings
        self.break_reminder.configure(s.break_enabled, s.break_work_min, s.break_rest_min)
        set_launch_at_login(s.launch_at_login)

    def _quit(self):
        self.camera.stop()
        QApplication.quit()

    def _on_face(self, face: FaceData):
        self.streak.settle(self.stats)  # no-op unless the date changed
        if self.paused or not self.calibration.data:
            return
        cal_win = getattr(self, "_cal_win", None)
        if cal_win is not None and cal_win.isVisible():  # don't nag while recalibrating
            return

        s = self.settings_store.settings
        if s.schedule_enabled and not self._in_schedule():
            return

        state = PostureAnalyzer.analyze(face, self.calibration.data, s.threshold)

        if state != self.current_state:
            self.current_state = state
            self._update_tray_icon(state)
            label = {"good": t("good"), "warning": t("warning"), "bad": t("bad")}[state.value]
            self._status_action.setText(f"● {t('posture')}: {label}")
            self.tray.setToolTip(f"TurtleNeck — {label}")

        if state in (PostureState.BAD, PostureState.WARNING):
            self.good_start = None
            self._handle_bad(state)
        else:
            self._handle_good()

    def _handle_bad(self, state: PostureState):
        now = time.time()
        if self.bad_start is None:
            self.bad_start = now

        elapsed = now - self.bad_start
        if elapsed > 60: self.level = TurtleLevel.ANGRY
        elif elapsed > 20: self.level = TurtleLevel.ANNOYED
        else: self.level = TurtleLevel.GENTLE

        cooldown = self.settings_store.settings.cooldown_seconds
        if self.last_alert and (now - self.last_alert) < cooldown:
            return

        if elapsed >= 5:
            self.last_alert = now
            msg = self.messages.bad_message(self.level.value)
            show_turtle_notification(self.level, msg, self.messages.character)
            self.stats.record(state.value, elapsed)

    def _handle_good(self):
        self.bad_start = None
        self.level = TurtleLevel.GENTLE

        now = time.time()
        if self.good_start is None:
            self.good_start = now
        if now - self.good_start >= 1800:
            msg = self.messages.good_message()
            show_turtle_notification(TurtleLevel.GENTLE, msg, self.messages.character)
            self.good_start = now
            self.stats.record("good", 1800)

    def _toggle_pause(self):
        self.paused = not self.paused
        self._pause_action.setText(t("resume") if self.paused else t("pause"))
        if self.paused:
            self.camera.stop()
        else:
            self._start_camera()

    def _in_schedule(self) -> bool:
        s = self.settings_store.settings
        from datetime import datetime
        now = datetime.now()
        now_min = now.hour * 60 + now.minute
        start_min = s.schedule_start_hour * 60 + s.schedule_start_min
        end_min = s.schedule_end_hour * 60 + s.schedule_end_min
        return start_min <= now_min <= end_min

    def _update_tray_icon(self, state: PostureState):
        self.tray.setIcon(QIcon(tray_pixmap(state)))

    def _show_calibration_from_menu(self):
        self.camera.stop()
        self._show_calibration()

    def _show_settings(self):
        self._settings_win = SettingsWindow(self.settings_store, on_saved=self._apply_settings)
        self._settings_win.show()

    def _show_stats(self):
        self.streak.settle(self.stats)
        self._stats_win = StatsWindow(self.stats, self.streak)
        self._stats_win.show()

    def _show_customize(self):
        self._cust_win = CustomizeWindow(self.messages)
        self._cust_win.show()
