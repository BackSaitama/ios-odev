import SwiftUI

struct AnaEkran: View {
    @Environment(EtkinlikDeposu.self) private var depo
    @State private var yeniAcik = false
    @State private var duzenlenen: Etkinlik?

    private let izgara = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let ilk = depo.yaklasanlar.first {
                        Button { duzenlenen = ilk } label: { BuyukKart(e: ilk, canli: !depo.testModu) }
                            .buttonStyle(BasmaStili())
                    } else if depo.etkinlikler.isEmpty {
                        BosDurum { yeniAcik = true }
                    }

                    if depo.yaklasanlar.count > 1 {
                        Bolum(baslik: "Sırada") {
                            LazyVGrid(columns: izgara, spacing: 14) {
                                ForEach(depo.yaklasanlar.dropFirst()) { e in
                                    Button { duzenlenen = e } label: { KucukKart(e: e) }
                                        .buttonStyle(BasmaStili())
                                        .contextMenu {
                                            Button("Sil", systemImage: "trash", role: .destructive) { withAnimation { depo.sil(e) } }
                                        }
                                }
                            }
                        }
                    }

                    if !depo.gecmistekiler.isEmpty {
                        Bolum(baslik: "Gündür devam eden") {
                            LazyVGrid(columns: izgara, spacing: 14) {
                                ForEach(depo.gecmistekiler) { e in
                                    Button { duzenlenen = e } label: { KucukKart(e: e) }
                                        .buttonStyle(BasmaStili())
                                        .contextMenu {
                                            Button("Sil", systemImage: "trash", role: .destructive) { withAnimation { depo.sil(e) } }
                                        }
                                }
                            }
                        }
                    }

                    if !depo.etkinlikler.isEmpty {
                        Bolum(baslik: "Ana ekran widget'ı") {
                            WidgetOnizleme()
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Geri Sayım")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { yeniAcik = true } label: { Image(systemName: "plus").font(.headline) }
                        .accessibilityLabel("Etkinlik ekle")
                }
            }
            .sheet(isPresented: $yeniAcik) { EtkinlikFormu(mevcut: nil) }
            .sheet(item: $duzenlenen) { e in EtkinlikFormu(mevcut: e) }
        }
    }
}

private struct Bolum<Icerik: View>: View {
    let baslik: String
    @ViewBuilder let icerik: Icerik

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(baslik)
                .font(.title3.weight(.bold))
                .padding(.leading, 4)
            icerik
        }
    }
}

/// En yakın etkinlik: büyük, canlı sayaç.
private struct BuyukKart: View {
    let e: Etkinlik
    let canli: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(e.emoji)
                    .font(.system(size: 52))
                Spacer()
                Text("EN YAKIN")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.22), in: Capsule())
            }
            Text(e.ad)
                .font(.system(.title2, design: .rounded).weight(.bold))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(e.bugunMu ? "🎉" : "\(e.gun)")
                    .font(.system(size: 84, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                Text(e.bugunMu ? "Bugün!" : "gün")
                    .font(.title2.weight(.bold))
                    .opacity(0.9)
            }
            if canli {
                TimelineView(.everyMinute) { _ in kalanSaat }
            } else {
                kalanSaat
            }
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.25))
                        Capsule().fill(.white).frame(width: geo.size.width * e.ilerleme)
                    }
                }
                .frame(height: 8)
                Text(e.hedef.formatted(.dateTime.day().month(.wide).year().weekday(.wide)))
                    .font(.footnote.weight(.semibold))
                    .opacity(0.85)
            }
        }
        .foregroundStyle(.white)
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                e.gradyan
                Circle().fill(.white.opacity(0.10)).frame(width: 260).offset(x: 140, y: -90)
                Circle().fill(.white.opacity(0.07)).frame(width: 180).offset(x: -150, y: 120)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Renkler.cift(e.renk)[1].opacity(0.4), radius: 18, y: 10)
        .padding(.top, 4)
    }

    private var kalanSaat: some View {
        let saniye = max(0, Int(e.hedef.timeIntervalSinceNow))
        let saat = (saniye % 86400) / 3600
        let dakika = (saniye % 3600) / 60
        return HStack(spacing: 8) {
            Parca(sayi: saat, ad: "saat")
            Parca(sayi: dakika, ad: "dakika")
        }
    }

    private struct Parca: View {
        let sayi: Int
        let ad: String

        var body: some View {
            HStack(spacing: 4) {
                Text("\(sayi)").font(.system(.headline, design: .rounded).weight(.heavy)).monospacedDigit()
                Text(ad).font(.caption.weight(.semibold)).opacity(0.85)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.black.opacity(0.15), in: Capsule())
        }
    }
}

private struct KucukKart: View {
    let e: Etkinlik

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(e.emoji).font(.system(size: 32))
                Spacer()
                if e.yillik {
                    Image(systemName: "repeat")
                        .font(.caption.weight(.bold))
                        .opacity(0.8)
                }
            }
            Spacer(minLength: 6)
            Text(e.bugunMu ? "🎉" : "\(e.gun)")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(e.gunEtiketi)
                .font(.caption.weight(.bold))
                .opacity(0.85)
            Text(e.ad)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
        .background(e.gradyan, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Renkler.cift(e.renk)[1].opacity(0.3), radius: 10, y: 6)
    }
}

private struct WidgetOnizleme: View {
    @Environment(EtkinlikDeposu.self) private var depo

    var body: some View {
        let ilk = depo.sirali.first
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                KucukSayacGorunumu(etkinlik: ilk)
                    .padding(16)
                    .frame(width: 158, height: 158)
                    .background(ilk?.gradyan ?? LinearGradient(colors: Renkler.cift(1), startPoint: .top, endPoint: .bottom),
                                in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                VStack(alignment: .leading, spacing: 8) {
                    Label("Nasıl eklenir?", systemImage: "apps.iphone")
                        .font(.subheadline.weight(.bold))
                    Text("Ana ekranda boş bir yere basılı tut → sol üstteki **Düzenle** → **Widget ekle** → **Geri Sayım**.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            OrtaSayacGorunumu(etkinlikler: depo.sirali)
                .padding(16)
                .frame(height: 158)
                .background(ilk?.gradyan ?? LinearGradient(colors: Renkler.cift(1), startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct BosDurum: View {
    let ekle: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("⏳").font(.system(size: 72))
            Text("Neyi bekliyorsun?")
                .font(.title2.bold())
            Text("Tatil, doğum günü, konser, karne günü… Ekle; kaç gün kaldığını hem burada hem ana ekranında göreyim.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: ekle) {
                Label("İlk etkinliğini ekle", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: Renkler.cift(0), startPoint: .leading, endPoint: .trailing), in: Capsule())
            }
            .buttonStyle(BasmaStili())
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

struct BasmaStili: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
