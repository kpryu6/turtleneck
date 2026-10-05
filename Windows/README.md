# 🐢 TurtleNeck for Windows (beta)

The Windows version of TurtleNeck, built with Python, MediaPipe and PyQt6.

## Install

**[Download TurtleNeck-Setup.exe](https://github.com/kpryu6/turtleneck/releases/latest/download/TurtleNeck-Setup.exe)** and run it: Next → Install → Finish. It installs for your user only (no admin rights needed) into `%LOCALAPPDATA%\TurtleNeck`, adds Start menu and desktop shortcuts, and can be uninstalled from **Settings → Apps**.

Or open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/kpryu6/turtleneck/main/install.ps1 | iex
```

- If the latest [Release](https://github.com/kpryu6/turtleneck/releases) has a Windows build, the script downloads and silently runs the same `TurtleNeck-Setup.exe`. You don't need Python.
- If it doesn't, the installer sets up TurtleNeck from source. That needs **Python 3.10–3.12**, because mediapipe doesn't support newer versions yet. Get it from [python.org](https://www.python.org/downloads/).

Both ways install to the same place, so they never leave two copies. TurtleNeck runs in the **system tray**; look for the turtle under **^** next to the clock.

> Windows SmartScreen may warn about the app because it isn't code-signed yet. Click **More info → Run anyway**.

### Run from source

```bash
cd Windows
pip install -r requirements.txt
python main.py
```

## What works

| Feature | Windows |
|---|---|
| Posture detection (MediaPipe Face Mesh) | ✅ |
| Slide-in turtle alerts that escalate (Gentle → Annoyed → Angry) | ✅ |
| Custom characters and messages | ✅ |
| Daily stats, weekly trend, 🔥 streaks | ✅ |
| Break reminder (Pomodoro style) | ✅ |
| Work-hours schedule, sensitivity, cooldown | ✅ |
| Launch at login | ✅ |
| 8 languages | ✅ |
| Year calendar, pause per app, pause during Focus Assist | ❌ macOS only for now |

Everything is processed locally. No video is stored or sent anywhere.

## Troubleshooting

**"Could not open the webcam"**
Close other apps that use the camera (Teams, Zoom, the Camera app), then click **Retry**. Also check **Settings → Privacy & security → Camera** and make sure desktop apps are allowed to use it.

**No turtle appears in the tray**
Windows may hide new tray icons. Click **^** next to the clock and drag the turtle onto the taskbar.

## Tests

```bash
cd Windows
QT_QPA_PLATFORM=offscreen python -m unittest discover -s tests -t .
```

The tests cover streaks, the break timer, and the calibration window. They feed it camera frames from a background thread, the way the real camera does, and check that the UI is only touched from the GUI thread. They also check the tray app's recalibration flow. Tests use a temporary home folder, so your real `~/.turtleneck` data is never touched.

## Building the .exe

On Windows with Python 3.10–3.12:

```powershell
.\Windows\build.ps1
```

It needs [Inno Setup 6](https://jrsoftware.org/isdl.php) (`winget install JRSoftware.InnoSetup`). This builds `Windows\dist\TurtleNeck-Setup.exe` (from `installer.iss`) and `TurtleNeck-Windows-x64.zip` with PyInstaller, and runs a self-test (`TurtleNeck.exe --self-test`). It checks that the bundled MediaPipe models load and the UI starts, so a broken build fails before it ships.

GitHub Actions ([`.github/workflows/windows.yml`](../.github/workflows/windows.yml)) runs the same build on every pull request that touches `Windows/`. When a `v*` tag is pushed, it attaches the zip to that GitHub Release.

## Project structure

```
Windows/
├── main.py                      # Entry point (+ --self-test)
├── build.ps1                    # PyInstaller build + smoke test
├── tests/                       # unittest suite (runs in CI)
├── requirements.txt
└── turtleneck/
    ├── core/
    │   ├── app.py               # Tray app, wires everything together
    │   ├── camera.py            # Webcam + MediaPipe Face Mesh
    │   ├── posture.py           # Posture analysis + calibration
    │   ├── break_reminder.py    # Pomodoro timer
    │   ├── autostart.py         # Launch at login (HKCU Run key)
    │   ├── settings.py / stats.py / messages.py / i18n.py
    └── ui/
        ├── notification.py      # Slide-in turtle alert
        ├── calibration_window.py
        ├── settings_window.py
        ├── stats_window.py
        ├── customize_window.py
        └── onboarding_window.py
```

## Data

All data is stored in `~/.turtleneck/` (`%USERPROFILE%\.turtleneck`):

- `calibration.json`: posture baseline
- `settings.json`: preferences
- `stats.json`: posture records (kept for 30 days)
- `streak.json`: days in a row with good posture
- `messages.json`, `character.json`: custom messages and character
