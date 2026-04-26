"""TurtleNeck for Windows — main entry point."""
import sys
from PyQt6.QtWidgets import QApplication
from turtleneck.core.app import TurtleNeckApp

def main():
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    turtle = TurtleNeckApp()
    turtle.start()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
