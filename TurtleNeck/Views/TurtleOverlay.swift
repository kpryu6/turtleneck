import SwiftUI
import AppKit

class TurtleOverlay {
    static let shared = TurtleOverlay()
    private var panel: NSPanel?
    private var dismissTask: DispatchWorkItem?

    func show(level: TurtleLevel, message: String) {
        DispatchQueue.main.async { [self] in
            NSSound.beep()
            showPanel(level: level, message: message)
        }
    }

    private func showPanel(level: TurtleLevel, message: String) {
        dismissTask?.cancel()
        panel?.close()
        panel = nil

        let screen = NSScreen.main!.visibleFrame
        let w: CGFloat = 320
        let h: CGFloat = 110
        let x = screen.maxX - w - 16
        let y = screen.maxY - h - 8

        let p = NSPanel(
            contentRect: NSRect(x: x, y: y, width: w, height: h),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered, defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.level = .floating
        p.hasShadow = true
        p.isReleasedWhenClosed = false
        p.hidesOnDeactivate = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = TurtleBannerView(level: level, message: message)
        p.contentView = NSHostingView(rootView: view)

        // 슬라이드 인
        p.setFrame(NSRect(x: screen.maxX, y: y, width: w, height: h), display: false)
        p.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            p.animator().setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
        }

        self.panel = p

        let delay: TimeInterval = level == .angry ? 15 : level == .annoyed ? 12 : 10
        let task = DispatchWorkItem { [weak self] in self?.dismiss() }
        dismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    }

    private func dismiss() {
        guard let p = panel else { return }
        let screen = NSScreen.main!.visibleFrame
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            p.animator().setFrame(
                NSRect(x: screen.maxX, y: p.frame.origin.y, width: p.frame.width, height: p.frame.height),
                display: true
            )
        }, completionHandler: { [weak self] in
            p.close()
            self?.panel = nil
        })
    }
}

// MARK: - 거북이 등딱지 아이콘 (위에서 본 모습)
struct TurtleDrawing: View {
    let level: TurtleLevel

    var shellColor: Color {
        switch level {
        case .gentle: return Color(nsColor: NSColor(red: 0.45, green: 0.32, blue: 0.22, alpha: 1))
        case .annoyed: return .orange
        case .angry: return .red
        }
    }

    var limbColor: Color {
        switch level {
        case .gentle: return Color(nsColor: NSColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 1))
        case .annoyed: return Color(nsColor: NSColor(red: 0.6, green: 0.6, blue: 0.2, alpha: 1))
        case .angry: return Color(nsColor: NSColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1))
        }
    }

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let shellR: CGFloat = 16

            // 다리 4개 (대각선)
            let legSize: CGFloat = 9.0
            let legDist: CGFloat = 14.0
            for (dx, dy) in [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)] as [(CGFloat, CGFloat)] {
                ctx.fill(Path(ellipseIn: CGRect(
                    x: cx + dx * legDist - legSize/2,
                    y: cy + dy * legDist - legSize/2,
                    width: legSize, height: legSize)),
                    with: .color(limbColor))
            }

            // 머리
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 6, y: cy - 26, width: 12, height: 14)),
                     with: .color(limbColor))
            // 눈
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 4, y: cy - 23, width: 3, height: 3)),
                     with: .color(.black.opacity(0.7)))
            ctx.fill(Path(ellipseIn: CGRect(x: cx + 1, y: cy - 23, width: 3, height: 3)),
                     with: .color(.black.opacity(0.7)))

            // 꼬리
            let tail = Path { p in
                p.move(to: CGPoint(x: cx - 2.5, y: cy + 18))
                p.addLine(to: CGPoint(x: cx, y: cy + 25))
                p.addLine(to: CGPoint(x: cx + 2.5, y: cy + 18))
                p.closeSubpath()
            }
            ctx.fill(tail, with: .color(limbColor))

            // 등딱지 원
            ctx.fill(Path(ellipseIn: CGRect(x: cx - shellR, y: cy - shellR, width: shellR * 2, height: shellR * 2)),
                     with: .color(shellColor))

            // 육각형 패턴
            let lineColor = shellColor.opacity(0.4)
            let hexR: CGFloat = 7.0
            // 중앙 육각형
            let hexPath = Path { p in
                for i in 0..<6 {
                    let angle = CGFloat(i) * .pi / 3 - .pi / 6
                    let px = cx + hexR * cos(angle)
                    let py = cy + hexR * sin(angle)
                    if i == 0 { p.move(to: CGPoint(x: px, y: py)) }
                    else { p.addLine(to: CGPoint(x: px, y: py)) }
                }
                p.closeSubpath()
            }
            ctx.stroke(hexPath, with: .color(lineColor), lineWidth: 1.2)

            // 중앙에서 바깥으로 선
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3 - .pi / 6
                let line = Path { p in
                    p.move(to: CGPoint(x: cx + hexR * cos(angle), y: cy + hexR * sin(angle)))
                    p.addLine(to: CGPoint(x: cx + (shellR - 1) * cos(angle), y: cy + (shellR - 1) * sin(angle)))
                }
                ctx.stroke(line, with: .color(lineColor), lineWidth: 1.2)
            }
        }
        .frame(width: 50, height: 55)
    }
}

struct TurtleBannerView: View {
    let level: TurtleLevel
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            bannerIcon

            VStack(alignment: .leading, spacing: 3) {
                Text("TurtleNeck")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .frame(width: 320, height: 110)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
        )
    }

    @ViewBuilder
    private var bannerIcon: some View {
        let char = MessageProvider.shared.selectedCharacter
        if let path = char.imagePath, let img = NSImage(contentsOfFile: path) {
            Image(nsImage: img).resizable().frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            TurtleDrawing(level: level)
        }
    }
}
