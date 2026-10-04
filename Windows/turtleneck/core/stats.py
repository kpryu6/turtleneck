"""Posture statistics and streak tracking."""
import json
import os
import time
from dataclasses import dataclass, asdict
from datetime import datetime, date, timedelta
from typing import List, Optional

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

    def score_on(self, d: date) -> Optional[int]:
        """Posture score for a day (-5 per bad minute), or None if nothing was recorded."""
        start = datetime.combine(d, datetime.min.time()).timestamp()
        day = [r for r in self.records if start <= r.timestamp < start + 86400]
        if not day:
            return None
        bad_secs = sum(r.duration for r in day if r.state != "good")
        return max(0, 100 - int(bad_secs / 60) * 5)

    def first_day(self) -> Optional[date]:
        return date.fromtimestamp(min(r.timestamp for r in self.records)) if self.records else None

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
    """Consecutive days with a posture score of 70+.

    Past days are settled from recorded scores; today is still in progress and
    is not counted yet. Days without any records (e.g. weekends) neither break
    nor extend the streak.
    """
    _path = os.path.join(os.path.expanduser("~"), ".turtleneck", "streak.json")

    def __init__(self):
        self.current = 0
        self.best = 0
        self._settled_through: Optional[str] = None
        self._last_check: Optional[date] = None
        self._load()

    def settle(self, stats: "StatsStore", today: Optional[date] = None):
        """Cheap to call often: only recomputes when the date has changed."""
        today = today or date.today()
        if self._last_check == today:
            return
        self._last_check = today

        if self._settled_through:
            d = date.fromisoformat(self._settled_through) + timedelta(days=1)
        else:
            d = stats.first_day()
            if d is None:
                return

        changed = False
        while d < today:
            score = stats.score_on(d)
            if score is not None:
                self.current = self.current + 1 if score >= 70 else 0
                self.best = max(self.best, self.current)
            self._settled_through = d.isoformat()
            changed = True
            d += timedelta(days=1)
        if changed:
            self._save()

    @property
    def emoji(self) -> str:
        if self.current >= 30: return "💎"
        if self.current >= 14: return "👑"
        if self.current >= 7: return "⭐"
        if self.current >= 3: return "🔥"
        return "🐢"

    def _save(self):
        os.makedirs(os.path.dirname(self._path), exist_ok=True)
        with open(self._path, "w") as f:
            json.dump({"current": self.current, "best": self.best,
                       "settled_through": self._settled_through}, f)

    def _load(self):
        if os.path.exists(self._path):
            try:
                with open(self._path) as f:
                    data = json.load(f)
                self.current = data.get("current", 0)
                self.best = data.get("best", 0)
                self._settled_through = data.get("settled_through")
            except Exception:
                pass
