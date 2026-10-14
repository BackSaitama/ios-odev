import Photos
import SwiftUI

struct KaydirEkrani: View {
    let kaynak: Kaynak
    @Environment(FotoDeposu.self) private var depo
    @State private var kayma: CGSize = .zero
    @State private var ucuyor = false
    @State private var copAcik = false

    private let esik: CGFloat = 110

    var body: some View {
        VStack(spacing: 18) {
            if !depo.kuyruk.isEmpty {
                ProgressView(value: Double(depo.siradaki), total: Double(depo.kuyruk.count))
                    .tint(.indigo)
                    .padding(.horizontal)
            }

            ZStack {
                if depo.yukleniyor {
                    ProgressView("Hazırlanıyor…")
                } else if let varlik = depo.simdiki {
                    if let sonraki = depo.sonraki {
                        FotoKarti(varlik: sonraki)
                            .scaleEffect(0.94)
                            .opacity(0.7)
                    }
                    FotoKarti(varlik: varlik)
                        .overlay { KararEtiketi(kayma: kayma.width, esik: esik) }
                        .offset(x: kayma.width, y: kayma.height * 0.3)
                        .rotationEffect(.degrees(Double(kayma.width / 22)))
                        .gesture(surukle)
                        .id(varlik.localIdentifier)
                } else {
                    BittiGorunumu(copAc: { copAcik = true })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)

            if depo.simdiki != nil {
                HStack(spacing: 34) {
                    YuvarlakDugme(ikon: "xmark", renk: .red, boyut: 68) { gonder(.sil) }
                    YuvarlakDugme(ikon: "arrow.uturn.backward", renk: .gray, boyut: 50) {
                        withAnimation(.snappy) { depo.geriAl() }
                    }
                    .disabled(!depo.geriAlinabilir)
                    .opacity(depo.geriAlinabilir ? 1 : 0.4)
                    YuvarlakDugme(ikon: "heart.fill", renk: .green, boyut: 68) { gonder(.tut) }
                }
                .padding(.bottom, 8)
            }
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
            kayma = CGSize(width: karar == .sil ? -700 : 700, height: kayma.height)
        }
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            depo.karar(karar)
            kayma = .zero
            ucuyor = false
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

                LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 4) {
                    if let tarih = varlik.creationDate {
                        Text(tarih.formatted(.dateTime.day().month(.wide).year()))
                            .font(.title3.bold())
                    }
                    HStack(spacing: 12) {
                        if varlik.mediaType == .video {
                            Label(sure(varlik.duration), systemImage: "play.fill")
                        }
                        Label(depo.boyut(varlik).okunur, systemImage: "internaldrive")
                    }
                    .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        }
    }

    private func sure(_ saniye: Double) -> String {
        let s = Int(saniye.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

struct VarlikGorseli: View {
    let varlik: PHAsset
    let boyut: CGSize
    @Environment(\.displayScale) private var olcek
    @State private var resim: UIImage?

    var body: some View {
        ZStack {
            Rectangle().fill(Color(.secondarySystemBackground))
            if let resim {
                Image(uiImage: resim)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .task(id: varlik.localIdentifier) {
            let hedef = CGSize(width: boyut.width * olcek, height: boyut.height * olcek)
            resim = await Gorsel.yukle(varlik, boyut: hedef)
        }
    }
}

private struct KararEtiketi: View {
    let kayma: CGFloat
    let esik: CGFloat

    var body: some View {
        ZStack {
            Etiket(metin: "SİL", renk: .red, aci: 14)
                .opacity(Double(min(max(-kayma / esik, 0), 1)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            Etiket(metin: "KALSIN", renk: .green, aci: -14)
                .opacity(Double(min(max(kayma / esik, 0), 1)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(28)
        .allowsHitTesting(false)
    }

    private struct Etiket: View {
        let metin: String
        let renk: Color
        let aci: Double

        var body: some View {
            Text(metin)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(renk)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(renk, lineWidth: 5))
                .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                .rotationEffect(.degrees(aci))
        }
    }
}

private struct YuvarlakDugme: View {
    let ikon: String
    let renk: Color
    let boyut: CGFloat
    let eylem: () -> Void

    var body: some View {
        Button(action: eylem) {
            Image(systemName: ikon)
                .font(.system(size: boyut * 0.38, weight: .bold))
                .foregroundStyle(renk)
                .frame(width: boyut, height: boyut)
                .background(Color(.systemBackground), in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

private struct BittiGorunumu: View {
    @Environment(FotoDeposu.self) private var depo
    let copAc: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.indigo)
            Text(depo.kuyruk.isEmpty ? "Burada bakılacak bir şey kalmadı" : "Bu bölüm bitti!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            if depo.copSayisi > 0 {
                Text("Çöp kutusunda \(depo.copSayisi) öğe bekliyor.")
                    .foregroundStyle(.secondary)
                Button("Çöp kutusunu aç", action: copAc)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
            }
        }
        .padding()
    }
}
