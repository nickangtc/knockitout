# Knock It Out — Agent Notes

This file is for future Pi agents working in this repository.

## Product constraints

Read `docs/prd.md` and `docs/implementation-plan.md` before making product-facing changes. Preserve the MVP boundaries.

Preferred language:

- `KnockItem`
- item / current item / knock item
- knock out / knocked out
- clear
- active

Avoid adding user-facing copy, comments, or new model fields using forbidden planning-system vocabulary from the PRD. Framework names like `NSMenuItem` are unavoidable and acceptable.

Do not add excluded features unless explicitly requested: projects, priorities, due dates, tags, reminders, calendar integration, notifications, sound effects, visible history, analytics, custom hotkeys, preferences window, App Store distribution work, launcher reordering, or multi-step onboarding.

## Architecture snapshot

This is a Swift Package executable that builds a macOS menu bar utility.

Important paths:

- `Sources/KnockItOut/KnockItOutApp.swift` — app entry point.
- `Sources/KnockItOut/AppDelegate.swift` — lifecycle wiring, duplicate-instance guard, controller setup.
- `Sources/KnockItOut/Models/KnockItem.swift` — canonical item model.
- `Sources/KnockItOut/Stores/KnockItemStore.swift` — single source of truth for items, persistence, undo, and rail colour assignment.
- `Sources/KnockItOut/Controllers/` — AppKit window/menu/hotkey controllers.
- `Sources/KnockItOut/Views/Launcher/` — launcher UI and key handling.
- `Sources/KnockItOut/Views/Rail/` — floating rail UI.
- `Sources/KnockItOut/Views/Toast/` — undo toast.
- `Sources/KnockItOut/Views/Celebration/` — final-item celebration.
- `Sources/KnockItOut/Infrastructure/` — persistence paths, screen placement, window subclasses, pointer helper.
- `Resources/Info.plist` — app bundle metadata including `LSUIElement`.
- `scripts/build-app.sh` — builds `build/Knock It Out.app`.

## Local files and persistence

Runtime JSON files are outside the repo:

- `~/Library/Application Support/Knock It Out/items.json`
- `~/Library/Application Support/Knock It Out/appearance.json`

Build outputs are ignored:

- `.build/`
- `build/`

## Development commands

After making code changes, run both the executable build and app bundle build automatically before reporting completion unless the user explicitly asks to skip builds:

```bash
swift build
scripts/build-app.sh
```

Build executable:

```bash
swift build
```

Build app bundle:

```bash
scripts/build-app.sh
```

Run app bundle:

```bash
open "build/Knock It Out.app"
```

Clean restart while testing:

```bash
pkill -x KnockItOut
open "build/Knock It Out.app"
```

Avoid `open -n` for normal testing because multiple running copies can draw overlapping rails and race on local JSON. The app also has a duplicate-instance guard now.

## Implementation notes / learned details

- Global hotkey uses Carbon `RegisterEventHotKey` for `⌘⇧K` to avoid Accessibility permission.
- Launcher keyboard handling uses a local AppKit key monitor (`LauncherKeyMonitor`) because SwiftUI `onKeyPress` was unreliable around text focus.
- Rail inline editing requires the rail window to become key; `ClickThroughHostingWindow.canBecomeKey` is `true` for this reason.
- Rail colours are assigned in `KnockItemStore` and persisted in `appearance.json`; do not derive them from hash values in the view if stable uniqueness matters.
- Undo toast is rendered inside `RailView` below the list when items remain. A separate toast window is only used after final-item KO when the rail is hidden.
- Rail hover animation is implemented as one capsule growing from right to left, not as swapping a bubble view for a pill view.
- The rail should remain compact and not block unnecessary desktop clicks more than needed.

## Before committing

Run:

```bash
swift build
scripts/build-app.sh
```

Also run a credential scan with your preferred local command, and manually check that no local runtime JSON or app bundles are staged.
