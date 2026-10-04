"""Pomodoro-style break reminder (port of macOS BreakReminder)."""
from typing import Callable, Optional
from PyQt6.QtCore import QObject, QTimer


class BreakReminder(QObject):
    """Counts work/rest minutes and calls `on_break_start` / `on_break_end`.

    Runs on the GUI thread (QTimer), so callbacks may touch widgets directly.
    """

    def __init__(self, on_break_start: Callable[[], None], on_break_end: Callable[[], None],
                 tick_ms: int = 60_000):
        super().__init__()
        self.on_break_start = on_break_start
        self.on_break_end = on_break_end
        self.work_min = 50
        self.rest_min = 10
        self.is_break_time = False
        self.minutes_remaining = 0
        self._timer = QTimer(self)
        self._timer.setInterval(tick_ms)
        self._timer.timeout.connect(self._tick)

    @property
    def is_active(self) -> bool:
        return self._timer.isActive()

    def configure(self, enabled: bool, work_min: int, rest_min: int):
        """Apply settings. Restarts the cycle only if something actually changed."""
        changed = (work_min, rest_min) != (self.work_min, self.rest_min)
        self.work_min, self.rest_min = work_min, rest_min
        if not enabled:
            self.stop()
        elif not self.is_active or changed:
            self.start()

    def start(self):
        self.is_break_time = False
        self.minutes_remaining = self.work_min
        self._timer.start()

    def stop(self):
        self._timer.stop()
        self.is_break_time = False

    def status_text(self) -> Optional[str]:
        if not self.is_active:
            return None
        icon = "☕" if self.is_break_time else "💻"
        return f"{icon} {self.minutes_remaining} min"

    def _tick(self):
        self.minutes_remaining -= 1
        if self.minutes_remaining > 0:
            return
        if self.is_break_time:
            self.is_break_time = False
            self.minutes_remaining = self.work_min
            self.on_break_end()
        else:
            self.is_break_time = True
            self.minutes_remaining = self.rest_min
            self.on_break_start()
