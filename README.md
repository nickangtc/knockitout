# Knock It Out

Knock It Out is a lightweight native macOS menu bar app for quickly capturing current-session items and knocking them out before distractions take over.

It is intentionally **not** a planning or productivity system: no projects, priorities, due dates, tags, reminders, analytics, visible history, or preferences window.

## Requirements

- macOS 14 Sonoma+
- Xcode / Swift toolchain

## Build

```bash
swift build
```

Build the local `.app` bundle:

```bash
scripts/build-app.sh
```

The app bundle is written to:

```text
build/Knock It Out.app
```

## Run

```bash
open "build/Knock It Out.app"
```

For a clean restart during development:

```bash
pkill -x KnockItOut
open "build/Knock It Out.app"
```

## Manual testing notes

- Menu bar icon only; no Dock icon.
- `⌘⇧K` opens/refocuses the launcher.
- Launcher input supports one item or multiple pasted lines.
- In launcher selection mode:
  - `↑` / `↓` move selection
  - `Enter` toggles active state
  - `E` edits
  - `K` knocks out
  - `Esc` returns to input mode
- Rail bubbles expand into coloured pills on hover/active state.
- Rail colours persist via local appearance metadata.
- Rail undo toast appears below the list, with reserved space.

## Persistence

Current items:

```text
~/Library/Application Support/Knock It Out/items.json
```

Rail appearance metadata:

```text
~/Library/Application Support/Knock It Out/appearance.json
```

Both are local runtime files and are not committed.

## Product language

Use: `item`, `current item`, `knock item`, `knock out`, `knocked out`, `clear`, `active`.

Avoid introducing planning-system concepts or forbidden product vocabulary in UI/copy/code comments. See `docs/prd.md` for full constraints.
