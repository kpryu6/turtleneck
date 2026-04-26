"""Sassy turtle messages + character system."""
import json
import os
import random
from dataclasses import dataclass, asdict, field
from typing import List, Optional

@dataclass
class CustomCharacter:
    name: str
    emoji: str
    image_path: Optional[str] = None

PRESETS = [
    CustomCharacter("Turtle", "🐢"),
    CustomCharacter("Cat", "🐱"),
    CustomCharacter("Dog", "🐶"),
    CustomCharacter("Owl", "🦉"),
    CustomCharacter("Penguin", "🐧"),
    CustomCharacter("Sloth", "🦥"),
    CustomCharacter("SpongeBob", "🧽"),
]

BUILTIN_MESSAGES = {
    1: [  # gentle
        "Hey buddy, I came out just for you {char}",
        "Your neck is slowly creeping forward~",
        "One {name} is enough, don't become the second one",
        "Shoulders back, just a little~",
        "Psst... your posture is slipping",
        "Keep this up and you'll be swimming back to the ocean~ {char}",
    ],
    2: [  # annoyed
        "Again? I JUST told you 💢",
        "Please stop. One {name} per household is ENOUGH",
        "You're gonna regret this when you're old, trust me",
        "How many times do I have to say this... 💢",
        "Go look in a mirror right now. Seriously.",
        "Your spine called. It wants a divorce.",
        "I'm not mad, I'm just... disappointed 💢",
        "Hey, didn't you say you were SpongeBob's friend? {char}",
    ],
    3: [  # angry
        "SIT. UP. RIGHT. NOW. 🔥",
        "I'm actually furious. Not kidding anymore.",
        "You made me come to the CENTER of your screen {char}🔥",
        "Last warning. Fix it or I'm living here permanently.",
        "I came all the way here because of YOU. STRAIGHTEN UP!!!",
        "Your posture is a CRIME and I'm the police 🚨",
        "I will NOT leave until you sit properly. Try me.",
    ],
}

GOOD_MESSAGES = [
    "Look at you! Perfect posture! I'm so proud {char}👍",
    "30 minutes of great posture! You're a legend!",
    "Keep it up! You're doing amazing!",
    "A world where I don't need to show up... beautiful 🥹",
    "Posture KING! Keep slaying today!",
]

class MessageProvider:
    _path = os.path.join(os.path.expanduser("~"), ".turtleneck", "messages.json")
    _char_path = os.path.join(os.path.expanduser("~"), ".turtleneck", "character.json")

    def __init__(self):
        self.custom_messages: List[dict] = []  # {"text": str, "level": int}
        self.character = PRESETS[0]
        self._load()

    def bad_message(self, level: int) -> str:
        msgs = list(BUILTIN_MESSAGES.get(level, []))
        msgs += [m["text"] for m in self.custom_messages if m.get("level") == level]
        raw = random.choice(msgs) if msgs else "Fix your posture~"
        return self._apply_char(raw)

    def good_message(self) -> str:
        return self._apply_char(random.choice(GOOD_MESSAGES))

    def _apply_char(self, text: str) -> str:
        return text.replace("{char}", self.character.emoji).replace("{name}", self.character.name)

    def set_character(self, char: CustomCharacter):
        self.character = char
        os.makedirs(os.path.dirname(self._char_path), exist_ok=True)
        with open(self._char_path, "w") as f:
            json.dump(asdict(char), f)

    def add_message(self, text: str, level: int):
        self.custom_messages.append({"text": text, "level": level})
        self._save_messages()

    def remove_message(self, index: int):
        if 0 <= index < len(self.custom_messages):
            self.custom_messages.pop(index)
            self._save_messages()

    def _save_messages(self):
        os.makedirs(os.path.dirname(self._path), exist_ok=True)
        with open(self._path, "w") as f:
            json.dump(self.custom_messages, f)

    def _load(self):
        if os.path.exists(self._path):
            try:
                with open(self._path) as f:
                    self.custom_messages = json.load(f)
            except Exception:
                pass
        if os.path.exists(self._char_path):
            try:
                with open(self._char_path) as f:
                    d = json.load(f)
                self.character = CustomCharacter(**d)
            except Exception:
                pass
