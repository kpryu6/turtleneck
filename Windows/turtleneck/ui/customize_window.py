"""Customize window — character + custom messages."""
from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QLabel, QPushButton,
                              QLineEdit, QComboBox, QListWidget, QGroupBox, QGridLayout)
from PyQt6.QtCore import Qt
from turtleneck.core.messages import MessageProvider, PRESETS, CustomCharacter
from turtleneck.core.i18n import t

class CustomizeWindow(QWidget):
    def __init__(self, messages: MessageProvider):
        super().__init__()
        self.messages = messages
        self.setWindowTitle(t("customize"))
        self.setFixedSize(460, 500)
        self._build_ui()

    def _build_ui(self):
        layout = QVBoxLayout(self)

        # Character selection
        grp = QGroupBox(t("character"))
        grid = QGridLayout(grp)
        self.char_buttons = []
        for i, char in enumerate(PRESETS):
            btn = QPushButton(f"{char.emoji}\n{char.name}")
            btn.setFixedSize(80, 60)
            btn.setCheckable(True)
            btn.setChecked(char.name == self.messages.character.name)
            btn.clicked.connect(lambda checked, c=char: self._select_char(c))
            grid.addWidget(btn, i // 4, i % 4)
            self.char_buttons.append((btn, char))
        layout.addWidget(grp)

        # Custom messages
        grp2 = QGroupBox(t("custom_messages"))
        vl = QVBoxLayout(grp2)

        # Level explanation
        explain = QLabel(
            "😊 Gentle = 0-20s  |  😤 Annoyed = 20-60s  |  🔥 Angry = 60s+"
        )
        explain.setStyleSheet("color: gray; font-size: 11px;")
        vl.addWidget(explain)

        self.msg_list = QListWidget()
        for m in self.messages.custom_messages:
            level_icon = {1: "😊", 2: "😤", 3: "🔥"}.get(m.get("level", 1), "😊")
            self.msg_list.addItem(f"{level_icon} {m['text']}")
        vl.addWidget(self.msg_list)

        # Add message row
        row = QHBoxLayout()
        self.level_combo = QComboBox()
        self.level_combo.addItem("😊 Gentle", 1)
        self.level_combo.addItem("😤 Annoyed", 2)
        self.level_combo.addItem("🔥 Angry", 3)
        row.addWidget(self.level_combo)
        self.msg_input = QLineEdit()
        self.msg_input.setPlaceholderText("Type a message...")
        row.addWidget(self.msg_input)
        add_btn = QPushButton("Add")
        add_btn.clicked.connect(self._add_message)
        row.addWidget(add_btn)
        vl.addLayout(row)

        del_btn = QPushButton("Remove Selected")
        del_btn.clicked.connect(self._remove_message)
        vl.addWidget(del_btn)

        layout.addWidget(grp2)

        # Preview
        self.preview = QLabel()
        self.preview.setStyleSheet("padding: 8px; background: #f5f5f5; border-radius: 6px;")
        self._update_preview()
        layout.addWidget(self.preview)

    def _select_char(self, char: CustomCharacter):
        self.messages.set_character(char)
        for btn, c in self.char_buttons:
            btn.setChecked(c.name == char.name)
        self._update_preview()

    def _add_message(self):
        text = self.msg_input.text().strip()
        if not text:
            return
        level = self.level_combo.currentData()
        self.messages.add_message(text, level)
        icon = {1: "😊", 2: "😤", 3: "🔥"}[level]
        self.msg_list.addItem(f"{icon} {text}")
        self.msg_input.clear()

    def _remove_message(self):
        row = self.msg_list.currentRow()
        if row >= 0:
            self.messages.remove_message(row)
            self.msg_list.takeItem(row)

    def _update_preview(self):
        sample = self.messages.bad_message(1)
        self.preview.setText(f"{self.messages.character.emoji}  {sample}")
