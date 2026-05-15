# Knock It Out — Implementation Plan

This plan translates `docs/prd.md` into a concrete native macOS MVP build plan. It assumes a new SwiftUI/AppKit macOS app targeting macOS 14+ with bundle identifier `com.nickang.knockitout`.

## 1. Implementation Goals

Build a lightweight menu bar-only macOS app that lets users quickly capture, keep visible, activate, reorder, edit, and knock out current-session items.

The MVP should prioritize:

1. Fast capture via `⌘⇧K`.
2. Reliable local persistence.
3. Polished enough native UI for launcher, rail, undo, and zero-state celebration.
4. Keyboard-first launcher behavior.
5. No expansion into planning/productivity-system features.

## 2. Vocabulary and Naming Guardrails

Use product language consistently in user-facing copy, code comments, model names, and test descriptions.

Allowed/preferred:

- `KnockItem`
- item
- current item
- knock item
- knock out
- knocked out
- clear
- active

Avoid:

- todo
- to-do
- task
- completed
- done
- checklist
- backlog

Implementation note: standard framework names like `NSMenuItem` are unavoidable and acceptable.

## 3. Proposed Project Structure

Create an Xcode macOS app project, or generate equivalent files manually, with this logical layout:

```text
KnockItOut/
  KnockItOutApp.swift
  AppDelegate.swift

  Models/
    KnockItem.swift
    KnockItemUndoSnapshot.swift

  Stores/
    KnockItemStore.swift
    AppSettingsStore.swift

  Controllers/
    HotKeyController.swift
    MenuBarController.swift
    LauncherWindowController.swift
    RailWindowController.swift
    WelcomeWindowController.swift

  Views/
    Launcher/
      LauncherView.swift
      LauncherItemRowView.swift
    Rail/
      RailView.swift
      RailItemView.swift
      RailDropDelegate.swift
    Toast/
      UndoToastView.swift
    Celebration/
      CelebrationView.swift
    Welcome/
      WelcomeView.swift

  Infrastructure/
    PersistencePaths.swift
    GlobalHotKey.swift
    ClickThroughHostingWindow.swift
    FloatingPanelWindow.swift
    ScreenPlacement.swift

  Resources/
    Assets.xcassets
    Info.plist
```

For a small app, this can remain one target with no separate packages.

## 4. App Lifecycle and Activation Policy

### Requirements

- Menu bar utility.
- No Dock icon.
- Launch at login enabled by default on first launch.
- First-run welcome window.

### Implementation

1. Use `@main` SwiftUI app with an `NSApplicationDelegateAdaptor` app delegate.
2. In `applicationDidFinishLaunching`:
   - Set `NSApp.setActivationPolicy(.accessory)` to hide Dock icon.
   - Initialize shared stores/controllers.
   - Load persisted items.
   - Create menu bar status item.
   - Register global hotkey.
   - Create rail controller and show rail if items exist.
   - Check first-run flag.
3. If first run:
   - Enable launch at login.
   - Show welcome window.
4. If not first run:
   - App stays resident with only menu bar/rail visible.

### Launch at Login

Use `ServiceManagement`:

```swift
SMAppService.mainApp.register()
SMAppService.mainApp.unregister()
SMAppService.mainApp.status
```

Store a first-run marker in `UserDefaults`, for example:

```swift
hasCompletedFirstRunWelcome: Bool
hasAppliedDefaultLoginItem: Bool
```

Default behavior:

- On first launch, the welcome window should clearly mention launch at login and include a checkbox to enable/disable it before continuing.
- The checkbox should default to enabled, matching the PRD intent, but the user can opt out before the app registers itself.
- When the welcome CTA is clicked, apply the checkbox choice via `SMAppService.mainApp.register()` or `unregister()`.
- If registration fails, do not block MVP use; consider logging and leaving menu state off.
- The menu item toggles this setting after onboarding.

## 5. Data Model

Implement exactly the PRD model:

```swift
struct KnockItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    let createdAt: Date
    var isActive: Bool
}
```

Recommended initializer:

```swift
init(id: UUID = UUID(), title: String, createdAt: Date = Date(), isActive: Bool = false)
```

Validation rules should live in `KnockItemStore` or a helper:

- Trim leading/trailing whitespace.
- Ignore empty lines.
- Maximum title length: 200 characters.
- Duplicate titles allowed.

## 6. Persistence

### Location

```text
~/Library/Application Support/Knock It Out/items.json
```

### Implementation

Create `PersistencePaths`:

- Resolve application support directory.
- Create `Knock It Out` folder if missing.
- Expose `itemsURL`.

Use `JSONEncoder`/`JSONDecoder` with stable date strategy:

```swift
encoder.dateEncodingStrategy = .iso8601
decoder.dateDecodingStrategy = .iso8601
```

### Save Behavior

Save immediately after:

- Add.
- Edit.
- Reorder.
- Toggle active.
- Knock out.
- Undo.
- Clear all.

Implementation options:

- For MVP, synchronous atomic writes on the main actor are acceptable because the data is tiny.
- Use `Data.write(to:options: .atomic)`.
- If save fails, keep in-memory state and log error. Optional: present a non-blocking alert later.

## 7. KnockItemStore

`KnockItemStore` should be the single source of truth.

Recommended declaration:

```swift
@MainActor
final class KnockItemStore: ObservableObject {
    @Published private(set) var items: [KnockItem] = []
    @Published var lastUndo: KnockItemUndoSnapshot?

    func load()
    func addTitles(from rawInput: String)
    func edit(id: UUID, title: String) -> Bool
    func toggleActive(id: UUID)
    func knockOut(id: UUID)
    func undoLastKnockOut()
    func move(from source: IndexSet, to destination: Int)
    func moveItem(id: UUID, toIndex: Int)
    func clearAll()
}
```

Undo snapshot:

```swift
struct KnockItemUndoSnapshot: Identifiable {
    let id = UUID()
    let item: KnockItem
    let previousIndex: Int
    let knockedOutAt: Date
}
```

Undo rules:

- Store only the most recent knocked-out item.
- Clear snapshot automatically after about 5 seconds.
- Clicking Undo restores at `previousIndex` if still valid; otherwise append or insert at nearest valid index.
- Undo state does not persist.
- Clear All clears undo state.

Store should publish lightweight events for UI-only effects:

```swift
enum KnockItemEvent {
    case itemKnockedOut(id: UUID)
    case finalItemKnockedOut(anchor: CGPoint?)
    case itemsCleared
}
```

Simpler MVP alternative: expose closures from controllers instead of an event stream.

## 8. Menu Bar Controller

### Menu Contents

1. Open Knock It Out
2. Clear All Items…
3. Launch at Login ✓
4. About Knock It Out
5. Quit Knock It Out

### Implementation

Use `NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)`.

Icon:

- MVP should use a custom template-style menu bar asset: a solid white circle with the letter `K` inside.
- Provide light/dark-compatible template rendering where possible.
- If template rendering makes the inner letter unclear, use separate light/dark asset variants.

Actions:

- Open Knock It Out: call `LauncherWindowController.open(on: currentCursorScreen)`.
- Clear All Items…: show `NSAlert` confirmation.
- Launch at Login: toggle `SMAppService.mainApp` registration.
- About: call `NSApp.orderFrontStandardAboutPanel(nil)`.
- Quit: `NSApp.terminate(nil)`.

Clear confirmation:

- Message/body: `Clear all current items`
- Destructive button: `Clear Items`
- Cancel button: `Cancel`

After clear:

- Store clears items and persists.
- Rail hides.
- No undo.

## 9. Global Hotkey

### Requirement

Default: `⌘⇧K`.

Behavior:

- Opens centered launcher on screen containing cursor.
- Focuses input.
- If launcher already open, refocus it.
- Alert if registration fails.

### Recommended Implementation

Use Carbon RegisterEventHotKey for a permission-light global hotkey.

- Key code for `K`: 40 on ANSI keyboard layouts.
- Modifiers: command + shift.
- Register in `HotKeyController`.
- Install event handler that calls launcher open/refocus.

Caveats:

- Carbon hotkeys are old but still commonly used for menu bar utilities.
- Confirm no Accessibility permission is required.
- If `RegisterEventHotKey` returns non-zero, show alert:
  `Couldn’t register ⌘⇧K. Another app may be using it.`

Dependency policy:

- Stay dependency-free/native-only for MVP unless a native approach proves impractical.
- Use Carbon directly for the hotkey first.
- Only introduce a third-party package after confirming the native implementation is not sufficient.

## 10. Windowing Strategy

The app needs several special-purpose windows:

1. Welcome window.
2. Launcher overlay window.
3. Rail floating window.
4. Undo toast window or in-rail overlay.
5. Celebration overlay/window.

### Window Levels

Recommended levels:

- Launcher: `.modalPanel` or `.floating` with activation when opened.
- Rail: `.floating`, possibly `.statusBar` if needed to remain visible.
- Toast/Celebration: near rail, same or slightly higher level than rail.

Avoid making windows invasive above all system UI unless necessary.

### Spaces and Fullscreen

The rail should appear across all Spaces. Set collection behavior thoughtfully:

```swift
window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

Apply this primarily to the rail, toast, and celebration windows. The launcher should open on demand on the main display/current invocation context and dismiss normally.

## 11. First-Run Welcome

### Copy

Title: `Knock It Out`

Body:

```text
Press ⌘⇧K anytime to add or knock out current items. You can quit or clear items from the menu bar.
```

Checkbox, default checked:

```text
Start Knock It Out when I log in
```

Button: `Start knocking things out`

### Behavior

Button action:

1. Apply launch-at-login choice from the checkbox.
2. Save first-run completion flag.
3. Close welcome window.
4. Open launcher immediately.
5. Focus launcher input.

Implementation:

- Standard titled non-resizable `NSWindow` hosting `WelcomeView`.
- Keep it small and centered.

## 12. Launcher Window

### Behavior

- Opens on screen containing cursor.
- Dark background mask covers only that screen.
- Centered launcher card, approximately 520 px wide.
- Dynamic height.
- Existing item list scrolls after about 3 rows.
- Input focused by default.
- Refocus if hotkey invoked while already open.

### AppKit Implementation

`LauncherWindowController` creates a borderless transparent window sized to current screen frame:

```swift
let window = NSWindow(
    contentRect: screen.frame,
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)
window.backgroundColor = .clear
window.isOpaque = false
window.level = .modalPanel
window.hasShadow = false
```

SwiftUI `LauncherView` renders:

- Full-screen semi-transparent dark mask.
- Centered card.
- Input.
- Existing item list.

Close rules:

- Clicking outside the launcher card closes the launcher.
- Esc closes only when no selection/edit mode is active.

## 13. Launcher View State Machine

Model explicit modes to prevent keyboard conflicts:

```swift
enum LauncherMode: Equatable {
    case input
    case selection(index: Int)
    case editing(id: UUID, draft: String)
}
```

### Input Mode

Default on open:

- Input focused.
- No selected row.
- Existing list passive.
- Letter `K` goes into input.

Key behavior:

- Enter with non-empty text: add one or more items.
- Enter with empty text: no-op.
- Down arrow: if items exist, select first item.
- Esc: close launcher.

Paste handling:

- Plain multiline paste into input is fine.
- On Enter, split input by newlines and create one item per non-empty line.

### Selection Mode

Activation:

- Press `↓` from input mode.

Key behavior:

- Up/down: move selection.
- Enter: toggle active for selected item.
- `K`: knock out selected item.
- `E`: enter editing mode.
- Esc: return to input mode and focus input.

Important:

- Do not let `K` knock anything out while input mode is active.

### Editing Mode

Behavior:

- Inline row text field.
- Enter: save if trimmed title is non-empty; stay editing if empty.
- Esc: cancel, return to selection mode.
- Persist immediately on save.

After KO in selection mode:

- Compute next selected index:
  - Same index if another item shifted into it.
  - Otherwise previous index.
  - If no items remain, return to input mode and focus input.
- Keep launcher open.
- Show undo toast.
- Trigger celebration if final item was knocked out.

## 14. Floating Rail Window

### Behavior

- Fixed top-right vertical rail.
- Hidden when zero items.
- New items appear below existing items.
- Floats above normal windows.
- Empty area should not block clicks if feasible.
- Basic multi-display behavior acceptable.

### Placement

MVP placement recommendation:

- Track the screen containing the cursor whenever launcher opens or items are added.
- Rail appears near top-right of that screen.
- On app launch, place rail on main screen.

Suggested frame:

```text
width: 320 px
height: min(screen height - top/bottom margins, content height)
x: screen.visibleFrame.maxX - width - 16
y: screen.visibleFrame.maxY - height - 24
```

Because pills expand leftward, the rail window needs enough width for expanded pill text, while content aligns to the right.

### Click-Through Empty Area

Options:

1. Simpler MVP: use a narrow-enough rail window and accept limited empty-area blocking.
2. Better MVP: custom `NSWindow`/`NSView` hit testing so only visible item regions receive mouse events.

Recommended implementation:

- Create `ClickThroughHostingWindow` with `ignoresMouseEvents = false`.
- Use a custom hosting root view or NSView wrapper that returns `nil` from `hitTest` for transparent/empty regions.
- If this becomes time-consuming, defer and document as polish.

## 15. Rail View and Interactions

### Rail Item Default Appearance

- Small circular dot/bubble aligned right.
- Active state: border/glow.
- Hover: expands leftward into rounded pill.
- Shows truncated single-line title.
- Shows `KO` button.
- Native tooltip with full title.

### SwiftUI State

Per item:

- `isHovered`
- `isEditing`
- `editDraft`
- drag state

Store-backed:

- title
- isActive
- order

### Click Behavior

- Single click bubble/pill: toggle active.
- Double click: edit inline.

Implementation detail:

- SwiftUI `onTapGesture(count: 2)` can conflict with single tap.
- Prefer an `NSViewRepresentable` click handler or delayed single-tap dispatch:
  - On first click, wait briefly before toggling.
  - If second click arrives, cancel toggle and begin edit.

For MVP, if a small conflict exists, prioritize double-click edit correctness.

### KO Button

- Visible on hover pill.
- Clicking `KO` knocks out item.
- Prevent click from also toggling active.
- Show undo toast.
- Trigger final-item celebration if applicable.

### Inline Editing

- Double-click to enter edit.
- Text field in pill.
- Enter saves if non-empty.
- Esc cancels.
- Clicking away saves if non-empty.
- Empty/whitespace save should not be accepted; keep editing and require valid text or Esc to cancel.

### Reordering

Use SwiftUI drag/drop or custom gesture.

Recommended MVP approach:

- Implement `.onMove` logic in store.
- Use `onDrag`/`onDrop` with a `DropDelegate` for rail items.
- As drag enters another row, update item order with animation.
- Persist after final drop or after each reorder event. PRD says persist after reorder; persisting after each move is acceptable but can be noisy. Better: reorder in memory during hover and persist at drop completion if feasible.

If SwiftUI drag/drop feels unreliable in floating borderless window, fallback:

- Use a vertical `DragGesture`.
- Track dragged item offset.
- Calculate target index based on row height.
- Commit on gesture end.

## 16. Undo Toast

### Behavior

- After individual KO, show: `Knocked out. Undo`
- Stays visible approximately 5 seconds.
- Clicking Undo restores item.
- Undo is ephemeral.
- Clear All has no undo.

### Implementation Options

Recommended:

- Render toast inside rail window if rail still visible.
- If final item was knocked out and rail hides, show a tiny separate toast window near the previous rail/final item position.

Simpler MVP:

- Always use a small toast window controlled by `ToastWindowController` near top-right rail position.

Toast state source:

- `KnockItemStore.lastUndo`.
- Timer in store or toast controller clears it after 5 seconds.

Clicking Undo:

- Calls `store.undoLastKnockOut()`.
- Hides toast.
- Shows rail again.

## 17. Zero-Items Celebration

### Behavior

- Trigger only when the final item is knocked out.
- Tiny spark/confetti burst near rail/final item.
- Optional copy: `All knocked out.`
- No sound.
- No blocking overlay.
- Auto-disappear under ~1.5 seconds.

### Implementation

MVP SwiftUI approach:

- `CelebrationView` in a small transparent floating window near rail anchor.
- Use several small colored circles or capsule shapes with randomized offsets/opacity.
- Animate outward and fade.
- Dismiss after 1.2–1.5 seconds.

Keep it simple and subtle.

## 18. Active State

Active state is a lightweight visual marker only.

Rules:

- Multiple active items allowed.
- No timers.
- No analytics.
- Persists to JSON.
- Toggled by launcher Enter in selection mode.
- Toggled by single click on rail item.

Visuals:

- Launcher selected active row can show accent border/dot.
- Rail active item should show border/glow on bubble/pill.

## 19. Multi-Display Behavior

MVP behavior:

- Launcher opens on screen containing cursor, as specified in the PRD.
- Rail stays on the main display.
- Rail appears across all Spaces on the main display.
- Do not dynamically move the rail to cursor/active displays in MVP.

Helper:

```swift
struct ScreenPlacement {
    static func screenContainingCursor() -> NSScreen
    static func launcherFrame(for screen: NSScreen) -> NSRect
    static func railFrame(for screen: NSScreen, itemCount: Int) -> NSRect
}
```

Potential edge cases to test manually:

- External monitor above/below laptop.
- Menu bar on non-main screen.
- Cursor screen changes while rail is visible.

Do not overbuild advanced multi-display behavior for MVP.

## 20. Accessibility and Keyboard Support

Minimum implementation:

- Launcher fully usable by keyboard.
- Sufficient contrast for selected and active states.
- Text fields have clear focus.
- Buttons have accessible labels.
- Rail item tooltip or accessibility label includes full title.

Avoid Accessibility permission:

- Use Carbon hotkey rather than event taps.
- Do not implement global keyboard monitoring beyond the registered hotkey.

## 21. Manual Test Plan Mapping

Use the PRD's 33 manual test cases as the acceptance checklist. During implementation, group testing by phase:

### Launch/App Tests

- First launch welcome.
- CTA opens launcher.
- No Dock icon.
- Launch-at-login checkbox defaults on during first run and applies the user's choice.
- Menu commands work.
- Hotkey conflict alert.

### Launcher Tests

- Hotkey opens/refocuses.
- Input focus.
- Single add.
- Multiline add.
- Empty Enter no-op.
- Passive list by default.
- Arrow selection.
- Enter toggles active.
- `E` edits.
- `K` knocks out.
- Selection moves correctly after KO.
- Launcher remains open.

### Rail Tests

- Appears when items exist.
- Disappears at zero.
- Hover expansion.
- Title truncation.
- Click active toggle.
- Double-click inline edit.
- Drag reorder.
- Reorder persists.
- Active persists.

### KO/Undo/Celebration Tests

- KO button removes item.
- Undo restores item.
- Final KO triggers celebration.
- Undo after final KO restores rail.

### Persistence Tests

- Items restore after app restart.
- Order persists.
- Active state persists.
- Edits persist.
- Clear all persists.

## 22. Build Phases

### Phase 0 — Project Bootstrap

Deliverables:

- New macOS SwiftUI project.
- Bundle identifier `com.nickang.knockitout`.
- macOS deployment target 14.0.
- App runs locally.
- Dock icon hidden via activation policy or Info.plist `LSUIElement`.

Acceptance:

- App launches without Dock icon.
- App can be quit from Xcode/debugger.

### Phase 1 — Model, Store, Persistence

Deliverables:

- `KnockItem` model.
- `KnockItemStore` with all core mutations.
- JSON load/save at required path.
- Basic unit tests if test target exists.

Acceptance:

- Add/edit/toggle/reorder/KO/undo/clear update in-memory state.
- JSON is written after each mutation.
- App relaunch restores items.

### Phase 2 — Menu Bar Shell and Launch at Login

Deliverables:

- Status item.
- Menu commands.
- Clear-all confirmation.
- Launch-at-login default enablement and toggle.
- About and Quit.

Acceptance:

- Menu contents match PRD.
- Clear all removes/persists.
- Launch at Login menu reflects current status.

### Phase 3 — Hotkey Controller

Deliverables:

- Register `⌘⇧K`.
- Open/refocus launcher callback.
- Failure alert.

Acceptance:

- Hotkey opens launcher from any app without Accessibility prompt.
- Repeated hotkey refocuses launcher.

### Phase 4 — First-Run Welcome

Deliverables:

- Welcome window with exact copy.
- First-run flag.
- CTA opens launcher and focuses input.

Acceptance:

- First launch shows welcome once.
- CTA behavior matches PRD.

### Phase 5 — Launcher MVP

Deliverables:

- Borderless screen overlay with dark mask.
- Centered 520 px launcher card.
- Focused input.
- Add single/multiple items.
- Existing item list with ~3 visible rows and scrolling.
- Input/selection/editing state machine.
- Keyboard actions: arrows, Enter, `E`, `K`, Esc.

Acceptance:

- PRD launcher test cases pass.
- No accidental KO while typing `K` in input.

### Phase 6 — Rail MVP

Deliverables:

- Floating rail window.
- Hide when zero items.
- Dot default state.
- Hover pill expansion.
- Truncated title.
- Active visual state.
- Single-click toggle.
- KO button.
- Inline edit.

Acceptance:

- Rail appears/disappears correctly.
- Click/hover/edit/KO interactions work.
- Changes persist.

### Phase 7 — Undo Toast and Celebration

Deliverables:

- Undo toast with 5-second window.
- Undo restores previous item/index.
- Final KO celebration.

Acceptance:

- Undo works after rail and launcher KO.
- Final KO triggers subtle celebration.
- Undo after final KO restores rail.

### Phase 8 — Rail Reordering

Deliverables:

- Drag vertical reorder.
- Visual drop feedback.
- Persisted order.
- Launcher reflects same order.

Acceptance:

- Dragging item changes rail order.
- Relaunch preserves order.
- Active state travels with item.

### Phase 9 — Polish and Hardening

Deliverables:

- Animations: launcher fade/scale, pill expansion, KO fade/shrink, celebration.
- Click-through empty rail area if feasible.
- Multi-display sanity.
- Accessibility labels.
- Error handling for persistence and hotkey conflicts.

Acceptance:

- All 33 manual MVP test cases pass.
- App feels lightweight and native.
- No forbidden vocabulary in user-facing UI.

## 23. Suggested Implementation Order Within Code

1. Define `KnockItem` and store API.
2. Implement persistence and test via temporary debug menu actions.
3. Add menu bar app shell.
4. Add launcher window with static view.
5. Wire launcher add flow to store.
6. Add hotkey.
7. Add welcome window.
8. Add launcher list/selection/edit/KO flows.
9. Add rail window and passive rendering.
10. Add rail hover/click/KO/edit.
11. Add undo toast.
12. Add celebration.
13. Add reorder.
14. Polish animations and multi-display behavior.
15. Run manual test pass and fix edge cases.

## 24. Key Technical Risks and Mitigations

### Risk: Global hotkey conflicts or keyboard layout issues

Mitigation:

- Show required conflict alert on registration failure.
- Use Carbon key code initially.
- Later, consider a hotkey library or configurable hotkey if product scope expands.

### Risk: Rail click-through empty areas are tricky

Mitigation:

- Start with a compact rail window to minimize blocked area.
- Add custom hit-testing during polish.
- Do not let this block core MVP interactions.

### Risk: Single-click and double-click conflict on rail

Mitigation:

- Use an AppKit-backed click recognizer or delayed single-click action.
- Test carefully because this affects active toggle and edit.

### Risk: SwiftUI drag/drop in floating borderless window may be finicky

Mitigation:

- Prototype early.
- If unreliable, implement custom `DragGesture` reorder.

### Risk: Launcher keyboard focus

Mitigation:

- Use `@FocusState` plus explicit AppKit `makeFirstResponder` after window display.
- Keep launcher modes explicit.

### Risk: Launch at login behavior varies in debug builds

Mitigation:

- Test with an archived/signed local build.
- Keep menu status resilient if registration status is unavailable.

## 25. Confirmed Product/Implementation Decisions

These decisions were confirmed after reviewing the initial implementation plan:

1. Rail appears across all Spaces.
2. Clicking outside the launcher card dismisses the launcher.
3. Menu bar icon should be a solid white circle with the letter `K` inside.
4. Empty inline edits should keep editing and require valid text or Esc.
5. MVP should stay dependency-free/native-only unless a dependency becomes truly necessary.
6. First-run welcome should include a launch-at-login checkbox, default checked.
7. Rail should stay on the main display in MVP.
8. Clear-all confirmation should only say `Clear all current items`.

## 26. MVP Definition of Done

The MVP is complete when:

- All included PRD features are implemented.
- All excluded PRD features are absent.
- All 33 manual test cases pass.
- No forbidden product vocabulary appears in user-facing UI.
- Items persist in the required JSON location.
- App runs as a menu bar-only macOS utility on macOS 14+.
- `⌘⇧K` opens/refocuses the launcher and requires no Accessibility permission.
