import SwiftUI

enum Tema {
    static let anaGradyan = LinearGradient(
        colors: [Color(red: 0.36, green: 0.34, blue: 0.95), Color(red: 0.62, green: 0.30, blue: 0.93), Color(red: 0.93, green: 0.33, blue: 0.62)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let silRengi = Color(red: 1.0, green: 0.27, blue: 0.33)
    static let tutRengi = Color(red: 0.20, green: 0.80, blue: 0.45)
    static let kose: CGFloat = 22
}

/// Kart görünümlü yüzey (açık ve koyu temada uyumlu).
struct KartYuzeyi: ViewModifier {
    var kose: CGFloat = Tema.kose

    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: kose, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

extension View {
    func kartYuzeyi(kose: CGFloat = Tema.kose) -> some View { modifier(KartYuzeyi(kose: kose)) }
}

/// Basmaya tepki veren yumuşak düğme stili.
struct BasmaStili: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Halka şeklinde ilerleme göstergesi.
struct IlerlemeHalkasi: View {
    let deger: Double
    var kalinlik: CGFloat = 10

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.25), lineWidth: kalinlik)
            Circle()
                .trim(from: 0, to: deger)
                .stroke(.white, style: StrokeStyle(lineWidth: kalinlik, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("%\(Int((deger * 100).rounded()))")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                Text("galeri")
                    .font(.caption2.weight(.semibold))
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
        }
        .animation(.spring, value: deger)
    }
}
