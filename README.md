# localhost-hq

A tiny macOS menu bar app that shows what's listening on localhost — so you stop forgetting which app is on which port.

## Features

- Live list of TCP listeners (port, command, pid)
- Auto-refreshes every 3s
- Filter by port / command / pid
- Conflict badge when the same port has multiple listeners
- "Is port N free?" quick check
- Copy port number
- Kill process (TERM or KILL)

## Run

Requires macOS 13+ and Xcode command line tools.

```sh
swift run
```

Or open `Package.swift` in Xcode and hit run.

## How it works

Shells out to `lsof -iTCP -sTCP:LISTEN -P -n` and parses the output. No privileged entitlements needed.

The app sets `NSApplication.activationPolicy = .accessory` at launch so it lives in the menu bar with no dock icon.
