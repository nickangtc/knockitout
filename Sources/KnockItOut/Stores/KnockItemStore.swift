import AppKit
import Foundation

@MainActor
final class KnockItemStore: ObservableObject {
    @Published private(set) var items: [KnockItem] = []
    @Published var lastUndo: KnockItemUndoSnapshot?

    private var colorIndexesByID: [UUID: Int] = [:]
    private let paletteCount = 10

    var onFinalKnockOut: ((CGPoint?) -> Void)?
    var onItemsChanged: (() -> Void)?

    private var undoWorkItem: DispatchWorkItem?

    func load() {
        do {
            try PersistencePaths.ensureDirectory()
            let url = PersistencePaths.itemsURL
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            items = try decoder.decode([KnockItem].self, from: data)
            loadAppearance()
            ensureColorIndexesForCurrentItems()
            saveAppearance()
            onItemsChanged?()
        } catch {
            NSLog("Knock It Out load error: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func addTitles(from rawInput: String) -> Int {
        let titles = sanitizedTitles(from: rawInput)
        guard !titles.isEmpty else { return 0 }
        let newItems = titles.map { KnockItem(title: $0) }
        for item in newItems {
            colorIndexesByID[item.id] = nextAvailableColorIndex()
            items.append(item)
        }
        saveAndNotify()
        return titles.count
    }

    @discardableResult
    func edit(id: UUID, title: String) -> Bool {
        guard let trimmed = sanitizedTitle(title), let index = items.firstIndex(where: { $0.id == id }) else { return false }
        items[index].title = trimmed
        saveAndNotify()
        return true
    }

    func toggleActive(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isActive.toggle()
        saveAndNotify()
    }

    func knockOut(id: UUID, anchor: CGPoint? = nil) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let wasFinal = items.count == 1
        let item = items.remove(at: index)
        lastUndo = KnockItemUndoSnapshot(item: item, previousIndex: index, knockedOutAt: Date())
        scheduleUndoExpiry()
        saveAndNotify()
        if wasFinal { onFinalKnockOut?(anchor) }
    }

    func undoLastKnockOut() {
        guard let snapshot = lastUndo else { return }
        let insertionIndex = min(max(snapshot.previousIndex, 0), items.count)
        if colorIndexesByID[snapshot.item.id] == nil {
            colorIndexesByID[snapshot.item.id] = nextAvailableColorIndex()
        }
        items.insert(snapshot.item, at: insertionIndex)
        clearUndoTimer()
        lastUndo = nil
        saveAndNotify()
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        saveAndNotify()
    }

    func moveItem(id: UUID, toIndex: Int) {
        guard let from = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: from)
        let adjusted = min(max(toIndex, 0), items.count)
        items.insert(item, at: adjusted)
        saveAndNotify()
    }

    func clearAll() {
        items.removeAll()
        colorIndexesByID.removeAll()
        clearUndoTimer()
        lastUndo = nil
        saveAndNotify()
    }

    private func sanitizedTitles(from rawInput: String) -> [String] {
        rawInput.components(separatedBy: .newlines).compactMap(sanitizedTitle)
    }

    private func sanitizedTitle(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(200))
    }

    private func saveAndNotify() {
        save()
        onItemsChanged?()
    }

    func colorIndex(for item: KnockItem) -> Int {
        if let index = colorIndexesByID[item.id] { return index }
        return abs(item.id.uuidString.hashValue) % paletteCount
    }

    private func save() {
        do {
            try PersistencePaths.ensureDirectory()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(items)
            try data.write(to: PersistencePaths.itemsURL, options: .atomic)
            saveAppearance()
        } catch {
            NSLog("Knock It Out save error: \(error.localizedDescription)")
        }
    }

    private func loadAppearance() {
        do {
            let url = PersistencePaths.appearanceURL
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let data = try Data(contentsOf: url)
            let raw = try JSONDecoder().decode([String: Int].self, from: data)
            colorIndexesByID = Dictionary(uniqueKeysWithValues: raw.compactMap { key, value in
                guard let id = UUID(uuidString: key) else { return nil }
                return (id, abs(value) % paletteCount)
            })
        } catch {
            NSLog("Knock It Out appearance load error: \(error.localizedDescription)")
        }
    }

    private func saveAppearance() {
        do {
            let currentIDs = Set(items.map(\.id))
            let currentAndUndoIDs = lastUndo.map { currentIDs.union([$0.item.id]) } ?? currentIDs
            colorIndexesByID = colorIndexesByID.filter { currentAndUndoIDs.contains($0.key) }
            let raw = Dictionary(uniqueKeysWithValues: colorIndexesByID.map { ($0.key.uuidString, $0.value) })
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(raw)
            try data.write(to: PersistencePaths.appearanceURL, options: .atomic)
        } catch {
            NSLog("Knock It Out appearance save error: \(error.localizedDescription)")
        }
    }

    private func ensureColorIndexesForCurrentItems() {
        for item in items where colorIndexesByID[item.id] == nil {
            colorIndexesByID[item.id] = nextAvailableColorIndex()
        }
    }

    private func nextAvailableColorIndex() -> Int {
        let used = Dictionary(grouping: items.compactMap { colorIndexesByID[$0.id] }, by: { $0 }).mapValues(\.count)
        return (0..<paletteCount).min { lhs, rhs in
            let lhsCount = used[lhs, default: 0]
            let rhsCount = used[rhs, default: 0]
            return lhsCount == rhsCount ? lhs < rhs : lhsCount < rhsCount
        } ?? 0
    }

    private func scheduleUndoExpiry() {
        clearUndoTimer()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.lastUndo = nil
                self.saveAppearance()
                self.onItemsChanged?()
            }
        }
        undoWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
    }

    private func clearUndoTimer() {
        undoWorkItem?.cancel()
        undoWorkItem = nil
    }
}
