"""Bundled image resources (included in the .exe by build.ps1 via --add-data)."""
import os

ICON_PATH = os.path.join(os.path.dirname(__file__), "icon.png")  # app icon, 256x256
