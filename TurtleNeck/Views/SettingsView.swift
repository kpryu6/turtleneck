import SwiftUI

struct AppInfo: Identifiable, Hashable {
    let id: String
    let name: String
}

struct SettingsView: View {
    @ObservedObject private var store = SettingsStore.shared
    @ObservedObject private var breakReminder = BreakReminder.shared
    @ObservedObject private var l10n = L10n.shared
    @State private var showPrivacy = false

    var body: some View {
        Form {
            Section(l10n["detection"]) {
                Picker(l10n["sensitivity"], selection: $store.settings.sensitivity) {
                    ForEach(AppSettings.Sensitivity.allCases, id: \.self) { s in
                        Text(s.labelEN).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                Stepper("\(l10n["cooldown"]): \(store.settings.cooldownSeconds)s",
                        value: $store.settings.cooldownSeconds, in: 10...300, step: 10)
            }

            Section {
                Toggle(l10n["active_work_hours"], isOn: $store.settings.scheduleEnabled)
                if store.settings.scheduleEnabled {
                    HStack {
                        DatePicker("Start", selection: scheduleStartBinding, displayedComponents: .hourAndMinute)
                        DatePicker("End", selection: scheduleEndBinding, displayedComponents: .hourAndMinute)
                    }
                }
            } header: { Text(l10n["schedule"]) } footer: { Text(l10n["schedule_desc"]) }

            Section {
                Text(l10n["disable_per_app_desc"]).font(.caption).foregroundColor(.secondary)
                ForEach(store.settings.disabledApps, id: \.self) { bundleId in
                    HStack {
                        Text(appName(for: bundleId))
                        Spacer()
                        Button(l10n["remove"]) {
                            store.settings.disabledApps.removeAll { $0 == bundleId }
                        }.foregroundColor(.red)
                    }
                }
                HStack {
                    Text(l10n["add_app"])
                    Spacer()
                    Menu(l10n["add"]) {
                        ForEach(installedApps(), id: \.id) { app in
                            Button(app.name) {
                                if !store.settings.disabledApps.contains(app.id) {
                                    store.settings.disabledApps.append(app.id)
                                }
                            }
                        }
                    }
                }
            } header: { Text(l10n["disable_per_app"]) }

            Section {
                Toggle(l10n["launch_at_login"], isOn: $store.settings.launchAtLogin)
                    .onChange(of: store.settings.launchAtLogin) { val in LaunchAtLogin.set(val) }
                Toggle(l10n["focus_mode"], isOn: $store.settings.pauseDuringFocus)
            } header: { Text(l10n["general"]) } footer: { Text(l10n["focus_mode_desc"]) }

            Section(l10n["language"]) {
                Picker(l10n["language"], selection: Binding(
                    get: { l10n.lang },
                    set: { l10n.set($0) }
                )) {
                    ForEach(AppLanguage.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }

            Section {
                Toggle(l10n["break_enable"], isOn: Binding(
                    get: { breakReminder.isActive },
                    set: { _ in breakReminder.toggle() }
                ))
                if breakReminder.isActive {
                    HStack {
                        Text(breakReminder.isBreakTime ? "☕ \(l10n["break"])" : "💻 \(l10n["work"])")
                        Spacer()
                        Text("\(breakReminder.minutesRemaining) min").foregroundColor(.secondary)
                    }
                    Stepper("\(l10n["work"]): \(breakReminder.workMinutes) min",
                            value: $breakReminder.workMinutes, in: 20...90, step: 5)
                    Stepper("\(l10n["break"]): \(breakReminder.breakMinutes) min",
                            value: $breakReminder.breakMinutes, in: 5...30, step: 5)
                }
            } header: { Text(l10n["break_reminder"]) } footer: { Text(l10n["break_desc"]) }

            Section(l10n["privacy"]) {
                Label(l10n["camera_local_only"], systemImage: "lock.shield")
                Label(l10n["no_video_stored"], systemImage: "eye.slash")
                Button(l10n["privacy_policy"]) { showPrivacy = true }
            }

            // Ko-fi 후원
            Section {
                VStack(spacing: 10) {
                    Text("☕").font(.system(size: 32))
                    Text(l10n["buy_coffee"])
                        .font(.headline)
                    Text(l10n["support_desc"])
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        NSWorkspace.shared.open(URL(string: "https://ko-fi.com/kpryu")!)
                    } label: {
                        Text("☕ \(l10n["support_kofi"])")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.11, green: 0.6, blue: 0.86)))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            } header: { Text(l10n["support"]) }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: store.settings) { _ in DispatchQueue.main.async { store.save() } }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView().frame(width: 450, height: 500) }
    }

    private func appName(for bundleId: String) -> String {
        if let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return FileManager.default.displayName(atPath: path.path).replacingOccurrences(of: ".app", with: "")
        }
        return bundleId
    }

    private func installedApps() -> [AppInfo] {
        let dirs = ["/Applications", "/Applications/Utilities", NSString("~/Applications").expandingTildeInPath]
        var apps: [AppInfo] = []
        for dir in dirs {
            guard let items = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for item in items where item.hasSuffix(".app") {
                if let bundle = Bundle(path: "\(dir)/\(item)"), let id = bundle.bundleIdentifier,
                   !store.settings.disabledApps.contains(id) {
                    apps.append(AppInfo(id: id, name: item.replacingOccurrences(of: ".app", with: "")))
                }
            }
        }
        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var scheduleStartBinding: Binding<Date> {
        Binding(get: { Calendar.current.date(from: store.settings.scheduleStart) ?? Date() },
                set: { store.settings.scheduleStart = Calendar.current.dateComponents([.hour, .minute], from: $0) })
    }
    private var scheduleEndBinding: Binding<Date> {
        Binding(get: { Calendar.current.date(from: store.settings.scheduleEnd) ?? Date() },
                set: { store.settings.scheduleEnd = Calendar.current.dateComponents([.hour, .minute], from: $0) })
    }
}
