import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var postureService: PostureService!
    private var popoverWindow: NSWindow?
    private var menuIcon: TurtleMenuIcon!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        postureService = PostureService.shared

        if !UserDefaults.standard.bool(forKey: "onboardingDone") {
            showOnboarding()
        } else if !CalibrationStore.shared.isCalibrated {
            showCalibration()
        } else {
            postureService.start()
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        menuIcon = TurtleMenuIcon()
        if let button = statusItem.button {
            menuIcon.attach(to: button)
        }

        let l = L10n.shared
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "\(l["posture"]): \(l["good"])", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: l["calibration"], action: #selector(showCalibration), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: l["customize"], action: #selector(showCustomize), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: l["stats"], action: #selector(showStats), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: l["settings"], action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: l["pause"], action: #selector(togglePause), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: l["buy_coffee"], action: #selector(openKofi), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: l["quit"], action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        NotificationCenter.default.addObserver(self, selector: #selector(postureStateChanged(_:)),
                                                name: .postureStateChanged, object: nil)
    }

    @objc private func postureStateChanged(_ notification: Notification) {
        guard let state = notification.userInfo?["state"] as? PostureState else { return }
        DispatchQueue.main.async {
            self.menuIcon.update(state: state)
            if let menu = self.statusItem.menu, let firstItem = menu.items.first {
                let color: NSColor = state == .good ? .systemGreen : state == .warning ? .systemYellow : .systemRed
                firstItem.attributedTitle = NSAttributedString(
                    string: "● Posture: \(state.labelEN)",
                    attributes: [.foregroundColor: color]
                )
            }
        }
    }

    @objc func showCalibration() {
        showWindow(title: "Calibration", view: AnyView(CalibrationView()), size: NSSize(width: 500, height: 580))
    }

    private func showOnboarding() {
        let view = OnboardingView {
            DispatchQueue.main.async { self.showCalibration() }
        }
        showWindow(title: "Welcome", view: AnyView(view), size: NSSize(width: 480, height: 420))
    }

    @objc private func showStats() {
        showWindow(title: "Stats", view: AnyView(StatsView()), size: NSSize(width: 600, height: 500))
    }

    @objc private func showCustomize() {
        showWindow(title: "Customize", view: AnyView(CustomizeView()), size: NSSize(width: 480, height: 550))
    }

    @objc private func showSettings() {
        showWindow(title: "Settings", view: AnyView(SettingsView()), size: NSSize(width: 450, height: 500))
    }

    @objc private func togglePause() {
        postureService.togglePause()
        if let menu = statusItem.menu {
            let pauseItem = menu.items.first { $0.action == #selector(togglePause) }
            pauseItem?.title = postureService.isPaused ? "Resume" : "Pause"
        }
    }

    @objc private func quit() {
        menuIcon.stop()
        postureService.stop()
        NSApp.terminate(nil)
    }

    @objc private func openKofi() {
        NSWorkspace.shared.open(URL(string: "https://ko-fi.com/kpryu")!)
    }

    private func showWindow(title: String, view: AnyView, size: NSSize) {
        popoverWindow?.close()
        popoverWindow = nil

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        popoverWindow = window
    }
}
