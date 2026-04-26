"""Settings window."""
import webbrowser
from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QLabel, QComboBox,
                              QSpinBox, QCheckBox, QPushButton, QGroupBox, QFormLayout)
from PyQt6.QtCore import Qt
from turtleneck.core.settings import SettingsStore
from turtleneck.core.i18n import t, set_language, LANGUAGES

class SettingsWindow(QWidget):
    def __init__(self, store: SettingsStore):
        super().__init__()
        self.store = store
        self.setWindowTitle(t("settings"))
        self.setFixedSize(420, 550)
        self._build_ui()

    def _build_ui(self):
        layout = QVBoxLayout(self)
        s = self.store.settings

        # Detection
        grp = QGroupBox(t("sensitivity"))
        form = QFormLayout(grp)
        self.sens = QComboBox()
        self.sens.addItems(["Strict", "Normal", "Loose"])
        self.sens.setCurrentText(s.sensitivity.capitalize())
        form.addRow(t("sensitivity"), self.sens)
        self.cooldown = QSpinBox()
        self.cooldown.setRange(10, 300)
        self.cooldown.setSingleStep(10)
        self.cooldown.setValue(s.cooldown_seconds)
        form.addRow("Cooldown (s)", self.cooldown)
        layout.addWidget(grp)

        # Schedule
        grp2 = QGroupBox(t("schedule"))
        form2 = QFormLayout(grp2)
        self.sched_on = QCheckBox("Active during work hours only")
        self.sched_on.setChecked(s.schedule_enabled)
        form2.addRow(self.sched_on)
        self.sched_start = QSpinBox()
        self.sched_start.setRange(0, 23)
        self.sched_start.setValue(s.schedule_start_hour)
        self.sched_end = QSpinBox()
        self.sched_end.setRange(0, 23)
        self.sched_end.setValue(s.schedule_end_hour)
        h = QHBoxLayout()
        h.addWidget(QLabel("Start:"))
        h.addWidget(self.sched_start)
        h.addWidget(QLabel("End:"))
        h.addWidget(self.sched_end)
        form2.addRow(h)
        layout.addWidget(grp2)

        # Language
        grp3 = QGroupBox(t("language"))
        form3 = QFormLayout(grp3)
        self.lang = QComboBox()
        for code, name in LANGUAGES.items():
            self.lang.addItem(name, code)
        idx = list(LANGUAGES.keys()).index(s.language) if s.language in LANGUAGES else 0
        self.lang.setCurrentIndex(idx)
        form3.addRow(t("language"), self.lang)
        layout.addWidget(grp3)

        # Break Reminder
        grp4 = QGroupBox(t("break_reminder"))
        form4 = QFormLayout(grp4)
        self.break_on = QCheckBox("Enable (Pomodoro style)")
        self.break_on.setChecked(s.break_enabled)
        form4.addRow(self.break_on)
        self.break_work = QSpinBox()
        self.break_work.setRange(20, 90)
        self.break_work.setSingleStep(5)
        self.break_work.setValue(s.break_work_min)
        self.break_rest = QSpinBox()
        self.break_rest.setRange(5, 30)
        self.break_rest.setSingleStep(5)
        self.break_rest.setValue(s.break_rest_min)
        form4.addRow("Work (min)", self.break_work)
        form4.addRow("Break (min)", self.break_rest)
        layout.addWidget(grp4)

        # Support
        kofi = QPushButton(t("buy_coffee"))
        kofi.setStyleSheet("padding: 10px; background: #1DA1F2; color: white; border-radius: 8px; font-weight: bold;")
        kofi.clicked.connect(lambda: webbrowser.open("https://ko-fi.com/kpryu"))
        layout.addWidget(kofi)

        # Save
        save = QPushButton("Save")
        save.setStyleSheet("padding: 8px; font-weight: bold;")
        save.clicked.connect(self._save)
        layout.addWidget(save)

    def _save(self):
        s = self.store.settings
        s.sensitivity = self.sens.currentText().lower()
        s.cooldown_seconds = self.cooldown.value()
        s.schedule_enabled = self.sched_on.isChecked()
        s.schedule_start_hour = self.sched_start.value()
        s.schedule_end_hour = self.sched_end.value()
        s.language = self.lang.currentData()
        s.break_enabled = self.break_on.isChecked()
        s.break_work_min = self.break_work.value()
        s.break_rest_min = self.break_rest.value()
        set_language(s.language)
        self.store.save()
        self.close()
