cask "turtleneck" do
  version "1.0.0"
  sha256 "e9f71cbdc07893c31016584f2d0ae450b5e23b669af0daaaf30aa06f92a95bec"

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
