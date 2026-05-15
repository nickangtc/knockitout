import SwiftUI

enum LauncherMode: Equatable {
    case input
    case selection(index: Int)
    case editing(id: UUID, draft: String)
}

private struct SelectedLauncherRowBoundsPreferenceKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

struct LauncherView: View {
    @ObservedObject var store: KnockItemStore
    let close: () -> Void
    @State private var input = ""
    @State private var mode: LauncherMode = .input
    @FocusState private var inputFocused: Bool
    @FocusState private var editFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.48).ignoresSafeArea().onTapGesture { close() }
            card
                .frame(width: 520)
                .transition(.scale(scale: 0.97).combined(with: .opacity))
        }
        .background(LauncherKeyMonitor { event in handleKeyEvent(event) })
        .onAppear { focusInput() }
        .onChange(of: store.items) { _, newItems in keepSelectionValid(newItems) }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("What are you knocking out?", text: $input, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .padding(14)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                .focused($inputFocused)
                .onSubmit { addInput() }
                .disabled(!isInputMode)

            if !store.items.isEmpty {
                Text("Current items")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                                row(item: item, index: index)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(item.id)
                            }
                        }
                    }
                    .frame(maxHeight: 142)
                    .onChange(of: selectedIndex) { _, value in
                        if let value, store.items.indices.contains(value) {
                            withAnimation(.easeOut(duration: 0.15)) { proxy.scrollTo(store.items[value].id, anchor: .center) }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(.black.opacity(0.80), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.12)))
        .overlayPreferenceValue(SelectedLauncherRowBoundsPreferenceKey.self) { anchor in
            GeometryReader { geometry in
                if let anchor {
                    shortcutHints
                        .position(x: geometry.size.width + 54, y: geometry[anchor].midY)
                }
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 28, y: 10)
        .onTapGesture { }
    }

    private func row(item: KnockItem, index: Int) -> some View {
        let selected = selectedIndex == index
        let showsExternalHints = if case .selection = mode { selected } else { false }
        let isEditing = if case .editing(let id, _) = mode { id == item.id } else { false }
        return HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(item.isActive ? Color.accentColor : .white.opacity(0.40))
                .frame(width: 9, height: 9)
                .padding(.top, 6)
            if case .editing(let id, let draft) = mode, id == item.id {
                TextField("", text: Binding(
                    get: { draft },
                    set: { mode = .editing(id: id, draft: $0) }
                ), axis: .vertical)
                .lineLimit(1...2)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .focused($editFocused)
                .onSubmit { saveEdit(id: id, draft: draft) }
                .onAppear { editFocused = true }
            } else {
                Text(item.title)
                    .lineLimit(1...2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.white.opacity(selected ? 1 : 0.82))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
        .background(selected ? Color.white.opacity(0.14) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(item.isActive ? Color.accentColor.opacity(0.75) : .clear))
        .contentShape(Rectangle())
        .anchorPreference(key: SelectedLauncherRowBoundsPreferenceKey.self, value: .bounds) { showsExternalHints ? $0 : nil }
        .onTapGesture { if !isEditing { mode = .selection(index: index); inputFocused = false } }
    }

    private var shortcutHints: some View {
        HStack(spacing: 10) {
            Text("[K]O")
                .font(.caption.monospaced().weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            Text("[E]dit")
                .font(.caption.monospaced().weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var isInputMode: Bool { if case .input = mode { true } else { false } }
    private var selectedIndex: Int? { if case .selection(let i) = mode { i } else if case .editing(let id, _) = mode { store.items.firstIndex { $0.id == id } } else { nil } }

    private func focusInput() { mode = .input; DispatchQueue.main.async { inputFocused = true } }
    private func addInput() { if store.addTitles(from: input) > 0 { input = "" }; focusInput() }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let modifierFlags = event.modifierFlags.intersection([.command, .option, .control])
        guard modifierFlags.isEmpty else { return false }

        switch event.keyCode {
        case 53:
            handleEscape()
            return true
        case 125:
            handleDown()
            return true
        case 126:
            handleUp()
            return true
        case 36, 76:
            return handleReturn()
        case 40:
            return handleLetterK()
        case 14:
            return handleLetterE()
        default:
            return false
        }
    }

    private func handleEscape() {
        switch mode {
        case .input: close()
        case .selection: focusInput()
        case .editing(let id, _): if let i = store.items.firstIndex(where: { $0.id == id }) { mode = .selection(index: i) } else { focusInput() }
        }
    }

    private func handleDown() {
        switch mode {
        case .input: if !store.items.isEmpty { mode = .selection(index: 0); inputFocused = false }
        case .selection(let i): mode = .selection(index: min(i + 1, store.items.count - 1))
        case .editing: break
        }
    }

    private func handleUp() {
        guard case .selection(let i) = mode else { return }
        mode = .selection(index: max(i - 1, 0))
    }

    private func handleReturn() -> Bool {
        switch mode {
        case .input:
            addInput()
            return true
        case .selection(let i):
            if store.items.indices.contains(i) { store.toggleActive(id: store.items[i].id) }
            return true
        case .editing(let id, let draft):
            saveEdit(id: id, draft: draft)
            return true
        }
    }

    private func handleLetterK() -> Bool {
        guard case .selection(let i) = mode, store.items.indices.contains(i) else { return false }
        let id = store.items[i].id
        store.knockOut(id: id)
        if store.items.isEmpty { focusInput() }
        else { mode = .selection(index: min(i, store.items.count - 1)) }
        return true
    }

    private func handleLetterE() -> Bool {
        guard case .selection(let i) = mode, store.items.indices.contains(i) else { return false }
        let item = store.items[i]
        mode = .editing(id: item.id, draft: item.title)
        return true
    }

    private func saveEdit(id: UUID, draft: String) {
        guard store.edit(id: id, title: draft), let i = store.items.firstIndex(where: { $0.id == id }) else { return }
        mode = .selection(index: i)
    }

    private func keepSelectionValid(_ newItems: [KnockItem]) {
        if case .selection(let i) = mode, newItems.isEmpty || !newItems.indices.contains(i) {
            newItems.isEmpty ? focusInput() : (mode = .selection(index: newItems.count - 1))
        }
    }
}
