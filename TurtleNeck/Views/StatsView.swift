import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject private var store = StatsStore.shared
    @ObservedObject private var streak = StreakStore.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            streakSection.padding(.horizontal, 20).padding(.top, 16)

            Picker("", selection: $selectedTab) {
                Text("Today").tag(0)
                Text("Weekly").tag(1)
                Text("Year").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case 0: todaySummary
                    case 1: weeklyContent
                    case 2: YearCalendarView()
                    default: EmptyView()
                    }
                }
                .padding(20)
            }
        }
    }

    private var streakSection: some View {
        HStack(spacing: 16) {
            Text(streak.streakEmoji).font(.system(size: 36))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak.currentStreak) day streak").font(.title2.bold())
                Text("Best: \(streak.bestStreak) days").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.1)))
    }

    private var todaySummary: some View {
        let today = store.todayRecords
        let badCount = today.filter { $0.state == .bad }.count
        let totalBadSeconds = today.filter { $0.state != .good }.reduce(0) { $0 + $1.duration }
        let score = max(0, 100 - Int(totalBadSeconds / 60) * 5)

        return HStack(spacing: 20) {
            StatCard(title: "Score", value: "\(score)", color: score >= 70 ? .green : .red)
            StatCard(title: "Turtle Visits", value: "\(badCount)", color: .orange)
            StatCard(title: "Bad Posture", value: formatDuration(totalBadSeconds), color: .red)
        }
    }

    private var weeklyContent: some View {
        Group {
            if #available(macOS 14.0, *) {
                Chart(store.weeklyData, id: \.date) { item in
                    BarMark(x: .value("Date", item.date, unit: .day), y: .value("Count", item.badCount))
                        .foregroundStyle(.orange)
                }
                .frame(height: 200)
            } else {
                VStack(alignment: .leading) {
                    ForEach(store.weeklyData, id: \.date) { item in
                        HStack {
                            Text(item.date, style: .date)
                            Spacer()
                            Text("\(item.badCount) visits").foregroundColor(.orange)
                        }
                    }
                }
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        if m == 0 { return "0m" }
        return m < 60 ? "\(m)m" : "\(m / 60)h \(m % 60)m"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(width: 100, height: 70)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.1)))
    }
}
