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

        // 디스플레이가 없는 순간(덮개 닫힘 등)엔 띄우지 않는다
        guard let screen = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else { return }
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
        guard let screen = (p.screen ?? NSScreen.main)?.visibleFrame else {
            p.close()
            panel = nil
            return
        }
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

// MARK: - 거북이 (앱 아이콘과 같은 옆모습, 단계별 색)
struct TurtleDrawing: View {
    let level: TurtleLevel

    var body: some View {
        Canvas { context, size in
            context.withCGContext { cg in
                TurtleArt.draw(in: cg, rect: CGRect(origin: .zero, size: size),
                               palette: TurtleArt.palette(for: level))
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
        } else if char.name == CustomCharacter.turtle.name {
            TurtleDrawing(level: level)
        } else {
            Text(char.emoji).font(.system(size: 34)).frame(width: 50, height: 55)
        }
    }
}
