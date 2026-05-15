import Foundation

struct KnockItemUndoSnapshot: Identifiable, Equatable {
    let id = UUID()
    let item: KnockItem
    let previousIndex: Int
    let knockedOutAt: Date
}
