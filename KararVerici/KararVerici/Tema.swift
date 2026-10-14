import SwiftUI

enum Tema {
    static let anaGradyan = LinearGradient(
        colors: [Color(red: 1.0, green: 0.55, blue: 0.10), Color(red: 1.0, green: 0.30, blue: 0.40), Color(red: 0.75, green: 0.25, blue: 0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let vurgu = Color(red: 1.0, green: 0.38, blue: 0.30)

    /// Liste kartları için sıradaki renk çifti.
    static func kartRenkleri(_ i: Int) -> [Color] {
        let ciftler: [[Color]] = [
            [.orange, .pink], [.indigo, .purple], [.teal, .blue], [.green, .mint], [.pink, .purple], [.yellow, .orange],
        ]
        return ciftler[((i % ciftler.count) + ciftler.count) % ciftler.count]
    }
}

struct KartYuzeyi: ViewModifier {
    var kose: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: kose, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

extension View {
    func kartYuzeyi(kose: CGFloat = 22) -> some View { modifier(KartYuzeyi(kose: kose)) }
}

struct BasmaStili: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
