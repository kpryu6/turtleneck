"""Onboarding — 3-page welcome flow."""
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QLabel, QPushButton, QStackedWidget
from PyQt6.QtCore import Qt
from turtleneck.core.i18n import t

class OnboardingWindow(QWidget):
    def __init__(self, on_done):
        super().__init__()
        self.on_done = on_done
        self.setWindowTitle("TurtleNeck")
        self.setFixedSize(480, 380)
        self._build_ui()

    def _build_ui(self):
        layout = QVBoxLayout(self)
        self.stack = QStackedWidget()

        # Page 1: Welcome
        p1 = QWidget()
        l1 = QVBoxLayout(p1)
        l1.setAlignment(Qt.AlignmentFlag.AlignCenter)
        l1.addWidget(self._centered("🐢", 60))
        l1.addWidget(self._centered(t("welcome"), 22, bold=True))
        l1.addWidget(self._centered("Your friendly posture guardian that\nkeeps your neck in check.", 13, color="gray"))
        self.stack.addWidget(p1)

        # Page 2: How it works
        p2 = QWidget()
        l2 = QVBoxLayout(p2)
        l2.setAlignment(Qt.AlignmentFlag.AlignCenter)
        l2.addWidget(self._centered("📷", 40))
        l2.addWidget(self._centered("How It Works", 22, bold=True))
        l2.addWidget(self._centered("1. Calibrate your good posture\n2. TurtleNeck watches via your camera\n3. A turtle pops up when you slouch", 13, color="gray"))
        self.stack.addWidget(p2)

        # Page 3: Privacy
        p3 = QWidget()
        l3 = QVBoxLayout(p3)
        l3.setAlignment(Qt.AlignmentFlag.AlignCenter)
        l3.addWidget(self._centered("🔒", 40))
        l3.addWidget(self._centered("Your Privacy Matters", 22, bold=True))
        l3.addWidget(self._centered("✅ All processing happens locally\n✅ No video is stored or uploaded\n✅ We never see your camera feed", 13, color="gray"))
        self.stack.addWidget(p3)

        layout.addWidget(self.stack)

        # Navigation
        nav = QHBoxLayout()
        self.back_btn = QPushButton(t("back"))
        self.back_btn.clicked.connect(self._prev)
        self.back_btn.setVisible(False)
        nav.addWidget(self.back_btn)
        nav.addStretch()
        self.next_btn = QPushButton(t("next"))
        self.next_btn.setStyleSheet("padding: 8px 20px; font-weight: bold;")
        self.next_btn.clicked.connect(self._next)
        nav.addWidget(self.next_btn)
        layout.addLayout(nav)

    def _next(self):
        idx = self.stack.currentIndex()
        if idx < 2:
            self.stack.setCurrentIndex(idx + 1)
            self.back_btn.setVisible(True)
            if idx + 1 == 2:
                self.next_btn.setText(t("get_started"))
        else:
            self.on_done()

    def _prev(self):
        idx = self.stack.currentIndex()
        if idx > 0:
            self.stack.setCurrentIndex(idx - 1)
            self.next_btn.setText(t("next"))
            if idx - 1 == 0:
                self.back_btn.setVisible(False)

    def _centered(self, text: str, size: int, bold: bool = False, color: str = "") -> QLabel:
        style = f"font-size: {size}px;"
        if bold: style += " font-weight: bold;"
        if color: style += f" color: {color};"
        lbl = QLabel(text)
        lbl.setStyleSheet(style)
        lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        lbl.setWordWrap(True)
        return lbl
