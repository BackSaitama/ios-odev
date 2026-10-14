import SwiftUI

struct KararEkrani: View {
    let listeId: UUID
    @Environment(KararDeposu.self) private var depo
    @Environment(\.dismiss) private var geri

    @State private var gosterilen: String?
    @State private var sonuc: Secenek?
    @State private var karar: Karar?
    @State private var hafizaNotu: String?
    @State private var donuyor = false
    @State private var tik = 0
    @State private var duzenleAcik = false

    private var liste: KararListesi? { depo.liste(listeId) }

    var body: some View {
        Group {
            if let liste {
                icerik(liste)
            } else {
                ContentUnavailableView("Liste bulunamadı", systemImage: "questionmark.folder")
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Düzenle") { duzenleAcik = true }
            }
        }
        .sheet(isPresented: $duzenleAcik) {
            if let liste { ListeDuzenle(mevcut: liste) }
        }
        .sensoryFeedback(.selection, trigger: tik)
        .sensoryFeedback(.success, trigger: sonuc?.id)
        .sallaninca { if let liste { kararVer(liste) } }
    }

    private func icerik(_ liste: KararListesi) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text(liste.emoji).font(.system(size: 44))
                    Text(liste.ad)
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 6)

                SonucKarti(metin: gosterilen, bitti: sonuc != nil, donuyor: donuyor)

                if let hafizaNotu, sonuc != nil {
                    Label(hafizaNotu, systemImage: "brain.head.profile")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let karar, !donuyor {
                    PuanCubugu(puan: depo.kararlar.first(where: { $0.id == karar.id })?.puan) { p in
                        withAnimation(.spring) { depo.puanla(karar.id, p) }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Button { kararVer(liste) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "dice.fill")
                            .rotationEffect(.degrees(Double(tik) * 40))
                        Text(sonuc == nil ? "Karar ver" : "Bir daha")
                    }
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Tema.anaGradyan, in: Capsule())
                    .shadow(color: Tema.vurgu.opacity(0.4), radius: 14, y: 6)
                }
                .buttonStyle(BasmaStili())
                .disabled(donuyor || liste.secenekler.isEmpty)
                .accessibilityLabel("Karar ver")

                Label("ya da telefonu salla", systemImage: "iphone.radiowaves.left.and.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                SecenekBulutu(liste: liste, secili: sonuc?.id)

                GecmisListesi(gecmis: Array(depo.gecmis(liste.id).prefix(10)))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: karar?.id)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: donuyor)
        }
    }

    private func kararVer(_ liste: KararListesi) {
        guard !donuyor, let secilen = depo.sec(liste) else { return }
        let not = depo.hafizaNotu(liste, secilen: secilen)
        donuyor = true
        sonuc = nil
        karar = nil
        hafizaNotu = nil
        Task {
            var bekleme = 0.04
            var onceki = ""
            for _ in 0..<16 {
                var aday = liste.secenekler.randomElement()?.ad ?? ""
                if liste.secenekler.count > 1 {
                    while aday == onceki { aday = liste.secenekler.randomElement()?.ad ?? "" }
                }
                onceki = aday
                withAnimation(.snappy(duration: 0.08)) { gosterilen = aday }
                tik += 1
                try? await Task.sleep(for: .seconds(bekleme))
                bekleme *= 1.15
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                gosterilen = secilen.ad
                sonuc = secilen
                hafizaNotu = not
            }
            karar = depo.kaydet(secilen, liste: liste)
            donuyor = false
        }
    }
}

private struct SonucKarti: View {
    let metin: String?
    let bitti: Bool
    let donuyor: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(bitti ? AnyShapeStyle(Tema.anaGradyan) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
                .shadow(color: bitti ? Tema.vurgu.opacity(0.45) : .black.opacity(0.08), radius: bitti ? 22 : 10, y: 8)

            if let metin {
                VStack(spacing: 8) {
                    if bitti {
                        Text("🎉").font(.system(size: 40)).transition(.scale)
                    }
                    Text(metin)
                        .font(.system(size: bitti ? 40 : 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(bitti ? Color.white : Color.primary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .id(metin)
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                                removal: .move(edge: .top).combined(with: .opacity)))
                }
                .padding(24)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundStyle(Tema.anaGradyan)
                    Text("Hazır olduğunda dokun")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 220)
        .scaleEffect(bitti ? 1.03 : 1)
        .clipped()
    }
}

private struct PuanCubugu: View {
    let puan: Int?
    let puanla: (Int) -> Void

    var body: some View {
        if let puan {
            Label(puan > 0 ? "Harika, bunu daha sık önereceğim" : "Tamam, bunu daha az çıkaracağım",
                  systemImage: puan > 0 ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(puan > 0 ? Color.green : Color.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background((puan > 0 ? Color.green : Color.orange).opacity(0.12), in: Capsule())
        } else {
            HStack(spacing: 14) {
                Text("Beğendin mi?")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Dugme(ikon: "hand.thumbsdown.fill", renk: .orange) { puanla(-1) }
                    .accessibilityLabel("Beğenmedim")
                Dugme(ikon: "hand.thumbsup.fill", renk: .green) { puanla(1) }
                    .accessibilityLabel("Beğendim")
            }
            .padding(14)
            .kartYuzeyi(kose: 20)
        }
    }

    private struct Dugme: View {
        let ikon: String
        let renk: Color
        let eylem: () -> Void

        var body: some View {
            Button(action: eylem) {
                Image(systemName: ikon)
                    .font(.title3)
                    .foregroundStyle(renk)
                    .frame(width: 52, height: 44)
                    .background(renk.opacity(0.14), in: Capsule())
            }
            .buttonStyle(BasmaStili())
        }
    }
}

private struct SecenekBulutu: View {
    let liste: KararListesi
    let secili: UUID?

    private let izgara = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Seçenekler")
                .font(.headline)
            LazyVGrid(columns: izgara, alignment: .leading, spacing: 8) {
                ForEach(liste.secenekler) { s in
                    HStack(spacing: 4) {
                        Text(s.ad)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        if s.agirlik > 1.2 {
                            Image(systemName: "heart.fill").font(.caption2).foregroundStyle(.pink)
                        } else if s.agirlik < 0.8 {
                            Image(systemName: "arrow.down").font(.caption2).foregroundStyle(.orange)
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(s.id == secili ? Color.white : Color.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(s.id == secili ? AnyShapeStyle(Tema.anaGradyan) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                                in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GecmisListesi: View {
    let gecmis: [Karar]

    var body: some View {
        if !gecmis.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Geçmiş")
                    .font(.headline)
                VStack(spacing: 0) {
                    ForEach(gecmis) { k in
                        HStack {
                            Text(k.secenekAd).font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(k.tarih.formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let p = k.puan {
                                Image(systemName: p > 0 ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                    .font(.caption)
                                    .foregroundStyle(p > 0 ? Color.green : Color.orange)
                            }
                        }
                        .padding(.vertical, 11)
                        .padding(.horizontal, 14)
                        if k.id != gecmis.last?.id { Divider().padding(.leading, 14) }
                    }
                }
                .kartYuzeyi(kose: 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
