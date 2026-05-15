import SwiftUI

struct UndoToastView: View {
    @ObservedObject var store: KnockItemStore

    var body: some View {
        if store.lastUndo != nil {
            HStack(spacing: 10) {
                Text("Knocked out.")
                    .foregroundStyle(.white)
                Button("Undo") { store.undoLastKnockOut() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.semibold)
            }
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.86), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.14)))
            .transition(.scale.combined(with: .opacity))
        }
    }
}
