import SwiftUI

struct RailView: View {
    @ObservedObject var store: KnockItemStore
    @State private var draggingID: UUID?

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .trailing, spacing: 8) {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .trailing, spacing: 8) {
                        ForEach(store.items) { item in
                            RailItemView(store: store, item: item)
                                .opacity(draggingID == item.id ? 0.55 : 1)
                                .draggable(item) { railDragPreview(item.title) }
                                .dropDestination(for: KnockItem.self) { dropped, _ in
                                    guard let first = dropped.first, let target = store.items.firstIndex(where: { $0.id == item.id }) else { return false }
                                    store.moveItem(id: first.id, toIndex: target)
                                    draggingID = nil
                                    return true
                                } isTargeted: { targeted in
                                    if targeted { draggingID = item.id }
                                }
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

    private func railDragPreview(_ title: String) -> some View {
        Text(title).lineLimit(1).padding(8).background(.black.opacity(0.8), in: Capsule()).foregroundStyle(.white)
    }
}
