# 🐢 TurtleNeck for Windows

Python + MediaPipe + PyQt6 version of TurtleNeck for Windows.

## Requirements

- Python 3.10+
- Webcam

## Install & Run

```bash
cd Windows
pip install -r requirements.txt
python main.py
```

## Features

All features from the macOS version:

- 🎯 Real-time posture detection via MediaPipe Face Mesh
- 📈 Escalating alerts (Gentle → Annoyed → Angry)
- 📊 Daily stats, weekly trends, streak tracking
- ⚙️ Sensitivity, cooldown, schedule settings
- 🎨 Custom characters & messages
- ☕ Break reminder (Pomodoro style)
- 🌍 8 languages (EN, KO, JA, ZH, ES, DE, FR, PT)
- 🔒 100% local processing — no video stored

## Project Structure

```
Windows/
├── main.py                          # Entry point
├── requirements.txt
└── turtleneck/
    ├── core/
    │   ├── app.py                   # Main orchestrator
    │   ├── camera.py                # Webcam + MediaPipe Face Mesh
    │   ├── posture.py               # Posture analysis + calibration
    │   ├── settings.py              # Settings persistence
    │   ├── stats.py                 # Statistics + streak
    │   ├── messages.py              # Sassy messages + characters
    │   └── i18n.py                  # 8-language localization
    └── ui/
        ├── notification.py          # Windows toast notifications
        ├── calibration_window.py    # Camera preview + calibration
        ├── settings_window.py       # Settings GUI
        ├── stats_window.py          # Stats dashboard
        ├── customize_window.py      # Character + message editor
        └── onboarding_window.py     # Welcome flow
```

## Data Storage

All data stored in `~/.turtleneck/`:
- `calibration.json` — posture baseline
- `settings.json` — user preferences
- `stats.json` — posture records (30-day retention)
- `streak.json` — consecutive good days
- `messages.json` — custom messages
- `character.json` — selected character
