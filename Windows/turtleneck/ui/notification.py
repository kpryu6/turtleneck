"""Cross-platform notification — Windows toast / macOS fallback."""
import sys
import winsound
from turtleneck.core.posture import TurtleLevel
from turtleneck.core.messages import CustomCharacter

def show_turtle_notification(level: TurtleLevel, message: str, character: CustomCharacter):
    """Show a system notification with turtle message."""
    title = f"{character.emoji} TurtleNeck"

    try:
        # Windows 10/11 toast notification
        from plyer import notification
        notification.notify(
            title=title,
            message=message,
            app_name="TurtleNeck",
            timeout=_timeout(level),
        )
    except Exception:
        # Fallback: print to console
        print(f"[{title}] {message}")

    # Beep sound
    try:
        winsound.MessageBeep()
    except Exception:
        pass

def _timeout(level: TurtleLevel) -> int:
    return {TurtleLevel.GENTLE: 10, TurtleLevel.ANNOYED: 12, TurtleLevel.ANGRY: 15}[level]
