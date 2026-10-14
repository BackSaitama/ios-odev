import SwiftUI

struct AnaEkran: View {
    @Environment(FotoDeposu.self) private var depo
    @State private var secilen: Kaynak?
    @State private var copAcik = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    IstatistikKarti()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Hızlı temizlik") {
                    KaynakSatiri(ikon: "shuffle", renk: .indigo, baslik: "Karışık",
                                 alt: "Galeriden rastgele \(depo.toplamSayi) içinden") { secilen = .karisik }
                    KaynakSatiri(ikon: "camera.viewfinder", renk: .orange, baslik: "Ekran görüntüleri",
                                 alt: "\(depo.ekranGoruntusuSayisi) adet, eskiler önce") { secilen = .ekranGoruntuleri }
                    KaynakSatiri(ikon: "video.fill", renk: .pink, baslik: "Videolar",
                                 alt: "\(depo.videoSayisi) adet, en çok yer kaplayan önce") { secilen = .videolar }
                }

                Section("Ay ay temizle") {
                    if depo.aylar.isEmpty {
                        Text("Fotoğraflar sayılıyor…")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(depo.aylar) { ay in
                        AySatiri(ay: ay, incelenen: depo.incelenenSayisi(ay)) { secilen = .ay(ay) }
                    }
                }
            }
            .navigationTitle("Kaydır Sil")
            .navigationDestination(item: $secilen) { kaynak in
                KaydirEkrani(kaynak: kaynak)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CopDugmesi { copAcik = true }
                }
            }
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

private struct IstatistikKarti: View {
    @Environment(FotoDeposu.self) private var depo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Toplam açtığın yer")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Text(depo.kayit.acilanBayt.okunur)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            HStack(spacing: 18) {
                Label("\(depo.kayit.incelenenSayisi) incelendi", systemImage: "eye")
                Label("\(depo.kayit.silinenSayisi) silindi", systemImage: "trash")
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }
}

private struct KaynakSatiri: View {
    let ikon: String
    let renk: Color
    let baslik: String
    let alt: String
    let eylem: () -> Void

    var body: some View {
        Button(action: eylem) {
            HStack(spacing: 14) {
                Image(systemName: ikon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(renk, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(baslik).font(.headline)
                    Text(alt).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct AySatiri: View {
    let ay: AyOzeti
    let incelenen: Int
    let eylem: () -> Void

    private var bitti: Bool { incelenen >= ay.toplam }

    var body: some View {
        Button(action: eylem) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(ay.baslik).font(.headline)
                        if bitti {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                        }
                    }
                    ProgressView(value: Double(incelenen), total: Double(max(ay.toplam, 1)))
                        .tint(bitti ? .green : .indigo)
                }
                Text("\(incelenen)/\(ay.toplam)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 70, alignment: .trailing)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(bitti)
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
                            .background(.red, in: Capsule())
                            .offset(x: 12, y: -10)
                    }
                }
        }
        .accessibilityLabel("Çöp kutusu, \(depo.copSayisi) öğe")
    }
}
