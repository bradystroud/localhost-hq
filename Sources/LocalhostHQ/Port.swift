import Foundation

struct ListeningPort: Identifiable, Hashable {
    let port: Int
    let pid: Int32
    let command: String
    let protocolName: String

    var id: String { "\(protocolName)-\(port)-\(pid)" }
}
