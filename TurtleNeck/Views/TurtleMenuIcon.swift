import AppKit

class TurtleMenuIcon {
    private weak var button: NSStatusBarButton?
    private var currentState: PostureState = .good

    func attach(to button: NSStatusBarButton) {
        self.button = button
        updateIcon()
    }

    func update(state: PostureState) {
        guard state != currentState else { return }
        currentState = state
        updateIcon()
    }

    private func updateIcon() {
        guard let button else { return }
        button.image = drawTopViewTurtle(state: currentState)
    }

    func stop() {}

    private func drawTopViewTurtle(state: PostureState) -> NSImage {
        let s: CGFloat = 18
        let img = NSImage(size: NSSize(width: s, height: s), flipped: true) { _ in
            let ctx = NSGraphicsContext.current!.cgContext
            let cx = s / 2, cy = s / 2

            let shellColor: NSColor
            let limbColor: NSColor
            switch state {
            case .good:
                shellColor = NSColor(red: 0.45, green: 0.32, blue: 0.22, alpha: 1) // 갈색
                limbColor = NSColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 1) // 초록
            case .warning:
                shellColor = .systemYellow
                limbColor = NSColor(red: 0.6, green: 0.6, blue: 0.2, alpha: 1)
            case .bad:
                shellColor = .systemRed
                limbColor = NSColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1)
            }

            // 다리 4개 (대각선)
            limbColor.setFill()
            let legSize: CGFloat = 3.5
            let legDist: CGFloat = 5.5
            for (dx, dy) in [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)] {
                ctx.fillEllipse(in: CGRect(
                    x: cx + CGFloat(dx) * legDist - legSize/2,
                    y: cy + CGFloat(dy) * legDist - legSize/2,
                    width: legSize, height: legSize))
            }

            // 머리 (위쪽)
            limbColor.setFill()
            ctx.fillEllipse(in: CGRect(x: cx - 2.5, y: cy - 9.5, width: 5, height: 5))

            // 꼬리 (아래쪽)
            let tail = CGMutablePath()
            tail.move(to: CGPoint(x: cx - 1, y: cy + 7))
            tail.addLine(to: CGPoint(x: cx, y: cy + 9.5))
            tail.addLine(to: CGPoint(x: cx + 1, y: cy + 7))
            tail.closeSubpath()
            ctx.addPath(tail)
            ctx.fillPath()

            // 등딱지 원
            shellColor.setFill()
            ctx.fillEllipse(in: CGRect(x: cx - 6.5, y: cy - 6.5, width: 13, height: 13))

            // 육각형 패턴 - 중앙
            shellColor.blended(withFraction: 0.3, of: .black)?.setStroke()
            ctx.setLineWidth(0.6)

            // 중앙 육각형
            let hexR: CGFloat = 3.0
            let hexPath = CGMutablePath()
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3 - .pi / 6
                let px = cx + hexR * cos(angle)
                let py = cy + hexR * sin(angle)
                if i == 0 { hexPath.move(to: CGPoint(x: px, y: py)) }
                else { hexPath.addLine(to: CGPoint(x: px, y: py)) }
            }
            hexPath.closeSubpath()
            ctx.addPath(hexPath)
            ctx.strokePath()

            // 중앙에서 바깥으로 선 6개
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3 - .pi / 6
                let ix = cx + hexR * cos(angle)
                let iy = cy + hexR * sin(angle)
                let ox = cx + 6.0 * cos(angle)
                let oy = cy + 6.0 * sin(angle)
                ctx.move(to: CGPoint(x: ix, y: iy))
                ctx.addLine(to: CGPoint(x: ox, y: oy))
            }
            ctx.strokePath()

            return true
        }
        img.isTemplate = (state == .good)
        return img
    }
}
