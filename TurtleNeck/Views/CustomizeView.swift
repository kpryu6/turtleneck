import SwiftUI
import AppKit

struct CustomizeView: View {
    @State private var messages = MessageProvider.shared.customMessages
    @State private var selectedChar = MessageProvider.shared.selectedCharacter
    @State private var newMessage = ""
    @State private var newLevel: TurtleLevel = .gentle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                // MARK: - Character
                Section("Character") {
                    Text("Choose who roasts you")
                        .font(.caption).foregroundColor(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(CustomCharacter.presets) { char in
                            charButton(char)
                        }
                    }

                    Divider()

                    // Custom image character
                    HStack {
                        if let path = selectedChar.imagePath,
                           let img = NSImage(contentsOfFile: path) {
                            Image(nsImage: img)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Button("Use Custom Image...") { pickImage() }
                        if selectedChar.imagePath != nil {
                            Button("Clear") {
                                selectedChar.imagePath = nil
                                MessageProvider.shared.selectedCharacter = selectedChar
                            }
                            .foregroundColor(.red)
                        }
                    }
                }

                // MARK: - Custom Messages
                Section {
                    // 레벨 설명
                    VStack(alignment: .leading, spacing: 6) {
                        levelExplain("😊 Gentle", "First 0–20 sec of bad posture")
                        levelExplain("😤 Annoyed", "Still slouching after 20–60 sec")
                        levelExplain("🔥 Angry", "Won't stop after 60+ sec")
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))

                    ForEach(messages) { msg in
                        HStack {
                            Text(levelDot(msg.level))
                            Text(msg.text).lineLimit(1)
                            Spacer()
                            Button(role: .destructive) {
                                messages.removeAll { $0.id == msg.id }
                                MessageProvider.shared.customMessages = messages
                            } label: {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(alignment: .center) {
                        Picker("Level", selection: $newLevel) {
                            Text("😊 Gentle").tag(TurtleLevel.gentle)
                            Text("😤 Annoyed").tag(TurtleLevel.annoyed)
                            Text("🔥 Angry").tag(TurtleLevel.angry)
                        }
                        .labelsHidden()
                        .frame(width: 120)

                        TextField("Type a message...", text: $newMessage)
                            .textFieldStyle(.roundedBorder)
                            .frame(height: 28)

                        Button("Add") {
                            guard !newMessage.isEmpty else { return }
                            messages.append(CustomMessage(text: newMessage, level: newLevel))
                            MessageProvider.shared.customMessages = messages
                            newMessage = ""
                        }
                        .disabled(newMessage.isEmpty)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text("Custom Messages")
                } footer: {
                    Text("Use {char} for character emoji, {name} for character name in your messages.")
                }

                // MARK: - Preview
                Section("Preview") {
                    let previewText = newMessage.isEmpty
                        ? "Type a message above to preview it here"
                        : MessageProvider.shared.applyCharacter(newMessage)
                    HStack {
                        charPreview
                        Text(previewText)
                            .font(.callout)
                            .foregroundColor(newMessage.isEmpty ? .secondary : .primary)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
                }
            }
            .formStyle(.grouped)
        }
        .padding()
    }

    private func charButton(_ char: CustomCharacter) -> some View {
        Button {
            selectedChar = char
            MessageProvider.shared.selectedCharacter = char
        } label: {
            VStack(spacing: 4) {
                Text(char.emoji).font(.system(size: 32))
                Text(char.name).font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedChar.id == char.id ? Color.blue.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedChar.id == char.id ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var charPreview: some View {
        if let path = selectedChar.imagePath, let img = NSImage(contentsOfFile: path) {
            Image(nsImage: img).resizable().frame(width: 32, height: 32).clipShape(Circle())
        } else {
            Text(selectedChar.emoji).font(.title)
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        // 앱 지원 디렉토리에 복사
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("TurtleNeck", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let dest = appSupport.appendingPathComponent("custom_char.\(url.pathExtension)")
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: url, to: dest)

        selectedChar = CustomCharacter(name: selectedChar.name, emoji: selectedChar.emoji, imagePath: dest.path)
        MessageProvider.shared.selectedCharacter = selectedChar
    }

    private func levelDot(_ level: TurtleLevel) -> String {
        switch level {
        case .gentle: return "😊"
        case .annoyed: return "😤"
        case .angry: return "🔥"
        }
    }

    private func levelExplain(_ label: String, _ desc: String) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.caption.bold()).frame(width: 90, alignment: .leading)
            Text(desc).font(.caption).foregroundColor(.secondary)
        }
    }
}
