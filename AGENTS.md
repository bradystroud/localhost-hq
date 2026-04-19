# AGENTS.md

Agent instructions for working on localhost-hq.

## Project

localhost-hq is a macOS menu bar app written in Swift + SwiftUI. It lists processes listening on local TCP ports so the developer can tell which dev server is running where and detect port conflicts.

## Stack

- Swift 5.9+
- SwiftUI with `MenuBarExtra` (macOS 13+)
- Swift Package Manager (no Xcode project file committed; `swift run` works)
- No third-party dependencies
- Dock icon hidden via `NSApp.setActivationPolicy(.accessory)` at launch

## Layout

- `Sources/LocalhostHQ/LocalhostHQApp.swift` — `@main` entry point, wires up `MenuBarExtra`
- `Sources/LocalhostHQ/MenuBarView.swift` — the dropdown UI
- `Sources/LocalhostHQ/PortScanner.swift` — shells out to `lsof` and parses output
- `Sources/LocalhostHQ/Port.swift` — the `ListeningPort` model

## Plans

New plans go in `docs/plans/` with the filename format `YYYY-MM-DD-TOPIC.md`.

AI task notes go in `docs/ai-tasks/` with the same filename format.

## Conventions

- Keep it dependency-free; this is a small tool, not a platform.
- Prefer native SwiftUI components.
- Any shell-out must handle the binary missing and return an empty result rather than crashing.
- Do not require root / sudo — the app must work for the signed-in user only.
