"""Settings persistence."""
import json
import os
from dataclasses import dataclass, field, asdict

@dataclass
class AppSettings:
    sensitivity: str = "normal"  # strict / normal / loose
    cooldown_seconds: int = 30
    schedule_enabled: bool = False
    schedule_start_hour: int = 9
    schedule_start_min: int = 0
    schedule_end_hour: int = 18
    schedule_end_min: int = 0
    disabled_apps: list = field(default_factory=list)
    launch_at_login: bool = False
    pause_during_focus: bool = False
    language: str = "en"
    break_enabled: bool = False
    break_work_min: int = 50
    break_rest_min: int = 10

    @property
    def threshold(self) -> float:
        return {"strict": 8, "normal": 25, "loose": 40}.get(self.sensitivity, 25)

class SettingsStore:
    _path = os.path.join(os.path.expanduser("~"), ".turtleneck", "settings.json")

    def __init__(self):
        self.settings = AppSettings()
        self._load()

    def save(self):
        os.makedirs(os.path.dirname(self._path), exist_ok=True)
        with open(self._path, "w") as f:
            json.dump(asdict(self.settings), f, indent=2)

    def _load(self):
        if os.path.exists(self._path):
            try:
                with open(self._path) as f:
                    d = json.load(f)
                self.settings = AppSettings(**{k: v for k, v in d.items() if k in AppSettings.__dataclass_fields__})
            except Exception:
                pass
