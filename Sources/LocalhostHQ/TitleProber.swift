import Foundation

@MainActor
final class TitleProber: ObservableObject {
    /// Cache keyed by "port-pid". Empty string means "probed, no title".
    @Published private(set) var titles: [String: String] = [:]
    private var inFlight: Set<String> = []

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 1.5
        config.timeoutIntervalForResource = 2.0
        config.httpCookieStorage = nil
        config.urlCache = nil
        config.waitsForConnectivity = false
        config.httpMaximumConnectionsPerHost = 4
        return URLSession(configuration: config)
    }()

    func title(for port: ListeningPort) -> String? {
        let key = cacheKey(port)
        guard let t = titles[key], !t.isEmpty else { return nil }
        return t
    }

    /// Drop cache entries for ports that are no longer listening, then probe any
    /// newly seen ports that we haven't tried yet.
    func probe(ports: [ListeningPort]) {
        let currentKeys = Set(ports.map(cacheKey))
        for key in titles.keys where !currentKeys.contains(key) {
            titles.removeValue(forKey: key)
        }
        for port in ports {
            let key = cacheKey(port)
            guard titles[key] == nil, !inFlight.contains(key) else { continue }
            inFlight.insert(key)
            Task { [weak self] in
                guard let self else { return }
                let result = await self.fetchTitle(port: port.port) ?? ""
                self.titles[key] = result
                self.inFlight.remove(key)
            }
        }
    }

    private func cacheKey(_ p: ListeningPort) -> String {
        "\(p.port)-\(p.pid)"
    }

    private func fetchTitle(port: Int) async -> String? {
        guard let url = URL(string: "http://localhost:\(port)/") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 1.5)
        req.httpMethod = "GET"
        req.setValue("localhost-hq/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue("text/html,*/*;q=0.8", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: req)
            if let http = response as? HTTPURLResponse,
               let ct = http.value(forHTTPHeaderField: "Content-Type")?.lowercased(),
               !ct.contains("html") && !ct.contains("xml") && !ct.contains("text") {
                return nil
            }
            let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1)
                ?? ""
            return extractTitle(from: html)
        } catch {
            return nil
        }
    }

    private func extractTitle(from html: String) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: #"<title[^>]*>([\s\S]*?)</title>"#,
            options: [.caseInsensitive]
        ) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let r = Range(match.range(at: 1), in: html) else { return nil }

        let raw = String(html[r])
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !raw.isEmpty else { return nil }
        return decodeEntities(raw)
    }

    private func decodeEntities(_ s: String) -> String {
        s.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}
