import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var scanner: PortScanner
    @ObservedObject var prober: TitleProber
    @ObservedObject var store: HiddenPatternsStore
    @Environment(\.openSettings) private var openSettings
    @AppStorage("hideNoise") private var hideNoise = true
    @State private var checkPortInput: String = ""
    @State private var search: String = ""

    private var visiblePorts: [ListeningPort] {
        guard hideNoise else { return scanner.ports }
        return scanner.ports.filter { p in
            !store.isNoise(command: p.command) || prober.title(for: p) != nil
        }
    }

    private var filteredPorts: [ListeningPort] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return visiblePorts }
        return visiblePorts.filter { p in
            String(p.port).contains(q)
                || p.command.lowercased().contains(q)
                || String(p.pid).contains(q)
                || (prober.title(for: p)?.lowercased().contains(q) ?? false)
        }
    }

    private var hiddenCount: Int { scanner.ports.count - visiblePorts.count }

    private var conflictingPorts: Set<Int> {
        var counts: [Int: Int] = [:]
        for p in visiblePorts { counts[p.port, default: 0] += 1 }
        return Set(counts.filter { $0.value > 1 }.keys)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            searchBar
            Divider()
            portList
            if hideNoise && hiddenCount > 0 {
                Divider()
                hiddenRow
            }
            Divider()
            checkPortField
            Divider()
            footer
        }
        .frame(width: 420)
        .onAppear { prober.probe(ports: scanner.ports) }
        .onChange(of: scanner.ports) { _, new in
            prober.probe(ports: new)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "network")
            Text("localhost-hq").font(.headline)
            Text("\(visiblePorts.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(4)
            Spacer()
            if scanner.isScanning {
                ProgressView().controlSize(.small)
            }
            Button {
                hideNoise.toggle()
            } label: {
                Image(systemName: hideNoise ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)
            .help(hideNoise ? "Showing dev-ish only — click to show all" : "Showing everything — click to hide noise")
            Button {
                scanner.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh")
            Button {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(",", modifiers: .command)
            .help("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter by port, command, pid, or title", text: $search)
                .textFieldStyle(.plain)
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var portList: some View {
        if filteredPorts.isEmpty {
            Text(scanner.ports.isEmpty ? "Nothing listening on localhost" : "No matches")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredPorts) { port in
                        PortRow(
                            port: port,
                            title: prober.title(for: port),
                            scanner: scanner,
                            isConflicting: conflictingPorts.contains(port.port),
                            onHide: hideNoise ? { store.add(port.command) } : nil
                        )
                        Divider()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: min(CGFloat(filteredPorts.count) * 48 + 2, 400))
        }
    }

    private var hiddenRow: some View {
        Button {
            hideNoise = false
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "eye")
                Text("Show \(hiddenCount) hidden")
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var checkPortField: some View {
        HStack(spacing: 8) {
            Text("Is port")
                .foregroundStyle(.secondary)
            TextField("3000", text: $checkPortInput)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
            if let port = Int(checkPortInput.trimmingCharacters(in: .whitespaces)) {
                if let match = scanner.ports.first(where: { $0.port == port }) {
                    Text("in use by \(match.command)")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .lineLimit(1)
                } else {
                    Text("free")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var footer: some View {
        HStack {
            Text(scanner.lastUpdated == .distantPast
                 ? "Scanning…"
                 : "Updated \(scanner.lastUpdated.formatted(date: .omitted, time: .standard))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("q")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct PortRow: View {
    let port: ListeningPort
    let title: String?
    @ObservedObject var scanner: PortScanner
    let isConflicting: Bool
    let onHide: (() -> Void)?
    @State private var showKillConfirm = false
    @State private var isHovering = false

    private var openURL: URL? {
        URL(string: "http://localhost:\(port.port)/")
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(verbatim: String(port.port))
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                    Text(port.protocolName)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(3)
                    if isConflicting {
                        Text("conflict")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .cornerRadius(3)
                    }
                    if let title, !title.isEmpty {
                        Text(title)
                            .font(.system(.body).weight(.medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(.primary)
                    }
                }
                Text(verbatim: "\(port.command) · pid \(port.pid)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            if title != nil, let url = openURL {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Image(systemName: "safari")
                }
                .buttonStyle(.borderless)
                .help("Open in browser")
            }
            Button {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(String(port.port), forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("Copy port number")
            if let onHide {
                Button {
                    onHide()
                } label: {
                    Image(systemName: "eye.slash")
                }
                .buttonStyle(.borderless)
                .help("Hide \(port.command) from this list")
            }
            Button {
                showKillConfirm = true
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .help("Kill process")
            .confirmationDialog(
                "Kill \(port.command) (pid \(port.pid)) on port \(port.port)?",
                isPresented: $showKillConfirm,
                titleVisibility: .visible
            ) {
                Button("Kill (TERM)") {
                    scanner.kill(pid: port.pid, signal: "TERM")
                    scanner.refresh()
                }
                Button("Force kill (KILL)", role: .destructive) {
                    scanner.kill(pid: port.pid, signal: "KILL")
                    scanner.refresh()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isHovering ? Color.secondary.opacity(0.08) : .clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }
}
