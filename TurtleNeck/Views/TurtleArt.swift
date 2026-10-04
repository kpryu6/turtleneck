import AppKit

/// 앱 아이콘(design/app-icon.svg)과 같은 모양의 거북이 — 목을 곧게 세운 옆모습.
/// 좌표는 아이콘 SVG(1024 기준)를 그대로 쓰고, 그릴 때 대상 영역에 맞게 변환한다.
/// 모든 함수는 y가 아래로 증가하는 좌표계(SwiftUI Canvas, flipped NSImage)를 가정한다.
enum TurtleArt {
    struct Palette {
        let shellTop: NSColor
        let shellBottom: NSColor
        let skinTop: NSColor
        let skinBottom: NSColor
        let rim: NSColor
    }

    private static func hex(_ v: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                 green: CGFloat((v >> 8) & 0xFF) / 255,
                 blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }

    static func palette(for level: TurtleLevel) -> Palette {
        switch level {
        case .gentle:  // 앱 아이콘과 같은 민트
            return Palette(shellTop: hex(0xB4FADB), shellBottom: hex(0x2DBE89),
                           skinTop: hex(0x93F1C9), skinBottom: hex(0x3FC995), rim: hex(0x1FA674))
        case .annoyed:
            return Palette(shellTop: hex(0xFFE3A6), shellBottom: hex(0xF59E0B),
                           skinTop: hex(0xFDD892), skinBottom: hex(0xE9A23B), rim: hex(0xD97706))
        case .angry:
            return Palette(shellTop: hex(0xFFB8B2), shellBottom: hex(0xEF4444),
                           skinTop: hex(0xFCA8A8), skinBottom: hex(0xE25555), rim: hex(0xC53030))
        }
    }

    static func palette(for state: PostureState) -> Palette {
        switch state {
        case .good: return palette(for: .gentle)
        case .warning: return palette(for: .annoyed)
        case .bad: return palette(for: .angry)
        }
    }

    /// 아이콘 좌표계에서 거북이가 차지하는 영역
    static let artBounds = CGRect(x: 240, y: 210, width: 540, height: 530)

    // MARK: - Shapes (icon coordinates)

    private static func roundedRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
        CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: r, cornerHeight: r, transform: nil)
    }
    private static func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2), transform: nil)
    }

    private static let legs = [roundedRect(356, 606, 80, 122, 40), roundedRect(572, 606, 80, 122, 40)]
    private static let tail: CGPath = {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 300, y: 606))
        p.addQuadCurve(to: CGPoint(x: 248, y: 660), control: CGPoint(x: 262, y: 622))
        p.addQuadCurve(to: CGPoint(x: 320, y: 636), control: CGPoint(x: 292, y: 658))
        p.closeSubpath()
        return p
    }()
    private static let neck = roundedRect(646, 320, 72, 300, 36)
    private static let head = circle(682, 306, 86)
    private static let eye = circle(716, 290, 14)
    private static let eyeHighlight = circle(721, 285, 4.5)
    private static let shell: CGPath = {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 284, y: 636))
        p.addCurve(to: CGPoint(x: 500, y: 392), control1: CGPoint(x: 284, y: 470), control2: CGPoint(x: 380, y: 392))
        p.addCurve(to: CGPoint(x: 716, y: 636), control1: CGPoint(x: 620, y: 392), control2: CGPoint(x: 716, y: 470))
        p.closeSubpath()
        return p
    }()
    private static let rim = roundedRect(270, 612, 460, 48, 24)
    private static let hexPattern: CGPath = {
        let p = CGMutablePath()
        func poly(_ pts: [(CGFloat, CGFloat)], close: Bool) {
            p.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
            pts.dropFirst().forEach { p.addLine(to: CGPoint(x: $0.0, y: $0.1)) }
            if close { p.closeSubpath() }
        }
        poly([(500, 452), (552, 482), (552, 542), (500, 572), (448, 542), (448, 482)], close: true)
        poly([(552, 482), (604, 452), (656, 482), (656, 542), (604, 572), (552, 542)], close: false)
        poly([(448, 482), (396, 452), (344, 482), (344, 542), (396, 572), (448, 542)], close: false)
        for (x, y1, y2) in [(500.0, 452.0, 392.0), (500, 572, 636), (604, 572, 636), (396, 572, 636)] as [(CGFloat, CGFloat, CGFloat)] {
            p.move(to: CGPoint(x: x, y: y1))
            p.addLine(to: CGPoint(x: x, y: y2))
        }
        return p
    }()
    private static let highlight: CGPath = {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 352, y: 470))
        p.addCurve(to: CGPoint(x: 480, y: 408), control1: CGPoint(x: 380, y: 430), control2: CGPoint(x: 430, y: 410))
        return p
    }()

    // MARK: - Drawing

    /// `rect` 안에 비율을 유지해 가운데 정렬하는 변환
    private static func fit(_ rect: CGRect) -> CGAffineTransform {
        let s = min(rect.width / artBounds.width, rect.height / artBounds.height)
        let dx = rect.minX + (rect.width - artBounds.width * s) / 2 - artBounds.minX * s
        let dy = rect.minY + (rect.height - artBounds.height * s) / 2 - artBounds.minY * s
        return CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: dx, ty: dy)
    }

    private static func fillGradient(_ ctx: CGContext, _ path: CGPath, _ top: NSColor, _ bottom: NSColor) {
        let box = path.boundingBox
        guard let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                 colors: [top.cgColor, bottom.cgColor] as CFArray,
                                 locations: [0, 1]) else { return }
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.drawLinearGradient(g, start: CGPoint(x: box.midX, y: box.minY),
                               end: CGPoint(x: box.midX, y: box.maxY), options: [])
        ctx.restoreGState()
    }

    /// 아이콘과 같은 상세한 거북이 (알림 배너 등 32pt 이상)
    static func draw(in ctx: CGContext, rect: CGRect, palette: Palette) {
        ctx.saveGState()
        ctx.concatenate(fit(rect))

        (legs + [tail, neck, head]).forEach { fillGradient(ctx, $0, palette.skinTop, palette.skinBottom) }
        ctx.setFillColor(NSColor(srgbRed: 0.04, green: 0.11, blue: 0.09, alpha: 1).cgColor)
        ctx.addPath(eye); ctx.fillPath()
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.9).cgColor)
        ctx.addPath(eyeHighlight); ctx.fillPath()

        fillGradient(ctx, shell, palette.shellTop, palette.shellBottom)
        ctx.saveGState()
        ctx.addPath(shell); ctx.clip()
        ctx.setStrokeColor(palette.rim.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(9)
        ctx.setLineJoin(.round)
        ctx.addPath(hexPattern); ctx.strokePath()
        ctx.restoreGState()

        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.35).cgColor)
        ctx.setLineWidth(12)
        ctx.setLineCap(.round)
        ctx.addPath(highlight); ctx.strokePath()

        ctx.setFillColor(palette.rim.cgColor)
        ctx.addPath(rim); ctx.fillPath()
        ctx.restoreGState()
    }

    /// 한 가지 색의 실루엣 (메뉴 막대처럼 작은 크기). 눈은 투명하게 뚫는다.
    static func drawSilhouette(in ctx: CGContext, rect: CGRect, color: NSColor) {
        ctx.saveGState()
        ctx.concatenate(fit(rect))
        ctx.setFillColor(color.cgColor)
        (legs + [tail, neck, head, shell, rim]).forEach { ctx.addPath($0); ctx.fillPath() }
        // 등껍질과 테두리 사이 틈을 살짝 비워 작은 크기에서도 모양이 읽히게
        ctx.setBlendMode(.clear)
        ctx.addPath(circle(716, 290, 22)); ctx.fillPath()
        ctx.setLineWidth(18)
        ctx.move(to: CGPoint(x: 296, y: 604)); ctx.addLine(to: CGPoint(x: 636, y: 604)); ctx.strokePath()
        ctx.restoreGState()
    }
}
