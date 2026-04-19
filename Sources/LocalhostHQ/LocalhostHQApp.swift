import SwiftUI
import AppKit

@main
struct LocalhostHQApp: App {
    @StateObject private var scanner = PortScanner()

    init() {
        NSApp.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(scanner: scanner)
        } label: {
            Label("localhost-hq", systemImage: "network")
        }
        .menuBarExtraStyle(.window)
    }
}
