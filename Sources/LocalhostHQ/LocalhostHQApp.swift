import SwiftUI
import AppKit

@main
struct LocalhostHQApp: App {
    @StateObject private var scanner = PortScanner()
    @StateObject private var prober = TitleProber()
    @StateObject private var store = HiddenPatternsStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(scanner: scanner, prober: prober, store: store)
        } label: {
            Label("localhost-hq", systemImage: "network")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
