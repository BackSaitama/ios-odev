import SwiftUI

struct AnaEkran: View {
    @Environment(KararDeposu.self) private var depo
    @State private var yeniAcik = false

    private let izgara = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    UstKart()

                    LazyVGrid(columns: izgara, spacing: 14) {
                        ForEach(Array(depo.listeler.enumerated()), id: \.element.id) { i, liste in
                            NavigationLink(value: liste.id) {
                                ListeKarti(liste: liste, renkler: Tema.kartRenkleri(i))
                            }
                            .buttonStyle(BasmaStili())
                        }
                        Button { yeniAcik = true } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(.system(size: 30, weight: .bold))
                                Text("Yeni liste")
                                    .font(.subheadline.weight(.bold))
                            }
                            .foregroundStyle(Tema.vurgu)
                            .frame(maxWidth: .infinity, minHeight: 168)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(Tema.vurgu.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                            )
                        }
                        .buttonStyle(BasmaStili())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Karar Verici")
            .navigationDestination(for: UUID.self) { id in
                KararEkrani(listeId: id)
            }
            .sheet(isPresented: $yeniAcik) {
                ListeDuzenle(mevcut: nil)
            }
        }
    }
}

private struct UstKart: View {
    @Environment(KararDeposu.self) private var depo

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Kararsız mı kaldın?")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                Text("Bir liste seç, telefonu salla. Neyi beğendiğini öğrenir, aynı şeyi üst üste çıkarmam.")
                    .font(.subheadline)
                    .opacity(0.9)
                    .fixedSize(horizontal: false, vertical: true)
                if !depo.kararlar.isEmpty {
                    Text("\(depo.kararlar.count) karar verildi")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.22), in: Capsule())
                }
            }
            Spacer(minLength: 0)
            Text("🎲")
                .font(.system(size: 64))
                .rotationEffect(.degrees(-12))
        }
        .foregroundStyle(.white)
        .padding(22)
        .background(Tema.anaGradyan, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Tema.vurgu.opacity(0.35), radius: 16, y: 8)
        .padding(.top, 4)
    }
}

private struct ListeKarti: View {
    let liste: KararListesi
    let renkler: [Color]
    @Environment(KararDeposu.self) private var depo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(liste.emoji)
                .font(.system(size: 36))
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(colors: renkler.map { $0.opacity(0.25) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            Text(liste.ad)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Group {
                if let son = depo.sonKarar(liste.id) {
                    Text("Son: \(son.secenekAd)")
                } else {
                    Text("\(liste.secenekler.count) seçenek")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        .padding(14)
        .kartYuzeyi(kose: 24)
    }
}
