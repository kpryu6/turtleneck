"""Launch at login via the per-user Run registry key (no admin rights needed)."""
import os
import sys

_RUN_KEY = r"Software\Microsoft\Windows\CurrentVersion\Run"
_NAME = "TurtleNeck"


def _command() -> str:
    if getattr(sys, "frozen", False):  # PyInstaller build
        return f'"{sys.executable}"'
    # Source install: use pythonw so no console window appears
    pythonw = os.path.join(os.path.dirname(sys.executable), "pythonw.exe")
    exe = pythonw if os.path.exists(pythonw) else sys.executable
    main = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "main.py"))
    return f'"{exe}" "{main}"'


def set_launch_at_login(enabled: bool) -> bool:
    """Returns True on success. No-op (False) on non-Windows platforms."""
    if sys.platform != "win32":
        return False
    import winreg
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, _RUN_KEY, 0, winreg.KEY_SET_VALUE) as key:
            if enabled:
                winreg.SetValueEx(key, _NAME, 0, winreg.REG_SZ, _command())
            else:
                try:
                    winreg.DeleteValue(key, _NAME)
                except FileNotFoundError:
                    pass
        return True
    except OSError:
        return False
