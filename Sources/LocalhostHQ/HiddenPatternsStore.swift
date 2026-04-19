import Foundation
import Combine

@MainActor
final class HiddenPatternsStore: ObservableObject {
    @Published var patterns: [String] {
        didSet { persist() }
    }

    private static let key = "hiddenPatterns"

    init() {
        if let saved = UserDefaults.standard.array(forKey: Self.key) as? [String], !saved.isEmpty {
            self.patterns = saved
        } else {
            self.patterns = PortFilter.defaultNoisePatterns
        }
    }

    func add(_ raw: String) {
        let normalized = raw.trimmingCharacters(in: .whitespaces).lowercased()
        guard !normalized.isEmpty, !patterns.contains(normalized) else { return }
        patterns.append(normalized)
        patterns.sort()
    }

    func remove(_ pattern: String) {
        patterns.removeAll { $0 == pattern }
    }

    func resetToDefaults() {
        patterns = PortFilter.defaultNoisePatterns
    }

    func isNoise(command: String) -> Bool {
        let lower = command.lowercased()
        return patterns.contains { lower.contains($0) }
    }

    private func persist() {
        UserDefaults.standard.set(patterns, forKey: Self.key)
    }
}
