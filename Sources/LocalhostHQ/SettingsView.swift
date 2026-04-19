import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: HiddenPatternsStore
    @State private var newPattern: String = ""
    @State private var confirmReset: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hidden patterns")
                .font(.title2).bold()

            Text("Ports whose process name contains any of these strings are hidden. Matching is case-insensitive. Any port that actually responds with an HTTP title is shown regardless.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                TextField("add pattern (e.g. syncthing)", text: $newPattern)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addPattern)
                Button("Add") { addPattern() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newPattern.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            patternList

            HStack {
                Text("\(store.patterns.count) pattern\(store.patterns.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset to defaults") {
                    confirmReset = true
                }
                .confirmationDialog(
                    "Reset hidden patterns to the built-in defaults?",
                    isPresented: $confirmReset,
                    titleVisibility: .visible
                ) {
                    Button("Reset", role: .destructive) { store.resetToDefaults() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will replace your current list with \(PortFilter.defaultNoisePatterns.count) built-in patterns.")
                }
            }
        }
        .padding(20)
        .frame(width: 480, height: 520)
    }

    private var patternList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(store.patterns, id: \.self) { pattern in
                    HStack {
                        Text(pattern)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button {
                            store.remove(pattern)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                        .help("Remove pattern")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(6)
    }

    private func addPattern() {
        let input = newPattern
        newPattern = ""
        store.add(input)
    }
}
