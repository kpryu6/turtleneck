cask "turtleneck" do
  version "1.0.0"
  sha256 "c565adba38f580e63dfaa48ffe91e46b72057b53755f66eadec1a82f51bd59e7"

  url "https://github.com/kpryu6/TurtleNeck/releases/download/v#{version}/TurtleNeck-#{version}.dmg"
  name "TurtleNeck"
  desc "Posture guardian that detects slouching via webcam and sends sassy turtle alerts"
  homepage "https://github.com/kpryu6/TurtleNeck"

  depends_on macos: ">= :ventura"

  app "TurtleNeck.app"

  zap trash: [
    "~/Library/Preferences/com.turtleneck.app.plist",
    "~/Library/Application Support/TurtleNeck",
  ]
end
