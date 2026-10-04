"""The turtle from the app icon (design/app-icon.svg): an upright turtle seen from
the side. Coordinates are the icon's 1024-unit SVG coordinates and are scaled into
whatever rect the caller gives. Mirrors TurtleNeck/Views/TurtleArt.swift on macOS.
"""
from dataclasses import dataclass

from PyQt6.QtCore import QPointF, QRectF, Qt
from PyQt6.QtGui import QBrush, QColor, QLinearGradient, QPainter, QPainterPath, QPen, QPixmap

from turtleneck.core.posture import PostureState, TurtleLevel


@dataclass(frozen=True)
class Palette:
    shell_top: str
    shell_bottom: str
    skin_top: str
    skin_bottom: str
    rim: str


PALETTES = {
    TurtleLevel.GENTLE: Palette("#B4FADB", "#2DBE89", "#93F1C9", "#3FC995", "#1FA674"),  # icon mint
    TurtleLevel.ANNOYED: Palette("#FFE3A6", "#F59E0B", "#FDD892", "#E9A23B", "#D97706"),
    TurtleLevel.ANGRY: Palette("#FFB8B2", "#EF4444", "#FCA8A8", "#E25555", "#C53030"),
}
STATE_LEVEL = {
    PostureState.GOOD: TurtleLevel.GENTLE,
    PostureState.WARNING: TurtleLevel.ANNOYED,
    PostureState.BAD: TurtleLevel.ANGRY,
}

ART_BOUNDS = QRectF(240, 210, 540, 530)  # area the turtle occupies in icon coordinates


def _rounded(x, y, w, h, r) -> QPainterPath:
    p = QPainterPath()
    p.addRoundedRect(QRectF(x, y, w, h), r, r)
    return p


def _circle(cx, cy, r) -> QPainterPath:
    p = QPainterPath()
    p.addEllipse(QPointF(cx, cy), r, r)
    return p


def _tail() -> QPainterPath:
    p = QPainterPath(QPointF(300, 606))
    p.quadTo(QPointF(262, 622), QPointF(248, 660))
    p.quadTo(QPointF(292, 658), QPointF(320, 636))
    p.closeSubpath()
    return p


def _shell() -> QPainterPath:
    p = QPainterPath(QPointF(284, 636))
    p.cubicTo(QPointF(284, 470), QPointF(380, 392), QPointF(500, 392))
    p.cubicTo(QPointF(620, 392), QPointF(716, 470), QPointF(716, 636))
    p.closeSubpath()
    return p


def _hex_pattern() -> QPainterPath:
    p = QPainterPath()

    def poly(pts, close):
        p.moveTo(*pts[0])
        for pt in pts[1:]:
            p.lineTo(*pt)
        if close:
            p.closeSubpath()

    poly([(500, 452), (552, 482), (552, 542), (500, 572), (448, 542), (448, 482)], True)
    poly([(552, 482), (604, 452), (656, 482), (656, 542), (604, 572), (552, 542)], False)
    poly([(448, 482), (396, 452), (344, 482), (344, 542), (396, 572), (448, 542)], False)
    for x, y1, y2 in ((500, 452, 392), (500, 572, 636), (604, 572, 636), (396, 572, 636)):
        p.moveTo(x, y1)
        p.lineTo(x, y2)
    return p


LEGS = [_rounded(356, 606, 80, 122, 40), _rounded(572, 606, 80, 122, 40)]
TAIL = _tail()
NECK = _rounded(646, 320, 72, 300, 36)
HEAD = _circle(682, 306, 86)
SHELL = _shell()
RIM = _rounded(270, 612, 460, 48, 24)
HEX = _hex_pattern()


def _fit(painter: QPainter, rect: QRectF):
    s = min(rect.width() / ART_BOUNDS.width(), rect.height() / ART_BOUNDS.height())
    painter.translate(rect.x() + (rect.width() - ART_BOUNDS.width() * s) / 2,
                      rect.y() + (rect.height() - ART_BOUNDS.height() * s) / 2)
    painter.scale(s, s)
    painter.translate(-ART_BOUNDS.x(), -ART_BOUNDS.y())


def _gradient(path: QPainterPath, top: str, bottom: str) -> QBrush:
    box = path.boundingRect()
    g = QLinearGradient(box.center().x(), box.top(), box.center().x(), box.bottom())
    g.setColorAt(0, QColor(top))
    g.setColorAt(1, QColor(bottom))
    return QBrush(g)


def draw_turtle(painter: QPainter, rect: QRectF, level: TurtleLevel):
    """Detailed turtle with gradients and shell pattern (alert banner, 32px+)."""
    pal = PALETTES[level]
    painter.save()
    painter.setRenderHint(QPainter.RenderHint.Antialiasing)
    _fit(painter, rect)
    painter.setPen(Qt.PenStyle.NoPen)

    for part in (*LEGS, TAIL, NECK, HEAD):
        painter.fillPath(part, _gradient(part, pal.skin_top, pal.skin_bottom))
    painter.fillPath(_circle(716, 290, 14), QColor("#0A1D17"))
    painter.fillPath(_circle(721, 285, 4.5), QColor(255, 255, 255, 230))

    painter.fillPath(SHELL, _gradient(SHELL, pal.shell_top, pal.shell_bottom))
    painter.save()
    painter.setClipPath(SHELL)
    rim = QColor(pal.rim)
    rim.setAlpha(128)
    painter.strokePath(HEX, QPen(rim, 9, Qt.PenStyle.SolidLine, Qt.PenCapStyle.FlatCap, Qt.PenJoinStyle.RoundJoin))
    painter.restore()

    highlight = QPainterPath(QPointF(352, 470))
    highlight.cubicTo(QPointF(380, 430), QPointF(430, 410), QPointF(480, 408))
    painter.strokePath(highlight, QPen(QColor(255, 255, 255, 90), 12, Qt.PenStyle.SolidLine, Qt.PenCapStyle.RoundCap))

    painter.fillPath(RIM, QColor(pal.rim))
    painter.restore()


def draw_silhouette(painter: QPainter, rect: QRectF, color: QColor):
    """Single-color turtle for small sizes (tray icon). The eye is punched out."""
    painter.save()
    painter.setRenderHint(QPainter.RenderHint.Antialiasing)
    _fit(painter, rect)
    for part in (*LEGS, TAIL, NECK, HEAD, SHELL, RIM):
        painter.fillPath(part, color)
    painter.setCompositionMode(QPainter.CompositionMode.CompositionMode_Clear)
    painter.fillPath(_circle(716, 290, 22), QColor(0, 0, 0))
    gap = QPainterPath(QPointF(296, 604))
    gap.lineTo(636, 604)
    painter.strokePath(gap, QPen(QColor(0, 0, 0), 18))
    painter.restore()


def tray_pixmap(state: PostureState, size: int = 32) -> QPixmap:
    """Tray icon: the turtle silhouette in the state's color."""
    px = QPixmap(size, size)
    px.fill(Qt.GlobalColor.transparent)
    p = QPainter(px)
    level = STATE_LEVEL[state]
    color = QColor(PALETTES[level].skin_bottom if state == PostureState.GOOD else PALETTES[level].rim)
    draw_silhouette(p, QRectF(0, 0, size, size), color)
    p.end()
    return px
