import SwiftUI

struct WelcomeView: View {
    @State var startAtLogin = true
    let start: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Knock It Out")
                .font(.system(size: 28, weight: .bold))
            Text("Press ⌘⇧K anytime to add or knock out current items. Knock It Out starts automatically when you log in. You can quit or clear items from the menu bar.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Toggle("Start Knock It Out when I log in", isOn: $startAtLogin)
            HStack {
                Spacer()
                Button("Start knocking things out") { start(startAtLogin) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 430)
    }
}
