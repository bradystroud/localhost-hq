import Foundation
import AppKit

@MainActor
final class PortScanner: ObservableObject {
    @Published private(set) var ports: [ListeningPort] = []
    @Published private(set) var lastUpdated: Date = .distantPast
    @Published private(set) var isScanning: Bool = false

    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        guard !isScanning else { return }
        isScanning = true
        Task {
            let parsed = await Task.detached(priority: .userInitiated) {
                Self.runLsof()
            }.value
            self.ports = parsed
            self.lastUpdated = Date()
            self.isScanning = false
        }
    }

    func kill(pid: Int32, signal: String = "TERM") {
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-\(signal)", String(pid)]
        try? task.run()
    }

    nonisolated static func runLsof() -> [ListeningPort] {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-iTCP", "-sTCP:LISTEN", "-P", "-n"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do { try task.run() } catch { return [] }
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var results: [ListeningPort] = []
        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)

        for line in lines.dropFirst() { // skip header row
            let fields = line.split(separator: " ", omittingEmptySubsequences: true)
            guard fields.count >= 9 else { continue }

            let command = String(fields[0])
            let pid = Int32(fields[1]) ?? 0
            let protoName = String(fields[7])
            let name = String(fields[8])

            let cleaned = name
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
            guard let portStr = cleaned.split(separator: ":").last,
                  let port = Int(portStr) else { continue }

            results.append(ListeningPort(
                port: port,
                pid: pid,
                command: command,
                protocolName: protoName
            ))
        }

        var seen = Set<String>()
        let unique = results.filter { seen.insert($0.id).inserted }
        return unique.sorted { lhs, rhs in
            if lhs.port != rhs.port { return lhs.port < rhs.port }
            return lhs.pid < rhs.pid
        }
    }
}
