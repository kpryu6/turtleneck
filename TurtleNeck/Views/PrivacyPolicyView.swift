import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy").font(.title.bold())
                Text("Last updated: April 2026").font(.caption).foregroundColor(.secondary)

                section("Camera Usage",
                    "TurtleNeck uses your Mac's camera solely to detect your posture in real-time. " +
                    "All image processing happens locally on your device using Apple's Vision framework. " +
                    "No camera footage is ever recorded, stored, or transmitted.")

                section("Data Storage",
                    "Your calibration data, settings, and posture statistics are stored locally on your device " +
                    "using UserDefaults. This data never leaves your Mac.")

                section("No Analytics",
                    "TurtleNeck does not collect any analytics, usage data, or personal information. " +
                    "We have no servers and no way to access your data.")

                section("In-App Purchases",
                    "Purchase information is handled entirely by Apple through StoreKit. " +
                    "We do not have access to your payment details.")

                section("Contact",
                    "If you have questions about this privacy policy, contact us at privacy@turtleneck.app")
            }
            .padding(24)
        }
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(body).font(.body).foregroundColor(.secondary)
        }
    }
}
