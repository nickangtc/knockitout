# Knock It Out — Product Requirements Document

## 1. Product Summary

**Knock It Out** is a simple native macOS menu bar app that helps users quickly capture and knock out current-session items before they get distracted.

The app is not a task manager and must never refer to itself as a to-do list, task list, checklist, backlog, or productivity system. It exists for one purpose: helping users capture the things they intend to knock out in the current laptop session, keep them visible, and remove them with a small satisfying moment when everything is cleared.

## 2. Core Problem

When users open a fresh laptop session, they often arrive with a few specific things in mind but quickly get distracted. They need a fast way to capture those intentions immediately and keep them visible on the desktop without creating a heavyweight planning system.

## 3. Product Principles

1. **Capture first** — adding items must be extremely fast.
2. **Session-oriented** — items are current-session intentions, not a long-term backlog.
3. **Always visible when useful** — current items float on the desktop until knocked out.
4. **Zero is the reward** — when there are no items, the desktop is clean.
5. **No task-manager creep** — no projects, priorities, due dates, tags, reminders, analytics, or history in MVP.
6. **Native and lightweight** — the app should feel like a small Mac utility.

## 4. Vocabulary Rules

Avoid these terms internally and externally:

- todo
- to-do
- task
- completed
- done
- checklist
- backlog

Preferred terms:

- item
- current item
- knock item
- knock out
- knocked out
- clear

Internal model name: `KnockItem`.

## 5. Target Platform

- Native macOS app
- macOS 14 Sonoma+
- SwiftUI + AppKit interop
- Menu bar utility
- No Dock icon

## 6. MVP Scope

### Included

1. Menu bar macOS app with no Dock icon.
2. Launch at login enabled by default.
3. Tiny first-run welcome window.
4. Global hotkey: `⌘⇧K`.
5. Centered launcher with dark background mask.
6. Fast item capture.
7. Paste multiple lines to create multiple items.
8. Existing item list inside launcher.
9. Keyboard selection in launcher with `↑` / `↓`.
10. `Enter` toggles active state for selected launcher item.
11. `E` edits selected launcher item.
12. `K` knocks out selected launcher item.
13. Top-right floating rail.
14. Rail item dots that expand into pills on hover or active state.
15. Click rail item to toggle active state.
16. Double-click rail item to edit inline.
17. Drag rail items to reorder.
18. KO button on rail item hover.
19. Short undo toast after knock out.
20. Zero-items celebration.
21. Local JSON persistence.
22. Menu bar clear-all command with confirmation.

### Excluded

- Projects
- Priorities
- Due dates
- Tags
- Reminders
- Calendar integration
- Notifications
- Sound effects
- Visible history
- Analytics
- Custom hotkeys
- Preferences window
- App Store distribution work
- Reordering inside launcher
- Multi-step onboarding

## 7. Data Model

### `KnockItem`

Fields:

```swift
struct KnockItem: Identifiable, Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var isActive: Bool
}
```

Notes:

- Duplicate titles are allowed.
- Active state persists.
- Item order is defined by array order in persistence.
- There is no `completed`, `done`, or `task` field.

## 8. Persistence

Current items are stored as JSON at:

```text
~/Library/Application Support/Knock It Out/items.json
```

Persistence behavior:

- Save immediately after add, edit, reorder, active toggle, knock out, undo, and clear all.
- Restore all items silently on app launch.
- Do not auto-clear stale items.
- No visible or hidden item history for MVP, except ephemeral undo state.

## 9. Launch and Onboarding

### Launch at Login

- Enabled by default on first launch.
- The app is intended to be available at the start of each Mac session.

### First-Run Welcome

Show a small welcome window on first launch.

Copy:

**Title:** Knock It Out

**Body:** Press ⌘⇧K anytime to add or knock out current items. Knock It Out starts automatically when you log in. You can quit or clear items from the menu bar.

**Button:** Start knocking things out

Button behavior:

1. Close welcome window.
2. Open launcher immediately.
3. Focus input.

## 10. Global Hotkey

Default hotkey:

```text
⌘⇧K
```

Behavior:

- Opens the centered launcher.
- Focuses input immediately.
- If launcher is already open, the hotkey may refocus or toggle it closed. Recommended MVP behavior: refocus if open.

If hotkey registration fails:

- Show an alert: “Couldn’t register ⌘⇧K. Another app may be using it.”

## 11. Launcher

### Purpose

The launcher is both:

1. A fast capture surface.
2. A keyboard surface for current items.

### Layout

- Centered horizontally and vertically on the current cursor screen.
- Darkened background mask covers the current screen only.
- Launcher width: approximately 520px.
- Height is dynamic.
- If existing items are shown, only about 3 are visible at once; list scrolls inside its parent container.

### Input Mode

Default state when opened:

- Input is focused.
- No existing item is selected.
- Existing item list is passive.
- Typing goes into the input, including the letter `K`.

Placeholder:

```text
What are you knocking out?
```

Input behavior:

- Enter with non-empty text creates item(s).
- Enter with empty/whitespace input does nothing.
- If pasted text contains multiple lines, Enter creates one item per non-empty line.
- Input clears after item creation.
- Launcher remains open after item creation.
- Esc closes launcher when no list selection or edit mode is active.

Validation:

- Trim leading/trailing whitespace.
- Ignore empty lines.
- Recommended hard max title length: 200 characters.

### Existing Item List

- Appears below input when items exist.
- Shows current items in rail order.
- Displays around 3 visible rows with internal scrolling.
- Passive by default.

Optional label:

```text
Current items
```

### Selection Mode

Activation:

- Press `↓` to activate the list and select the first item.
- Press `↑` / `↓` to move selection.

Selected item hints:

- Show keycap-style hint: `[K] KO`
- Show edit hint if space allows: `[E] Edit`
- Enter toggles active state.

Keyboard behavior in selection mode:

- `↑` / `↓`: move selection
- `Enter`: toggle active/inactive
- `K`: knock out selected item
- `E`: edit selected item
- `Esc`: return to input mode and clear selection

### Launcher Editing

When a selected item is edited with `E`:

- Selected row becomes inline editable.
- Enter saves edit.
- Esc cancels edit.
- Empty/whitespace save should be ignored and keep editing.
- After save, return to list selection mode.
- Persist immediately after save.

### Launcher Knock Out

When `K` is pressed on a selected item:

- Item is knocked out.
- Item briefly animates/fades/strikes if feasible.
- Item disappears from list and rail.
- Launcher stays open.
- Selection moves to next item if available, otherwise previous item.
- If no items remain, list disappears and input remains focused.
- Trigger zero-items celebration if it was the last item.
- Show undo toast.

## 12. Floating Rail

### Purpose

The rail keeps current items visible on the desktop.

### Placement

- Fixed top-right vertical rail.
- First item appears near the top-right corner.
- New items appear below existing items.
- Rail floats above normal windows.
- Rail is hidden entirely when there are zero items.
- Empty rail area should not block clicks to underlying windows.

### Multi-Display Behavior

Recommended MVP behavior:

- Launcher appears on the screen containing the cursor when `⌘⇧K` is pressed.
- Rail lives on the current/active screen.
- Basic multi-display behavior is sufficient for MVP.

### Item Appearance

Default:

- Small circular dot/bubble.

On hover:

- Expands leftward into a rounded pill.
- Shows truncated item title.
- Shows KO button.

Active:

- Shows clear border/glow around bubble and/or pill.
- Active state can apply to multiple items at once.
- Active state has no timer or analytics behavior.

Text:

- Single-line only.
- Truncate with ellipsis beyond max width.
- Recommended pill max width: around 260px.
- Native tooltip may show full title after hover delay.

### Rail Interactions

- Click item: toggle active state.
- Double-click item: edit inline.
- Hover item: expand pill and show KO button.
- Click KO button: knock out item.
- Drag item vertically: reorder rail items.

### Rail Editing

- Double-click bubble/pill to edit inline.
- Enter saves.
- Esc cancels.
- Clicking away saves if non-empty.
- Empty/whitespace save should not be accepted.
- Persist immediately after save.

### Rail Reordering

- Drag item vertically within rail.
- Drop position updates array order.
- Order persists to JSON.
- Launcher reflects same order.
- Active state travels with item.

Recommended visual behavior:

- Dragged item lifts or changes opacity.
- Other items shift to preview drop position.

## 13. Knock Out Behavior

An item can be knocked out by:

1. Clicking the rail hover **KO** button.
2. Opening launcher, selecting an item, and pressing `K`.

KO behavior:

- Remove item from current items.
- Persist immediately.
- Show undo toast.
- If it was the last item, trigger zero-items celebration.

KO button label:

```text
KO
```

No confirmation is required for individual KO actions.

## 14. Undo Toast

After an item is knocked out:

- Show small toast: **Knocked out. Undo**
- Undo window: approximately 5 seconds.
- Clicking Undo restores the item.
- Restored item returns to its previous order position if feasible; otherwise nearest sensible position.
- Undo state is ephemeral and does not survive app quit.
- Clear All does not require undo because it has confirmation.

## 15. Zero-Items State and Celebration

When the final item is knocked out:

- Rail disappears.
- Desktop becomes clean.
- Trigger a tiny confetti/spark burst near the rail or final item position.
- Optional microcopy: **All knocked out.**
- No sound.
- No blocking overlay.
- Auto-disappear quickly, under roughly 1.5 seconds.

If the user undoes the final KO:

- Restore the item.
- No need to reverse the celebration.

## 16. Menu Bar

The app has a menu bar icon only. No Dock icon.

Menu contents:

1. Open Knock It Out
2. Clear All Items…
3. Launch at Login ✓
4. About Knock It Out
5. Quit Knock It Out

### Open Knock It Out

- Opens the same launcher as `⌘⇧K`.

### Clear All Items…

- Opens confirmation dialog.
- Confirmation copy:

Title/body:

```text
Clear all current items?
```

Buttons:

- Destructive: **Clear Items**
- Cancel: **Cancel**

Clear behavior:

- Removes all current items.
- Persists immediately.
- No history.
- No undo required for MVP.

## 17. Visual and Motion Direction

### Theme

- Dark translucent overlay style for launcher and rail.
- Keep UI minimal, lightweight, and focused.

### Animation

Use subtle animations only:

- Launcher fade/scale in.
- Pill expansion on hover.
- KO fade/shrink or strike.
- Tiny zero-state spark/confetti burst.

Avoid:

- Loud bounce effects.
- Long animations.
- Sound.
- Full-screen celebration overlays.

## 18. Accessibility and Permissions

- Avoid requiring Accessibility permission if possible.
- Prefer global hotkey implementation that does not require invasive permissions.
- Ensure keyboard-only use for launcher flows.
- Use sufficient contrast for selected and active states.

## 19. Technical Notes

### App Architecture

Recommended components:

- `KnockItemStore`
  - Owns `[KnockItem]`
  - Loads/saves JSON
  - Add/edit/reorder/toggle active/KO/undo/clear

- `HotKeyController`
  - Registers `⌘⇧K`
  - Opens/refocuses launcher

- `MenuBarController`
  - Owns status item and menu commands

- `LauncherWindowController`
  - Borderless centered overlay window
  - Dark mask

- `RailWindowController`
  - Floating top-right rail window
  - Click-through empty areas if feasible

- SwiftUI views:
  - `LauncherView`
  - `RailView`
  - `RailItemView`
  - `UndoToastView`
  - `CelebrationView`
  - `WelcomeView`

### Suggested Bundle Identifier

```text
com.nickang.knockitout
```

## 20. Manual MVP Test Cases

1. First launch shows welcome.
2. Clicking welcome CTA opens launcher.
3. `⌘⇧K` opens launcher.
4. Launcher input is focused by default.
5. Typing one item and pressing Enter creates one item.
6. Pasting multiple lines and pressing Enter creates multiple items.
7. Empty input + Enter does nothing.
8. Existing item list is passive by default.
9. Pressing `↓` selects first launcher item.
10. `↑` / `↓` changes selected item.
11. Enter toggles selected item active state.
12. `E` edits selected launcher item.
13. `K` knocks out selected launcher item.
14. Launcher stays open after KO.
15. KO selection moves to next/previous item.
16. Rail appears top-right when items exist.
17. Rail disappears when zero items exist.
18. Hovering rail item expands pill.
19. Rail title truncates with ellipsis.
20. Clicking rail item toggles active state.
21. Double-clicking rail item edits inline.
22. Dragging rail item reorders items.
23. Reordered items persist after app restart.
24. Active states persist after app restart.
25. KO button removes item and shows undo toast.
26. Undo restores knocked item.
27. Last KO triggers celebration.
28. Menu bar Open Knock It Out opens launcher.
29. Clear All Items shows confirmation.
30. Clear Items removes all current items.
31. App has no Dock icon.
32. App launches at login after first run.
33. Hotkey conflict alert appears if registration fails.

## 21. Open Questions for Later

These are intentionally deferred:

- Custom hotkey support.
- Preferences window.
- Better stale-session handling.
- Visible history or recap.
- App Store distribution.
- Fullscreen-space behavior.
- Advanced multi-display placement.
- Gesture-based flick-to-KO interaction.
- More detailed visual branding.
