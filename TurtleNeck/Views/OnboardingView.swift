import SwiftUI

struct OnboardingView: View {
    @State private var page = 0
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                // Page 1: Welcome
                VStack(spacing: 16) {
                    Text("🐢").font(.system(size: 80))
                    Text("Welcome to TurtleNeck")
                        .font(.title.bold())
                    Text("Your friendly posture guardian that\nkeeps your neck in check.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .tag(0)

                // Page 2: How it works
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    Text("How It Works")
                        .font(.title.bold())
                    VStack(alignment: .leading, spacing: 10) {
                        step("1", "Calibrate your good posture")
                        step("2", "TurtleNeck watches via your camera")
                        step("3", "A turtle pops up when you slouch")
                    }
                    .padding(.horizontal, 40)
                }
                .tag(1)

                // Page 3: Privacy
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("Your Privacy Matters")
                        .font(.title.bold())
                    VStack(alignment: .leading, spacing: 8) {
                        privacyRow("checkmark.shield", "All processing happens locally")
                        privacyRow("xmark.icloud", "No video is stored or uploaded")
                        privacyRow("eye.slash", "We never see your camera feed")
                    }
                    .padding(.horizontal, 40)
                }
                .tag(2)
            }
            .tabViewStyle(.automatic)
            .frame(height: 320)

            // Navigation
            HStack {
                if page > 0 {
                    Button("Back") { withAnimation { page -= 1 } }
                        .buttonStyle(.plain)
                }
                Spacer()

                // Dots
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == page ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                if page < 2 {
                    Button("Next") { withAnimation { page += 1 } }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        UserDefaults.standard.set(true, forKey: "onboardingDone")
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
        .frame(width: 480, height: 420)
    }

    private func step(_ num: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(num)
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue.opacity(0.15)))
            Text(text).font(.body)
        }
    }

    private func privacyRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.green).frame(width: 24)
            Text(text).font(.body)
        }
    }
}
