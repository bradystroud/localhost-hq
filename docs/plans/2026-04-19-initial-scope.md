# 2026-04-19 — Initial scope

## Why

Brady runs many local dev servers concurrently and regularly forgets which service is on which port, and hits port conflicts when starting new ones.

## MVP

- Menu bar item listing all TCP LISTEN sockets on localhost
- Show: port, protocol, command name, pid
- Auto-refresh every 3s; manual refresh button
- Filter field (port / command / pid)
- "Is port N free?" check
- Copy port number to clipboard
- Kill process (TERM or KILL with confirmation)
- Conflict badge when multiple processes listen on the same port

## Explicitly out of scope for v1

- UDP listeners
- Remote host listeners (only localhost / all-interfaces)
- Process grouping by project
- Launch-at-login
- Notifications when a port opens/closes
- Icon / app bundle / code signing / notarization

## Ideas for later

- Tag known ports with labels ("3000 = rove-manufacturing-board")
- Persist labels across runs
- Auto-detect project directory from process cwd (via `lsof -a -d cwd`)
- Launch at login via `SMAppService`
- Preferences window for refresh interval
- Keyboard shortcut to open the menu
