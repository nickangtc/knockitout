import SwiftUI

struct CelebrationView: View {
    @State private var burst = false
    private let colors: [Color] = [.yellow, .orange, .pink, .cyan, .green, .purple]

    var body: some View {
        ZStack {
            ForEach(0..<14, id: \.self) { index in
                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: CGFloat(5 + index % 4), height: CGFloat(5 + index % 4))
                    .offset(burst ? offset(for: index) : .zero)
                    .opacity(burst ? 0 : 1)
            }
            Text("All knocked out.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(8)
                .background(.black.opacity(0.72), in: Capsule())
                .offset(y: 42)
                .opacity(burst ? 0 : 1)
        }
        .frame(width: 180, height: 140)
        .onAppear { withAnimation(.easeOut(duration: 1.15)) { burst = true } }
    }

    private func offset(for index: Int) -> CGSize {
        let angle = Double(index) / 14.0 * Double.pi * 2
        let radius = CGFloat(34 + (index % 5) * 9)
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}
