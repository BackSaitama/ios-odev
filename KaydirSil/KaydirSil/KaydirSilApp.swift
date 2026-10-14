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
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "hand.draw.fill")
                .font(.system(size: 80))
                .foregroundStyle(.indigo)
            Text("Galerini kaydırarak temizle")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 14) {
                Satir(ikon: "arrow.left", renk: .red, metin: "Sola kaydır: sil")
                Satir(ikon: "arrow.right", renk: .green, metin: "Sağa kaydır: kalsın")
                Satir(ikon: "lock.fill", renk: .indigo, metin: "Fotoğrafların telefonundan hiçbir yere gitmez")
            }
            .padding(.horizontal)
            Spacer()
            Button {
                Task { await depo.izinIste() }
            } label: {
                Text("Başlayalım")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
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
