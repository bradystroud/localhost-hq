import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var scanner: PortScanner
    @State private var checkPortInput: String = ""
    @State private var search: String = ""

    private var filteredPorts: [ListeningPort] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return scanner.ports }
        return scanner.ports.filter {
            String($0.port).contains(q)
                || $0.command.lowercased().contains(q)
                || String($0.pid).contains(q)
        }
    }

    private var conflictingPorts: Set<Int> {
        var counts: [Int: Int] = [:]
        for p in scanner.ports { counts[p.port, default: 0] += 1 }
        return Set(counts.filter { $0.value > 1 }.keys)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            searchBar
            Divider()
            portList
            Divider()
            checkPortField
            Divider()
            footer
        }
        .frame(width: 380)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "network")
            Text("localhost-hq").font(.headline)
            Spacer()
            if scanner.isScanning {
                ProgressView().controlSize(.small)
            }
            Button {
                scanner.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter by port, command, or pid", text: $search)
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
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredPorts) { port in
                        PortRow(
                            port: port,
                            scanner: scanner,
                            isConflicting: conflictingPorts.contains(port.port)
                        )
                        Divider()
                    }
                }
            }
            .frame(maxHeight: 360)
        }
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
    @ObservedObject var scanner: PortScanner
    let isConflicting: Bool
    @State private var showKillConfirm = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(port.port)")
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
                }
                Text("\(port.command) · pid \(port.pid)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(String(port.port), forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("Copy port number")
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
        .contentShape(Rectangle())
    }
}
