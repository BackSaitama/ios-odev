import Photos
import SwiftUI

struct AnaEkran: View {
    @Environment(FotoDeposu.self) private var depo
    @State private var secilen: Kaynak?
    @State private var copAcik = false

    private let ayIzgarasi = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    OzetKarti()

                    VStack(alignment: .leading, spacing: 12) {
                        BolumBasligi(baslik: "Hızlı temizlik")
                        HStack(spacing: 12) {
                            HizliKutu(ikon: "shuffle", baslik: "Karışık", sayi: depo.toplamSayi,
                                      renkler: [.indigo, .purple]) { secilen = .karisik }
                            HizliKutu(ikon: "camera.viewfinder", baslik: "Ekran görüntüleri", sayi: depo.ekranGoruntusuSayisi,
                                      renkler: [.orange, .pink]) { secilen = .ekranGoruntuleri }
                            HizliKutu(ikon: "play.rectangle.fill", baslik: "Videolar", sayi: depo.videoSayisi,
                                      renkler: [.pink, .red]) { secilen = .videolar }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        BolumBasligi(baslik: "Ay ay temizle")
                        if depo.aylar.isEmpty {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Fotoğraflar sayılıyor…").foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                        } else {
                            LazyVGrid(columns: ayIzgarasi, spacing: 14) {
                                ForEach(depo.aylar) { ay in
                                    AyKarti(ay: ay, incelenen: depo.incelenenSayisi(ay)) { secilen = .ay(ay) }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Kaydır Sil")
            .navigationDestination(item: $secilen) { kaynak in
                KaydirEkrani(kaynak: kaynak)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CopDugmesi { copAcik = true }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if depo.copSayisi > 0 {
                    CopCubugu { copAcik = true }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: depo.copSayisi)
            .sheet(isPresented: $copAcik) {
                CopKutusu()
            }
            .task {
                await depo.ozetleriYukle()
                if ProcessInfo.processInfo.arguments.contains("-otomatikBasla") {
                    secilen = .karisik
                }
            }
            .refreshable {
                await depo.ozetleriYukle()
            }
        }
    }
}

private struct BolumBasligi: View {
    let baslik: String

    var body: some View {
        Text(baslik)
            .font(.title3.weight(.bold))
            .padding(.leading, 4)
    }
}

private struct OzetKarti: View {
    @Environment(FotoDeposu.self) private var depo

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Açtığın yer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(depo.kayit.acilanBayt.okunur)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                HStack(spacing: 8) {
                    Cip(ikon: "eye.fill", metin: "\(depo.kayit.incelenenSayisi)")
                    Cip(ikon: "trash.fill", metin: "\(depo.kayit.silinenSayisi)")
                }
            }
            Spacer(minLength: 0)
            IlerlemeHalkasi(deger: depo.galeriIlerlemesi)
                .frame(width: 92, height: 92)
        }
        .padding(22)
        .background {
            ZStack {
                Tema.anaGradyan
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 220)
                    .offset(x: 120, y: -70)
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 160)
                    .offset(x: -130, y: 80)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .purple.opacity(0.35), radius: 18, y: 10)
        .padding(.top, 4)
    }

    private struct Cip: View {
        let ikon: String
        let metin: String

        var body: some View {
            Label(metin, systemImage: ikon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.white.opacity(0.2), in: Capsule())
        }
    }
}

private struct HizliKutu: View {
    let ikon: String
    let baslik: String
    let sayi: Int
    let renkler: [Color]
    let eylem: () -> Void

    var body: some View {
        Button(action: eylem) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: ikon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(colors: renkler, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
                Spacer(minLength: 0)
                Text("\(sayi)")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .contentTransition(.numericText())
                Text(baslik)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .padding(14)
            .kartYuzeyi()
        }
        .buttonStyle(BasmaStili())
    }
}

private struct AyKarti: View {
    let ay: AyOzeti
    let incelenen: Int
    let eylem: () -> Void
    @Environment(FotoDeposu.self) private var depo

    private var bitti: Bool { incelenen >= ay.toplam }

    var body: some View {
        Button(action: eylem) {
            ZStack(alignment: .bottomLeading) {
                GeometryReader { geo in
                    if let kapak = ay.kimlikler.first.flatMap({ depo.varlik($0) }) {
                        VarlikGorseli(varlik: kapak, boyut: geo.size)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        Rectangle().fill(Color(.tertiarySystemFill))
                    }
                }
                LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 6) {
                    Text(ay.baslik)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    ProgressView(value: Double(incelenen), total: Double(max(ay.toplam, 1)))
                        .tint(bitti ? Tema.tutRengi : .white)
                    Text("\(incelenen) / \(ay.toplam)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .padding(12)
            }
            .frame(height: 170)
            .overlay(alignment: .topTrailing) {
                if bitti {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Tema.tutRengi)
                        .padding(10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .saturation(bitti ? 0.2 : 1)
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(BasmaStili())
        .disabled(bitti)
    }
}

private struct CopCubugu: View {
    @Environment(FotoDeposu.self) private var depo
    let eylem: () -> Void

    var body: some View {
        Button(action: eylem) {
            HStack(spacing: 12) {
                Image(systemName: "trash.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Tema.silRengi, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(depo.copSayisi) öğe silinmeyi bekliyor")
                        .font(.subheadline.weight(.bold))
                    Text("Gözden geçir ve yer aç")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .padding(.trailing, 8)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
        }
        .buttonStyle(BasmaStili())
        .padding(.horizontal, 18)
        .padding(.bottom, 6)
    }
}

struct CopDugmesi: View {
    @Environment(FotoDeposu.self) private var depo
    let eylem: () -> Void

    var body: some View {
        Button(action: eylem) {
            Image(systemName: depo.copSayisi > 0 ? "trash.fill" : "trash")
                .overlay(alignment: .topTrailing) {
                    if depo.copSayisi > 0 {
                        Text("\(depo.copSayisi)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Tema.silRengi, in: Capsule())
                            .offset(x: 12, y: -10)
                    }
                }
        }
        .accessibilityLabel("Çöp kutusu, \(depo.copSayisi) öğe")
    }
}
