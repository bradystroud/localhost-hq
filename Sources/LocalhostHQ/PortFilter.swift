import Foundation

/// Built-in default hide-patterns. The live list lives in `HiddenPatternsStore`
/// (persisted in UserDefaults) and is seeded from this on first launch.
/// Matching is lowercased substring — so "Rider.Backend" and "rider" both hit "rider".
/// A port whose command matches a pattern is still shown if it responds with an HTTP title.
enum PortFilter {
    static let defaultNoisePatterns: [String] = [
        // macOS system daemons
        "rapportd", "controlce", "cupsd", "sharingd", "mdnsresp",
        "loginwindow", "searchd", "trustd", "airplayd",
        "identitys", "remoted", "nsurlsessiond", "cfprefsd",
        "opendirectoryd", "syspolicyd",
        // JetBrains IDEs
        "rider", "idea", "pycharm", "webstorm", "phpstorm",
        "rubymine", "goland", "clion", "datagrip", "fleet",
        "jetbrains", "appcode",
        // Adobe
        "adobe", "creative cloud", "dcp", "coresync",
        "corecontroller", "ccxprocess", "cclibrary",
        // Containers / virt
        "orbstack", "com.docker", "dockerd", "vpnkit", "qemu",
        // Cloud sync / chat / productivity
        "dropbox", "dropboxd", "slack", "teams", "zoom",
        "microsoft", "onedrive", "1password", "keybase",
        "spotify", "discord", "obsidian", "raycast", "notion",
        "whatsapp", "telegram",
        // Browsers (helpers often listen on loopback)
        "chrome", "safari", "firefox", "arc", "brave", "edge",
        // VPN / networking extras
        "tailscaled", "cloudflared"
    ]
}
