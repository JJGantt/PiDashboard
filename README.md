# TVDashboard

A tvOS app that displays live data from a Raspberry Pi dashboard server on the Apple TV home screen and in the main app.

## Overview

**TVDashboard** is a tvOS application with two targets:

- **TVDashboard** (main app) — Browse to-do lists, grocery lists, reminders, and recent activity
- **TopShelfExtension** (Top Shelf widget) — Quick glance at dashboard sections from the Apple TV home screen

The app fetches live data from the [tv-dashboard](https://github.com/JJGantt/tv-dashboard) server running on a Raspberry Pi.

## Architecture

### Targets

- `TVDashboard/` — Main tvOS app
  - `Services/PiAPIClient.swift` — Fetches dashboard data (tries local IP first, then Tailscale fallback)
  - `Services/DashboardStore.swift` — Manages state, auto-refresh every 60s, cache fallback
  - `Views/` — Navigation, section cards, item detail pages
- `TopShelfExtension/` — Top Shelf extension (stub — ready to implement)
- `Shared/` — Shared models, cache, constants across both targets

### Configuration

Pi server addresses are stored in a gitignored `Config.xcconfig` file (see `Config.xcconfig.example`). At build time, these are injected into `Info.plist` and read at runtime:

```swift
static var localBaseURL: String {
    let host = Bundle.main.infoDictionary?["PILocalHost"] as? String ?? ""
    return "http://\(host)"
}
```

## Setup

1. Clone and install dependencies (tvOS 17.0+, Xcode 16+)
2. Copy `Config.xcconfig.example` → `Config.xcconfig` and fill in your Pi's local/Tailscale IPs
3. Build and deploy to Apple TV

## Features

- Real-time sync with Pi data (todo, grocery, reminders, activity)
- Offline cache fallback
- Deep linking support (`pidashboard://section/todo/item/todo-0`)
- Connection status indicator
- Horizontal card scroll navigation

## Related

- **Server:** [tv-dashboard](https://github.com/JJGantt/tv-dashboard) — Flask server that serves JSON and rendered poster images
- **Backend:** [pi-server](https://github.com/JJGantt/pi-server) — Main HTTP server on Pi
