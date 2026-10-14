import Photos
import SwiftUI

@main
struct KaydirSilApp: App {
    @State private var depo = FotoDeposu()

    var body: some Scene {
        WindowGroup {
            KokEkran()
                .environment(depo)
                .tint(.indigo)
        }
    }
}

struct KokEkran: View {
    @Environment(FotoDeposu.self) private var depo

    var body: some View {
        switch depo.izin {
        case .authorized, .limited:
            AnaEkran()
        case .notDetermined:
            IzinEkrani()
        default:
            IzinYokEkrani()
        }
    }
}

struct IzinEkrani: View {
    @Environment(FotoDeposu.self) private var depo

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 10)
            OrnekKartlar()
                .frame(height: 300)
            VStack(spacing: 10) {
                Text("Galerini kaydırarak\ntemizle")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .multilineTextAlignment(.center)
                Text("Günde bir dakika, binlerce gereksiz fotoğraf daha az.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 14) {
                Satir(ikon: "arrow.left", renk: Tema.silRengi, metin: "Sola kaydır: sil")
                Satir(ikon: "arrow.right", renk: Tema.tutRengi, metin: "Sağa kaydır: kalsın")
                Satir(ikon: "lock.fill", renk: .indigo, metin: "Fotoğrafların telefonundan hiçbir yere gitmez")
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .kartYuzeyi()
            Spacer(minLength: 0)
            Button {
                Task { await depo.izinIste() }
            } label: {
                Text("Başlayalım")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Tema.anaGradyan, in: Capsule())
                    .shadow(color: .purple.opacity(0.35), radius: 14, y: 6)
            }
            .buttonStyle(BasmaStili())
        }
        .padding(24)
        .background(Color(.systemGroupedBackground))
    }

    /// Kendi kendine sağa sola kayan örnek kartlar.
    private struct OrnekKartlar: View {
        private let renkler: [[Color]] = [[.orange, .pink], [.teal, .blue], [.green, .mint], [.purple, .indigo]]

        private let testModu = ProcessInfo.processInfo.arguments.contains("-UITest")

        var body: some View {
            if testModu {
                deste(0)
            } else {
                canli
            }
        }

        private var canli: some View {
            TimelineView(.periodic(from: .now, by: 1.6)) { zaman in
                let t = Int(zaman.date.timeIntervalSinceReferenceDate / 1.6)
                ZStack {
                    deste(t)
                        .id(t)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .offset(x: t % 2 == 0 ? 320 : -320).combined(with: .opacity)
                        ))
                }
                .animation(.easeInOut(duration: 0.45), value: t)
            }
        }

        private func deste(_ t: Int) -> some View {
            ZStack {
                ForEach((0..<3).reversed(), id: \.self) { i in
                    let r = renkler[(t + i) % renkler.count]
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(colors: r, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay {
                            Image(systemName: ["mountain.2.fill", "sun.max.fill", "leaf.fill", "camera.fill"][(t + i) % 4])
                                .font(.system(size: 54))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(width: 200, height: 270)
                        .scaleEffect(1 - CGFloat(i) * 0.06)
                        .offset(y: CGFloat(i) * 14)
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
                }
            }
        }
    }

    private struct Satir: View {
        let ikon: String
        let renk: Color
        let metin: String

        var body: some View {
            HStack(spacing: 14) {
                Image(systemName: ikon)
                    .font(.title3.bold())
                    .foregroundStyle(renk)
                    .frame(width: 30)
                Text(metin)
            }
        }
    }
}

struct IzinYokEkrani: View {
    var body: some View {
        ContentUnavailableView {
            Label("Fotoğraflara erişim yok", systemImage: "photo.badge.exclamationmark")
        } description: {
            Text("Galerini temizleyebilmem için Ayarlar'dan fotoğraf erişimine izin vermelisin.")
        } actions: {
            Button("Ayarlar'ı aç") {
                if let adres = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(adres)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
