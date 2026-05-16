import SwiftUI

struct RailView: View {
    @ObservedObject var store: KnockItemStore
    @State private var draggingItemID: UUID?
    @State private var dragOffset: CGFloat = 0
    @State private var sourceIndex: Int = 0
    @State private var currentDestIndex: Int = 0

    private let itemSlotHeight: CGFloat = 64

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .trailing, spacing: 8) {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .trailing, spacing: 8) {
                        ForEach(store.items) { item in
                            let isDragging = draggingItemID == item.id
                            RailItemView(
                                store: store,
                                item: item,
                                isDragLifted: isDragging,
                                onDragBegan: { beginDrag(item: item) },
                                onDragMoved: { delta in updateDrag(delta: delta) },
                                onDragEnded: { endDrag() }
                            )
                            .offset(y: isDragging ? dragOffset : shiftOffset(for: item))
                            .zIndex(isDragging ? 1 : 0)
                        }
                    }
                }
                .frame(maxHeight: max(66, proxy.size.height - (store.lastUndo == nil ? 16 : 70)))

                if store.lastUndo != nil {
                    UndoToastView(store: store)
                        .padding(.trailing, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.vertical, 8)
            .padding(.trailing, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .animation(.easeInOut(duration: 0.16), value: store.items)
        .animation(.easeInOut(duration: 0.16), value: store.lastUndo?.id)
    }

    private func beginDrag(item: KnockItem) {
        guard let idx = store.items.firstIndex(where: { $0.id == item.id }) else { return }
        draggingItemID = item.id
        sourceIndex = idx
        currentDestIndex = idx
        dragOffset = 0
    }

    private func updateDrag(delta: CGFloat) {
        dragOffset = delta
        let newDest = clampedDestinationIndex()
        if newDest != currentDestIndex {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                currentDestIndex = newDest
            }
        }
    }

    private func endDrag() {
        let dest = currentDestIndex
        let src = sourceIndex
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if dest != src {
                store.moveItem(id: store.items[src].id, toIndex: dest)
            }
            draggingItemID = nil
            dragOffset = 0
        }
        sourceIndex = 0
        currentDestIndex = 0
    }

    private func clampedDestinationIndex() -> Int {
        let rawDest = sourceIndex + Int(round(dragOffset / itemSlotHeight))
        return min(max(rawDest, 0), store.items.count - 1)
    }

    private func shiftOffset(for item: KnockItem) -> CGFloat {
        guard let dragID = draggingItemID,
              dragID != item.id,
              let thisIdx = store.items.firstIndex(where: { $0.id == item.id }) else { return 0 }

        if sourceIndex < currentDestIndex && thisIdx > sourceIndex && thisIdx <= currentDestIndex {
            return -itemSlotHeight
        } else if sourceIndex > currentDestIndex && thisIdx >= currentDestIndex && thisIdx < sourceIndex {
            return itemSlotHeight
        }
        return 0
    }
}
