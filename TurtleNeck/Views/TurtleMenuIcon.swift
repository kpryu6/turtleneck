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
        button.image = drawTurtle(state: currentState)
    }

    func stop() {}

    /// 앱 아이콘과 같은 옆모습 거북이 실루엣.
    /// 좋은 자세일 땐 템플릿 이미지라 메뉴 막대의 밝기(다크/라이트)에 맞춰 자동으로 색이 바뀌고,
    /// 주의/나쁨일 땐 주황/빨강으로 칠한다.
    private func drawTurtle(state: PostureState) -> NSImage {
        let s: CGFloat = 18
        let img = NSImage(size: NSSize(width: s, height: s), flipped: true) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let color: NSColor = state == .good ? .black : TurtleArt.palette(for: state).rim
            TurtleArt.drawSilhouette(in: ctx, rect: rect.insetBy(dx: 0.5, dy: 0.5), color: color)
            return true
        }
        img.isTemplate = (state == .good)
        return img
    }
}
