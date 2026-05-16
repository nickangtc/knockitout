import AppKit
import SwiftUI

struct RailItemView: View {
    @ObservedObject var store: KnockItemStore
    let item: KnockItem
    var isDragLifted: Bool = false
    var onDragBegan: (() -> Void)?
    var onDragMoved: ((CGFloat) -> Void)?
    var onDragEnded: (() -> Void)?
    @State private var hovering = false
    @State private var editing = false
    @State private var draft = ""
    @State private var clickPulse = false
    @State private var koHovering = false
    @State private var activationBorderProgress: CGFloat = 0
    @State private var activationBorderOpacity: Double = 0
    @State private var rainbowHueRotation: Double = 0
    @State private var isActivationBorderRunning = false
    @State private var activationBorderRunID = UUID()
    @FocusState private var focused: Bool

    var body: some View {
        railElement
        .scaleEffect(isDragLifted ? 1.05 : (clickPulse ? 1.07 : 1.0), anchor: .trailing)
        .shadow(color: .black.opacity(isDragLifted ? 0.25 : 0), radius: isDragLifted ? 12 : 0, y: isDragLifted ? 4 : 0)
        .frame(height: railElementHeight)
        .help(item.title)
        .accessibilityLabel(item.title)
        .contentShape(Rectangle())
        .pointingHandOnHover()
        .overlay(alignment: .trailing) {
            railClickSurface
        }
        .onHover { isHovering in
            if !isDragLifted {
                withAnimation(.easeInOut(duration: 0.16)) { hovering = isHovering }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: hovering)
        .animation(.easeInOut(duration: 0.18), value: item.isActive)
        .animation(.easeOut(duration: 0.10), value: clickPulse)
        .animation(.easeInOut(duration: 0.2), value: isDragLifted)
    }

    private var isExpanded: Bool { hovering || editing || item.isActive }

    private var expandedWidth: CGFloat {
        if editing { return 286 }
        let estimatedTitleWidth = min(CGFloat(item.title.count) * 7.4 + 12, 170)
        return min(max(estimatedTitleWidth + 76, 136), 286)
    }

    private var expandedHeight: CGFloat {
        42
    }

    private var titleWidth: CGFloat {
        max(44, expandedWidth - 76)
    }

    private var railElementHeight: CGFloat {
        max(expandedHeight, 50) + 6
    }

    private var railElement: some View {
        ZStack(alignment: .trailing) {
            expandingCapsule
                .frame(width: isExpanded ? expandedWidth : 50, height: isExpanded ? expandedHeight : 50, alignment: .trailing)
                .clipShape(Capsule())

            pillContent
                .opacity(isExpanded ? 1 : 0)
                .frame(width: expandedWidth, height: expandedHeight, alignment: .trailing)
                .allowsHitTesting(isExpanded)

        }
        .frame(width: isExpanded ? expandedWidth : 50, height: railElementHeight, alignment: .trailing)
        .clipped()
    }

    private var railClickSurface: some View {
        HStack(spacing: 0) {
            RailClickSurface(
                onSingleClick: {
                    let shouldRunActivationBorder = !item.isActive
                    performClickPulse()
                    withAnimation(.easeInOut(duration: 0.10)) { store.toggleActive(id: item.id) }
                    if shouldRunActivationBorder {
                        runActivationBorder()
                    } else {
                        stopActivationBorder()
                    }
                },
                onDoubleClick: {
                    performClickPulse()
                    beginEditing()
                },
                onDragBegan: onDragBegan,
                onDragMoved: onDragMoved,
                onDragEnded: onDragEnded
            )
            .frame(width: isExpanded ? max(44, expandedWidth - 50) : 50, height: railElementHeight)

            if isExpanded {
                Color.clear.frame(width: 50, height: railElementHeight)
            }
        }
        .frame(width: isExpanded ? expandedWidth : 50, height: railElementHeight, alignment: .trailing)
    }

    private var expandingCapsule: some View {
        let color = auraColor(for: item)
        return Capsule()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.96), color.opacity(0.72), color.opacity(isExpanded ? 0.54 : 0.86)],
                    startPoint: .trailing,
                    endPoint: .leading
                )
            )
            .overlay(Capsule().stroke(Color.white.opacity(borderOpacity), lineWidth: item.isActive && !isActivationBorderRunning ? 2.6 : 1))
            .overlay(activationBorder)
            .shadow(color: color.opacity(item.isActive ? 0.72 : 0.38), radius: item.isActive ? 20 : 12)
            .shadow(color: color.opacity(0.28), radius: 8)
    }

    private var activationBorder: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) / 2
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .trim(from: 0, to: activationBorderProgress)
                .stroke(
                    AngularGradient(
                        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round)
                )
                .hueRotation(.degrees(rainbowHueRotation))
                .opacity(activationBorderOpacity)
                .shadow(color: .white.opacity(activationBorderOpacity * 0.55), radius: 5)
        }
        .allowsHitTesting(false)
    }

    private var borderOpacity: Double {
        if item.isActive { return isActivationBorderRunning ? 0 : 0.86 }
        return 0.34
    }

    private var bubble: some View {
        let color = auraColor(for: item)
        return ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 44, height: 44)
                .blur(radius: 9)
            Circle()
                .fill(color.opacity(0.34))
                .frame(width: 34, height: 34)
                .blur(radius: 5)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.92), color.opacity(0.92), color.opacity(0.62)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 18
                    )
                )
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.white.opacity(item.isActive ? 0.95 : 0.36), lineWidth: item.isActive ? 2.8 : 1.1))
                .overlay(activeRing(color: color))
                .overlay(activeSpark)
                .shadow(color: color.opacity(0.55), radius: 9, x: 0, y: 0)
                .shadow(color: color.opacity(item.isActive ? 0.88 : 0.38), radius: item.isActive ? 22 : 10, x: 0, y: 0)
                .scaleEffect(item.isActive ? 1.08 : 1.0)
        }
        .frame(width: 50, height: 48)
    }

    @ViewBuilder
    private func activeRing(color: Color) -> some View {
        if item.isActive {
            Circle()
                .stroke(color.opacity(0.95), lineWidth: 3)
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(Color.white.opacity(0.65), lineWidth: 1).frame(width: 46, height: 46))
                .shadow(color: color.opacity(0.85), radius: 12)
        }
    }

    @ViewBuilder
    private var activeSpark: some View {
        if item.isActive {
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 6, height: 6)
                .offset(x: 10, y: -10)
                .shadow(color: .white.opacity(0.9), radius: 4)
        }
    }

    private var pillContent: some View {
        HStack(spacing: 9) {
            if editing {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .frame(width: 190)
                    .onSubmit { saveEdit() }
                    .onKeyPress(.escape) { editing = false; return .handled }
                    .onAppear { focused = true }
                    .onChange(of: focused) { _, isFocused in
                        if !isFocused && editing {
                            if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { focused = true }
                            else { saveEdit() }
                        }
                    }
            } else {
                Text(item.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: titleWidth, alignment: .leading)
            }
            Button("KO") { store.knockOut(id: item.id) }
                .buttonStyle(.plain)
                .font(.caption.weight(.bold))
                .foregroundStyle(koHovering ? Color.black.opacity(0.78) : .white)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(koHovering ? Color.white.opacity(0.82) : Color.black.opacity(0.16), in: Capsule())
                .scaleEffect(koHovering ? 1.08 : 1)
                .onHover { hovering in
                    koHovering = hovering
                    if hovering { NSCursor.disappearingItem.push() }
                    else { NSCursor.pop() }
                }
                .animation(.easeInOut(duration: 0.10), value: koHovering)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(width: expandedWidth, height: expandedHeight, alignment: .trailing)
    }

    private func auraColor(for item: KnockItem) -> Color {
        let palette: [Color] = [
            Color(red: 0.64, green: 0.78, blue: 0.96),
            Color(red: 0.76, green: 0.68, blue: 0.93),
            Color(red: 0.88, green: 0.67, blue: 0.78),
            Color(red: 0.70, green: 0.86, blue: 0.74),
            Color(red: 0.92, green: 0.78, blue: 0.55),
            Color(red: 0.62, green: 0.84, blue: 0.86),
            Color(red: 0.82, green: 0.72, blue: 0.60),
            Color(red: 0.73, green: 0.76, blue: 0.91),
            Color(red: 0.86, green: 0.66, blue: 0.58),
            Color(red: 0.66, green: 0.80, blue: 0.68)
        ]
        let index = store.colorIndex(for: item) % palette.count
        return palette[index]
    }

    private func performClickPulse() {
        withAnimation(.easeOut(duration: 0.08)) { clickPulse = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            withAnimation(.easeInOut(duration: 0.14)) { clickPulse = false }
        }
    }

    private func runActivationBorder() {
        let runID = UUID()
        activationBorderRunID = runID
        activationBorderProgress = 0
        activationBorderOpacity = 1
        rainbowHueRotation = 0
        isActivationBorderRunning = true

        withAnimation(.linear(duration: 0.58)) {
            activationBorderProgress = 1
            rainbowHueRotation = 360
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            guard activationBorderRunID == runID else { return }
            withAnimation(.easeOut(duration: 0.16)) {
                isActivationBorderRunning = false
            }
            withAnimation(.easeOut(duration: 0.24)) {
                activationBorderOpacity = 0
            }
        }
    }

    private func stopActivationBorder() {
        activationBorderRunID = UUID()
        isActivationBorderRunning = false
        withAnimation(.easeOut(duration: 0.12)) {
            activationBorderOpacity = 0
        }
    }

    private func beginEditing() {
        NSApp.activate(ignoringOtherApps: true)
        draft = item.title
        withAnimation(.easeInOut(duration: 0.16)) {
            editing = true
            hovering = true
        }
        DispatchQueue.main.async { focused = true }
    }

    private func saveEdit() {
        if store.edit(id: item.id, title: draft) { editing = false }
    }
}
