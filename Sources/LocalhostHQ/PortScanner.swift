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
        // -F pcPn  → parseable output with pid/command/protocol/name fields
        // +c 0     → disable command-name truncation
        task.arguments = ["-iTCP", "-sTCP:LISTEN", "-P", "-n", "+c", "0", "-F", "pcPn"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do { try task.run() } catch { return [] }
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var results: [ListeningPort] = []
        var currentPid: Int32 = 0
        var currentCommand = ""
        var currentProto = ""

        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let tag = line.first else { continue }
            let rest = String(line.dropFirst())
            switch tag {
            case "p":
                currentPid = Int32(rest) ?? 0
                currentCommand = ""
                currentProto = ""
            case "c":
                currentCommand = rest
            case "P":
                currentProto = rest
            case "n":
                let cleaned = rest
                    .replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")
                if let portStr = cleaned.split(separator: ":").last,
                   let port = Int(portStr) {
                    results.append(ListeningPort(
                        port: port,
                        pid: currentPid,
                        command: currentCommand,
                        protocolName: currentProto
                    ))
                }
            default:
                break
            }
        }

        var seen = Set<String>()
        let unique = results.filter { seen.insert($0.id).inserted }
        return unique.sorted { lhs, rhs in
            if lhs.port != rhs.port { return lhs.port < rhs.port }
            return lhs.pid < rhs.pid
        }
    }
}
