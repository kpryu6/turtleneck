"""Posture statistics and streak tracking."""
import json
import os
import time
from dataclasses import dataclass, asdict
from datetime import datetime, date, timedelta
from typing import List

@dataclass
class PostureRecord:
    timestamp: float
    state: str  # good / warning / bad
    duration: float

class StatsStore:
    _path = os.path.join(os.path.expanduser("~"), ".turtleneck", "stats.json")

    def __init__(self):
        self.records: List[PostureRecord] = []
        self._load()

    def record(self, state: str, duration: float):
        self.records.append(PostureRecord(time.time(), state, duration))
        self._prune_and_save()

    def today_records(self) -> List[PostureRecord]:
        today_start = datetime.combine(date.today(), datetime.min.time()).timestamp()
        return [r for r in self.records if r.timestamp >= today_start]

    def today_score(self) -> int:
        bad_secs = sum(r.duration for r in self.today_records() if r.state != "good")
        return max(0, 100 - int(bad_secs / 60) * 5)

    def today_turtle_count(self) -> int:
        return len([r for r in self.today_records() if r.state in ("bad", "warning")])

    def weekly_data(self) -> list:
        result = []
        for i in range(6, -1, -1):
            d = date.today() - timedelta(days=i)
            start = datetime.combine(d, datetime.min.time()).timestamp()
            end = start + 86400
            day_recs = [r for r in self.records if start <= r.timestamp < end and r.state != "good"]
            result.append({"date": d.isoformat(), "count": len(day_recs)})
        return result

    def _prune_and_save(self):
        cutoff = time.time() - 30 * 86400
        self.records = [r for r in self.records if r.timestamp > cutoff]
        os.makedirs(os.path.dirname(self._path), exist_ok=True)
        with open(self._path, "w") as f:
            json.dump([asdict(r) for r in self.records], f)

    def _load(self):
        if os.path.exists(self._path):
            try:
                with open(self._path) as f:
                    data = json.load(f)
                self.records = [PostureRecord(**r) for r in data]
            except Exception:
                pass

class StreakStore:
    _path = os.path.join(os.path.expanduser("~"), ".turtleneck", "streak.json")

    def __init__(self):
        self.current = 0
        self.best = 0
        self._load()

    def end_of_day(self, score: int):
        today = date.today().isoformat()
        data = self._load_raw()
        last_day = data.get("last_day", "")

        if score >= 70:
            if last_day:
                diff = (date.today() - date.fromisoformat(last_day)).days
                self.current = self.current + 1 if diff == 1 else 1
            else:
                self.current = 1
            data["last_day"] = today
        else:
            self.current = 0

        self.best = max(self.best, self.current)
        data["current"] = self.current
        data["best"] = self.best
        os.makedirs(os.path.dirname(self._path), exist_ok=True)
        with open(self._path, "w") as f:
            json.dump(data, f)

    @property
    def emoji(self) -> str:
        if self.current >= 30: return "💎"
        if self.current >= 14: return "👑"
        if self.current >= 7: return "⭐"
        if self.current >= 3: return "🔥"
        return "🐢"

    def _load(self):
        data = self._load_raw()
        self.current = data.get("current", 0)
        self.best = data.get("best", 0)

    def _load_raw(self) -> dict:
        if os.path.exists(self._path):
            try:
                with open(self._path) as f:
                    return json.load(f)
            except Exception:
                pass
        return {}
