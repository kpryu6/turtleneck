import SwiftUI

struct YearCalendarView: View {
    @ObservedObject private var store = StatsStore.shared
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { selectedYear -= 1 } label: { Image(systemName: "chevron.left") }
                Text(String(selectedYear)).font(.title3.bold())
                Button { selectedYear += 1 } label: { Image(systemName: "chevron.right") }
                Spacer()
                legendView
            }

            // 12개월 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 8) {
                ForEach(1...12, id: \.self) { month in
                    monthView(month: month)
                }
            }
        }
        .padding()
    }

    private func monthView(month: Int) -> some View {
        let cal = Calendar.current
        let dateComponents = DateComponents(year: selectedYear, month: month, day: 1)
        guard let firstDay = cal.date(from: dateComponents),
              let range = cal.range(of: .day, in: .month, for: firstDay) else {
            return AnyView(EmptyView())
        }

        let monthName = cal.shortMonthSymbols[month - 1]
        let firstWeekday = cal.component(.weekday, from: firstDay) - 1 // 0-based

        return AnyView(
            VStack(alignment: .leading, spacing: 2) {
                Text(monthName).font(.caption2.bold()).foregroundColor(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(10), spacing: 1), count: 7), spacing: 1) {
                    // 빈 칸
                    ForEach(0..<firstWeekday, id: \.self) { _ in
                        Rectangle().fill(Color.clear).frame(width: 10, height: 10)
                    }
                    // 날짜
                    ForEach(range, id: \.self) { day in
                        let date = cal.date(from: DateComponents(year: selectedYear, month: month, day: day))!
                        let score = scoreFor(date: date)
                        Rectangle()
                            .fill(colorFor(score: score))
                            .frame(width: 10, height: 10)
                            .cornerRadius(2)
                            .help("\(monthName) \(day): \(score >= 0 ? "\(score) pts" : "No data")")
                    }
                }
            }
        )
    }

    private func scoreFor(date: Date) -> Int {
        let cal = Calendar.current
        let dayRecords = store.records.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
        if dayRecords.isEmpty { return -1 } // no data
        let badSeconds = dayRecords.filter { $0.state != .good }.reduce(0) { $0 + $1.duration }
        return max(0, 100 - Int(badSeconds / 60) * 5)
    }

    private func colorFor(score: Int) -> Color {
        if score < 0 { return Color.secondary.opacity(0.1) } // no data
        if score >= 90 { return .green }
        if score >= 70 { return .green.opacity(0.6) }
        if score >= 50 { return .yellow.opacity(0.6) }
        if score >= 30 { return .orange.opacity(0.6) }
        return .red.opacity(0.6)
    }

    private var legendView: some View {
        HStack(spacing: 3) {
            Text("Less").font(.caption2).foregroundColor(.secondary)
            ForEach([0.1, 0.6, 0.6, 0.6, 1.0], id: \.self) { opacity in
                Rectangle()
                    .fill(opacity == 0.1 ? Color.secondary.opacity(0.1) : Color.green.opacity(opacity))
                    .frame(width: 10, height: 10)
                    .cornerRadius(2)
            }
            Text("More").font(.caption2).foregroundColor(.secondary)
        }
    }
}
