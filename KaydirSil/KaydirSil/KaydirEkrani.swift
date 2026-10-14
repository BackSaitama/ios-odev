import Photos
import SwiftUI

struct KaydirEkrani: View {
    let kaynak: Kaynak
    @Environment(FotoDeposu.self) private var depo
    @State private var kayma: CGSize = .zero
    @State private var ucuyor = false
    @State private var copAcik = false

    private let esik: CGFloat = 110

    /// -1 (tam sil) ... 0 ... 1 (tam kalsın)
    private var yon: Double { Double(max(-1, min(1, kayma.width / esik))) }

    var body: some View {
        VStack(spacing: 16) {
            if !depo.kuyruk.isEmpty && depo.simdiki != nil {
                UstBilgi()
                    .padding(.horizontal, 18)
            }

            ZStack {
                if depo.yukleniyor {
                    VStack(spacing: 14) {
                        ProgressView().controlSize(.large)
                        Text("Fotoğraflar hazırlanıyor…").foregroundStyle(.secondary)
                    }
                } else if let varlik = depo.simdiki {
                    if let ucuncu = depo.ucuncu {
                        FotoKarti(varlik: ucuncu)
                            .scaleEffect(0.88)
                            .offset(y: 26)
                            .opacity(0.5)
                    }
                    if let sonraki = depo.sonraki {
                        FotoKarti(varlik: sonraki)
                            .scaleEffect(0.94 + 0.06 * abs(yon))
                            .offset(y: 13 - 13 * abs(yon))
                            .opacity(0.75 + 0.25 * abs(yon))
                    }
                    FotoKarti(varlik: varlik)
                        .overlay { KararEtiketi(yon: yon) }
                        .offset(x: kayma.width, y: kayma.height * 0.3)
                        .rotationEffect(.degrees(Double(kayma.width / 20)), anchor: .bottom)
                        .gesture(surukle)
                        .id(varlik.localIdentifier)
                        .transition(.identity)
                } else {
                    BittiGorunumu(copAc: { copAcik = true })
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 18)
            .padding(.bottom, 14)

            if depo.simdiki != nil {
                HStack(spacing: 28) {
                    KararDugmesi(ikon: "xmark", renk: Tema.silRengi, boyut: 70, vurgu: max(0, -yon)) { gonder(.sil) }
                    KararDugmesi(ikon: "arrow.uturn.backward", renk: .secondary, boyut: 52, vurgu: 0) {
                        withAnimation(.snappy) { depo.geriAl() }
                    }
                    .disabled(!depo.geriAlinabilir)
                    .opacity(depo.geriAlinabilir ? 1 : 0.35)
                    KararDugmesi(ikon: "heart.fill", renk: Tema.tutRengi, boyut: 70, vurgu: max(0, yon)) { gonder(.tut) }
                }
                .padding(.bottom, 10)
            }
        }
        .background {
            ZStack {
                Color(.systemGroupedBackground)
                RadialGradient(colors: [Tema.silRengi.opacity(0.35 * max(0, -yon)), .clear],
                               center: .leading, startRadius: 10, endRadius: 420)
                RadialGradient(colors: [Tema.tutRengi.opacity(0.35 * max(0, yon)), .clear],
                               center: .trailing, startRadius: 10, endRadius: 420)
            }
            .ignoresSafeArea()
        }
        .navigationTitle(kaynak.baslik)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CopDugmesi { copAcik = true }
            }
        }
        .sheet(isPresented: $copAcik) { CopKutusu() }
        .sensoryFeedback(.impact(weight: .light), trigger: depo.siradaki)
        .sensoryFeedback(.selection, trigger: abs(yon) >= 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: depo.simdiki == nil)
        .task { await depo.baslat(kaynak) }
    }

    private var surukle: some Gesture {
        DragGesture()
            .onChanged { deger in
                guard !ucuyor else { return }
                kayma = deger.translation
            }
            .onEnded { deger in
                guard !ucuyor else { return }
                let x = deger.translation.width + deger.predictedEndTranslation.width * 0.2
                if x < -esik {
                    gonder(.sil)
                } else if x > esik {
                    gonder(.tut)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { kayma = .zero }
                }
            }
    }

    private func gonder(_ karar: Karar) {
        guard !ucuyor, depo.simdiki != nil else { return }
        ucuyor = true
        withAnimation(.easeIn(duration: 0.22)) {
            kayma = CGSize(width: karar == .sil ? -650 : 650, height: kayma.height + 40)
        }
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            depo.karar(karar)
            kayma = .zero
            ucuyor = false
        }
    }
}

private struct UstBilgi: View {
    @Environment(FotoDeposu.self) private var depo

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(min(depo.siradaki + 1, depo.kuyruk.count)) / \(depo.kuyruk.count)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText())
                Spacer()
                HStack(spacing: 6) {
                    Cip(ikon: "heart.fill", renk: Tema.tutRengi, sayi: depo.oturumTutulan)
                    Cip(ikon: "trash.fill", renk: Tema.silRengi, sayi: depo.oturumSilinen)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(Tema.anaGradyan)
                        .frame(width: geo.size.width * CGFloat(depo.siradaki) / CGFloat(max(depo.kuyruk.count, 1)))
                }
            }
            .frame(height: 6)
            .animation(.spring, value: depo.siradaki)
        }
    }

    private struct Cip: View {
        let ikon: String
        let renk: Color
        let sayi: Int

        var body: some View {
            Label("\(sayi)", systemImage: ikon)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(renk)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(renk.opacity(0.14), in: Capsule())
                .contentTransition(.numericText())
        }
    }
}

struct FotoKarti: View {
    let varlik: PHAsset
    @Environment(FotoDeposu.self) private var depo

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                VarlikGorseli(varlik: varlik, boyut: geo.size)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                LinearGradient(colors: [.clear, .clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 8) {
                    if let tarih = varlik.creationDate {
                        Text(tarih.formatted(.dateTime.day().month(.wide).year()))
                            .font(.system(.title2, design: .rounded).weight(.bold))
                        Text(tarih.formatted(.relative(presentation: .named)))
                            .font(.subheadline.weight(.medium))
                            .opacity(0.85)
                    }
                    HStack(spacing: 8) {
                        if varlik.mediaType == .video {
                            Bilgi(ikon: "play.fill", metin: sure(varlik.duration))
                        }
                        if varlik.mediaSubtypes.contains(.photoScreenshot) {
                            Bilgi(ikon: "camera.viewfinder", metin: "Ekran görüntüsü")
                        }
                        Bilgi(ikon: "internaldrive.fill", metin: depo.boyut(varlik).okunur)
                    }
                }
                .foregroundStyle(.white)
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
        }
    }

    private func sure(_ saniye: Double) -> String {
        let s = Int(saniye.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private struct Bilgi: View {
        let ikon: String
        let metin: String

        var body: some View {
            Label(metin, systemImage: ikon)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .environment(\.colorScheme, .dark)
        }
    }
}

struct VarlikGorseli: View {
    let varlik: PHAsset
    let boyut: CGSize
    @Environment(\.displayScale) private var olcek
    @State private var resim: UIImage?

    var body: some View {
        ZStack {
            Rectangle().fill(Color(.tertiarySystemFill))
            if let resim {
                Image(uiImage: resim)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                ProgressView()
            }
        }
        .animation(.easeOut(duration: 0.2), value: resim != nil)
        .task(id: varlik.localIdentifier) {
            let hedef = CGSize(width: boyut.width * olcek, height: boyut.height * olcek)
            resim = await Gorsel.yukle(varlik, boyut: hedef)
        }
    }
}

private struct KararEtiketi: View {
    let yon: Double

    var body: some View {
        ZStack {
            Etiket(metin: "SİL", ikon: "trash.fill", renk: Tema.silRengi, aci: 12)
                .opacity(max(0, -yon))
                .scaleEffect(0.8 + 0.2 * max(0, -yon))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            Etiket(metin: "KALSIN", ikon: "heart.fill", renk: Tema.tutRengi, aci: -12)
                .opacity(max(0, yon))
                .scaleEffect(0.8 + 0.2 * max(0, yon))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(26)
        .allowsHitTesting(false)
    }

    private struct Etiket: View {
        let metin: String
        let ikon: String
        let renk: Color
        let aci: Double

        var body: some View {
            Label(metin, systemImage: ikon)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(renk, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: renk.opacity(0.5), radius: 12)
                .rotationEffect(.degrees(aci))
        }
    }
}

private struct KararDugmesi: View {
    let ikon: String
    let renk: Color
    let boyut: CGFloat
    let vurgu: Double
    let eylem: () -> Void

    var body: some View {
        Button(action: eylem) {
            Image(systemName: ikon)
                .font(.system(size: boyut * 0.36, weight: .heavy))
                .foregroundStyle(vurgu > 0.5 ? Color.white : renk)
                .frame(width: boyut, height: boyut)
                .background {
                    ZStack {
                        Circle().fill(Color(.secondarySystemGroupedBackground))
                        Circle().fill(renk).opacity(vurgu)
                    }
                }
                .scaleEffect(1 + 0.15 * vurgu)
                .shadow(color: (vurgu > 0 ? renk : .black).opacity(vurgu > 0 ? 0.4 : 0.12), radius: 12, y: 5)
        }
        .buttonStyle(BasmaStili())
    }
}

private struct BittiGorunumu: View {
    @Environment(FotoDeposu.self) private var depo
    let copAc: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: depo.kuyruk.isEmpty ? "checkmark.circle.fill" : "sparkles")
                .font(.system(size: 72))
                .foregroundStyle(Tema.anaGradyan)
                .symbolEffect(.bounce, value: depo.simdiki == nil)
            Text(depo.kuyruk.isEmpty ? "Burada bakılacak bir şey kalmadı" : "Bu bölüm bitti!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            if !depo.kuyruk.isEmpty {
                HStack(spacing: 14) {
                    Sayac(sayi: depo.oturumTutulan, ad: "kalsın", renk: Tema.tutRengi)
                    Sayac(sayi: depo.oturumSilinen, ad: "sil", renk: Tema.silRengi)
                }
            }
            if depo.copSayisi > 0 {
                Button(action: copAc) {
                    Label("Çöp kutusunu aç (\(depo.copSayisi))", systemImage: "trash.fill")
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Tema.silRengi)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .kartYuzeyi(kose: 30)
    }

    private struct Sayac: View {
        let sayi: Int
        let ad: String
        let renk: Color

        var body: some View {
            VStack(spacing: 2) {
                Text("\(sayi)")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(renk)
                Text(ad).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            .frame(width: 96)
            .padding(.vertical, 10)
            .background(renk.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
