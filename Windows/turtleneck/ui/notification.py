"""Slide-in turtle alert — a port of the macOS TurtleOverlay.

A frameless, always-on-top card slides in from the right edge of the screen,
stays for a few seconds and slides back out. Unlike Windows toast notifications,
it isn't swallowed by Focus Assist / Do Not Disturb.
"""
import math
import os
from typing import Optional

from PyQt6.QtWidgets import QApplication, QWidget, QLabel, QHBoxLayout, QVBoxLayout, QGraphicsDropShadowEffect
from PyQt6.QtGui import QColor, QPainter, QPainterPath, QPixmap, QPolygonF
from PyQt6.QtCore import Qt, QTimer, QPoint, QPointF, QRectF, QPropertyAnimation, QEasingCurve

from turtleneck.core.posture import TurtleLevel
from turtleneck.core.messages import CustomCharacter

CARD_W, CARD_H = 320, 110
MARGIN = 16      # shadow room around the card
EDGE_GAP = 16    # distance from the screen edge

_SHELL = {
    TurtleLevel.GENTLE: QColor(115, 82, 56),
    TurtleLevel.ANNOYED: QColor(255, 149, 0),
    TurtleLevel.ANGRY: QColor(255, 59, 48),
}
_LIMB = {
    TurtleLevel.GENTLE: QColor(102, 153, 77),
    TurtleLevel.ANNOYED: QColor(153, 153, 51),
    TurtleLevel.ANGRY: QColor(179, 77, 77),
}


class TurtleIcon(QWidget):
    """Top-down turtle, same shape as the macOS TurtleDrawing."""

    def __init__(self, level: TurtleLevel):
        super().__init__()
        self.level = level
        self.setFixedSize(50, 55)

    def paintEvent(self, _):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        p.setPen(Qt.PenStyle.NoPen)
        cx, cy = self.width() / 2, self.height() / 2
        shell, limb = _SHELL[self.level], _LIMB[self.level]

        p.setBrush(limb)
        for dx, dy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
            p.drawEllipse(QPointF(cx + dx * 14, cy + dy * 14), 4.5, 4.5)
        p.drawEllipse(QRectF(cx - 6, cy - 26, 12, 14))  # head
        p.drawPolygon(QPolygonF([QPointF(cx - 2.5, cy + 18), QPointF(cx, cy + 25), QPointF(cx + 2.5, cy + 18)]))

        p.setBrush(QColor(0, 0, 0, 180))
        p.drawEllipse(QRectF(cx - 4, cy - 23, 3, 3))
        p.drawEllipse(QRectF(cx + 1, cy - 23, 3, 3))

        p.setBrush(shell)
        p.drawEllipse(QPointF(cx, cy), 16, 16)

        pen = p.pen()
        line = QColor(shell)
        line.setAlpha(102)
        p.setPen(line)
        pts = [QPointF(cx + 7 * math.cos(i * math.pi / 3 - math.pi / 6),
                       cy + 7 * math.sin(i * math.pi / 3 - math.pi / 6)) for i in range(6)]
        p.drawPolygon(QPolygonF(pts))
        for i, pt in enumerate(pts):
            a = i * math.pi / 3 - math.pi / 6
            p.drawLine(pt, QPointF(cx + 15 * math.cos(a), cy + 15 * math.sin(a)))
        p.setPen(pen)
        p.end()


class _Card(QWidget):
    def paintEvent(self, _):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        path = QPainterPath()
        path.addRoundedRect(QRectF(self.rect()), 16, 16)
        p.fillPath(path, QColor(248, 248, 250, 245))
        p.end()


class TurtleOverlay(QWidget):
    def __init__(self):
        super().__init__(None, Qt.WindowType.FramelessWindowHint | Qt.WindowType.Tool
                         | Qt.WindowType.WindowStaysOnTopHint | Qt.WindowType.WindowDoesNotAcceptFocus)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setAttribute(Qt.WidgetAttribute.WA_ShowWithoutActivating)
        self.setFixedSize(CARD_W + MARGIN * 2, CARD_H + MARGIN * 2)

        self.card = _Card(self)
        self.card.setGeometry(MARGIN, MARGIN, CARD_W, CARD_H)
        shadow = QGraphicsDropShadowEffect(self.card)
        shadow.setBlurRadius(20)
        shadow.setOffset(0, 4)
        shadow.setColor(QColor(0, 0, 0, 60))
        self.card.setGraphicsEffect(shadow)

        row = QHBoxLayout(self.card)
        row.setContentsMargins(12, 12, 12, 12)
        row.setSpacing(10)
        self.icon_slot = QHBoxLayout()
        row.addLayout(self.icon_slot)

        col = QVBoxLayout()
        col.setSpacing(3)
        col.addStretch()
        title = QLabel("TurtleNeck")
        title.setStyleSheet("color: #6e6e73; font-size: 11px; font-weight: 600;")
        col.addWidget(title)
        self.message = QLabel()
        self.message.setWordWrap(True)
        self.message.setStyleSheet("color: #1d1d1f; font-size: 13px; font-weight: 500;")
        col.addWidget(self.message)
        col.addStretch()
        row.addLayout(col, 1)

        self._anim = QPropertyAnimation(self, b"pos", self)
        self._anim.setDuration(300)
        self._dismiss_timer = QTimer(self)
        self._dismiss_timer.setSingleShot(True)
        self._dismiss_timer.timeout.connect(self.dismiss)

    def show_alert(self, level: TurtleLevel, message: str, character: CustomCharacter):
        self._set_icon(level, character)
        self.message.setText(message)

        screen = QApplication.primaryScreen()
        if screen is None:
            return
        area = screen.availableGeometry()
        y = area.top() + EDGE_GAP - MARGIN
        shown = QPoint(area.right() - EDGE_GAP - CARD_W - MARGIN, y)
        hidden = QPoint(area.right() + 1, y)

        self._slide(hidden if not self.isVisible() else self.pos(), shown, QEasingCurve.Type.OutCubic)
        self.show()
        self.raise_()
        QApplication.beep()

        delay = {TurtleLevel.GENTLE: 10, TurtleLevel.ANNOYED: 12, TurtleLevel.ANGRY: 15}[level]
        self._dismiss_timer.start(delay * 1000)

    def dismiss(self):
        if not self.isVisible():
            return
        screen = self.screen() or QApplication.primaryScreen()
        hidden = QPoint(screen.availableGeometry().right() + 1, self.y())
        self._slide(self.pos(), hidden, QEasingCurve.Type.InCubic, on_done=self.hide)

    def mousePressEvent(self, _):
        self._dismiss_timer.stop()
        self.dismiss()

    def _slide(self, start: QPoint, end: QPoint, curve, on_done=None):
        self._anim.stop()
        try:
            self._anim.finished.disconnect()
        except TypeError:
            pass
        if on_done:
            self._anim.finished.connect(on_done)
        self.move(start)
        self._anim.setStartValue(start)
        self._anim.setEndValue(end)
        self._anim.setEasingCurve(curve)
        self._anim.start()

    def _set_icon(self, level: TurtleLevel, character: CustomCharacter):
        while self.icon_slot.count():
            w = self.icon_slot.takeAt(0).widget()
            if w:
                w.deleteLater()

        if character.image_path and os.path.exists(character.image_path):
            lbl = QLabel()
            lbl.setPixmap(QPixmap(character.image_path).scaled(
                50, 50, Qt.AspectRatioMode.KeepAspectRatioByExpanding, Qt.TransformationMode.SmoothTransformation))
            lbl.setFixedSize(50, 50)
            self.icon_slot.addWidget(lbl)
        elif character.name == "Turtle":
            self.icon_slot.addWidget(TurtleIcon(level))
        else:
            lbl = QLabel(character.emoji)
            lbl.setFixedSize(50, 55)
            lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
            lbl.setStyleSheet("font-size: 34px;")
            self.icon_slot.addWidget(lbl)


_overlay: Optional[TurtleOverlay] = None

def show_turtle_notification(level: TurtleLevel, message: str, character: CustomCharacter):
    """Show the slide-in turtle alert. Must be called on the GUI thread."""
    global _overlay
    if _overlay is None:
        _overlay = TurtleOverlay()
    _overlay.show_alert(level, message, character)
