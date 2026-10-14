import SwiftUI

enum Tema {
    static let anaGradyan = LinearGradient(
        colors: [Color(red: 0.05, green: 0.55, blue: 0.45), Color(red: 0.10, green: 0.42, blue: 0.75), Color(red: 0.30, green: 0.28, blue: 0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let vurgu = Color(red: 0.10, green: 0.55, blue: 0.55)
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
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Aboneliğin baş harfiyle renkli yuvarlak logo.
struct HarfLogo: View {
    let harf: String
    let renk: Color
    var boyut: CGFloat = 46

    var body: some View {
        Text(harf)
            .font(.system(size: boyut * 0.45, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: boyut, height: boyut)
            .background(
                LinearGradient(colors: [renk, renk.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: boyut * 0.3, style: .continuous)
            )
    }
}
