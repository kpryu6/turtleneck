<div align="center">

# 🐢 TurtleNeck

**A sassy turtle that fixes your posture**

Your webcam-powered posture guardian for macOS.
Slouch, and the turtle shows up. Keep slouching, and it gets angry.

[![macOS 13+](https://img.shields.io/badge/macOS-13.0+-black?logo=apple)](https://www.apple.com/macos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-blue?logo=kofi)](https://ko-fi.com/kpryu)

</div>

---

## Install

```bash
brew tap kpryu6/turtleneck
brew install --cask turtleneck
```

Or download the latest `.dmg` from [Releases](https://github.com/kpryu6/TurtleNeck/releases).

## How It Works

1. **Calibrate** — Sit up straight, TurtleNeck saves your good posture as a baseline
2. **Monitor** — Your webcam quietly tracks your head position using Apple Vision
3. **Alert** — Slouch for 5+ seconds and a turtle slides in with a sassy message
4. **Escalate** — Keep slouching and the turtle gets progressively angrier

### Alert Levels

| | Level | Trigger | Example |
|---|-------|---------|---------|
| 🐢 | Gentle | 0–20s | *"Hey buddy, I came out just for you"* |
| 🐢💢 | Annoyed | 20–60s | *"Your spine called. It wants a divorce."* |
| 🐢🔥 | Angry | 60s+ | *"Your posture is a CRIME and I'm the police 🚨"* |

## Features

- **Menu bar app** — Turtle icon changes color based on posture (green/yellow/red)
- **Custom messages** — Write your own sassy alerts
- **Custom characters** — Swap the turtle for a cat, dog, owl, or your own image
- **Posture stats** — Daily score, turtle visit count, weekly trends
- **Year calendar** — GitHub-style contribution graph for your posture
- **Streak tracking** — 🔥 consecutive good posture days
- **Break reminder** — Pomodoro-style work/rest timer
- **Schedule** — Active during work hours only
- **Per-app disable** — Pause when specific apps are running
- **Focus Mode** — Auto-pause during macOS Do Not Disturb
- **8 languages** — EN, 한국어, 日本語, 中文, ES, DE, FR, PT
- **100% private** — All processing local. No video stored or sent. Ever.

## Privacy

TurtleNeck uses Apple's Vision framework to detect face position locally on your Mac. **No camera footage is ever recorded, stored, or transmitted.** There are no servers, no analytics, no tracking.

## Building from Source

```bash
brew install xcodegen
git clone https://github.com/kpryu6/TurtleNeck.git
cd TurtleNeck
xcodegen generate
xcodebuild -project TurtleNeck.xcodeproj -scheme TurtleNeck build
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 5.9 + SwiftUI |
| Posture Detection | Apple Vision (Face Landmarks) |
| Camera | AVFoundation |
| Charts | Swift Charts |
| Menu Bar | AppKit (NSStatusItem) |
| Alerts | NSPanel (custom slide-in) |
| Project | XcodeGen |

## Support

TurtleNeck is **free and open source**. If it helped fix your posture, consider supporting:

<a href="https://ko-fi.com/kpryu"><img src="https://ko-fi.com/img/githubbutton_sm.svg" /></a>

## License

[MIT](LICENSE)

---

<div align="center">
<sub>Your neck will thank you. The turtle won't. 🐢</sub>
</div>
