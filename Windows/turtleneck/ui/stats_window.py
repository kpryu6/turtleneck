"""Stats window — today / weekly / streak."""
from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QLabel,
                              QTabWidget, QGridLayout, QFrame)
from PyQt6.QtCore import Qt
from turtleneck.core.stats import StatsStore, StreakStore
from turtleneck.core.i18n import t

class StatsWindow(QWidget):
    def __init__(self, stats: StatsStore, streak: StreakStore):
        super().__init__()
        self.stats = stats
        self.streak = streak
        self.setWindowTitle(t("stats"))
        self.setFixedSize(500, 400)
        self._build_ui()

    def _build_ui(self):
        layout = QVBoxLayout(self)

        # Streak
        streak_box = QFrame()
        streak_box.setStyleSheet("background: #FFF3E0; border-radius: 10px; padding: 10px;")
        sl = QHBoxLayout(streak_box)
        sl.addWidget(QLabel(f"<span style='font-size:32px'>{self.streak.emoji}</span>"))
        info = QVBoxLayout()
        info.addWidget(QLabel(f"<b style='font-size:18px'>{self.streak.current} day streak</b>"))
        info.addWidget(QLabel(f"<span style='color:gray'>Best: {self.streak.best} days</span>"))
        sl.addLayout(info)
        sl.addStretch()
        layout.addWidget(streak_box)

        # Tabs
        tabs = QTabWidget()

        # Today tab
        today_w = QWidget()
        tl = QHBoxLayout(today_w)
        score = self.stats.today_score()
        visits = self.stats.today_turtle_count()
        bad_recs = [r for r in self.stats.today_records() if r.state != "good"]
        bad_min = int(sum(r.duration for r in bad_recs) / 60)

        tl.addWidget(self._card(t("score"), str(score), "#4CAF50" if score >= 70 else "#F44336"))
        tl.addWidget(self._card(t("turtle_visits"), str(visits), "#FF9800"))
        tl.addWidget(self._card(t("bad_posture"), f"{bad_min}m", "#F44336"))
        tabs.addTab(today_w, t("today"))

        # Weekly tab
        weekly_w = QWidget()
        wl = QVBoxLayout(weekly_w)
        for day in self.stats.weekly_data():
            row = QHBoxLayout()
            row.addWidget(QLabel(day["date"]))
            row.addStretch()
            row.addWidget(QLabel(f"<span style='color:#FF9800'>{day['count']} visits</span>"))
            wl.addLayout(row)
        wl.addStretch()
        tabs.addTab(weekly_w, t("weekly"))

        layout.addWidget(tabs)

    def _card(self, title: str, value: str, color: str) -> QFrame:
        card = QFrame()
        card.setFixedSize(130, 80)
        card.setStyleSheet(f"background: {color}22; border-radius: 10px;")
        cl = QVBoxLayout(card)
        cl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        cl.addWidget(QLabel(f"<b style='font-size:20px; color:{color}'>{value}</b>"))
        cl.addWidget(QLabel(f"<span style='color:gray; font-size:11px'>{title}</span>"))
        return card
