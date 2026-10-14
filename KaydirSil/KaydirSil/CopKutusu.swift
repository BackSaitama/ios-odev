import Photos
import SwiftUI

struct CopKutusu: View {
    @Environment(FotoDeposu.self) private var depo
    @Environment(\.dismiss) private var kapat
    @State private var siliniyor = false
    @State private var acilan: Int64?
    @State private var hata = false

    private let sutunlar = [GridItem(.adaptive(minimum: 104), spacing: 8)]

    var body: some View {
        NavigationStack {
            let varliklar = depo.copVarliklari
            Group {
                if varliklar.isEmpty {
                    ContentUnavailableView("Çöp kutusu boş",
                                           systemImage: "trash",
                                           description: Text("Sola kaydırdığın fotoğraflar burada birikir."))
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            OzetSeridi(sayi: varliklar.count, boyut: depo.copBoyutu)
                            LazyVGrid(columns: sutunlar, spacing: 8) {
                                ForEach(varliklar, id: \.localIdentifier) { varlik in
                                    CopHucresi(varlik: varlik) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            depo.kurtar(varlik.localIdentifier)
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .padding(16)
                    }
                    .background(Color(.systemGroupedBackground))
                    .safeAreaInset(edge: .bottom) { silmeCubugu(sayi: varliklar.count) }
                }
            }
            .navigationTitle("Çöp kutusu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { kapat() }
                }
            }
            .alert("Harika! 🎉", isPresented: Binding(get: { acilan != nil }, set: { if !$0 { acilan = nil } })) {
                Button("Tamam") { kapat() }
            } message: {
                Text("\((acilan ?? 0).okunur) yer açtın. Silinenler 30 gün boyunca Fotoğraflar uygulamasındaki \"Son Silinenler\" klasöründe durur; yer hemen açılsın istersen orayı da boşalt.")
            }
            .alert("Silinmedi", isPresented: $hata) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Silme işlemi iptal edildi ya da bir sorun oldu. Fotoğrafların yerinde duruyor.")
            }
        }
    }

    private func silmeCubugu(sayi: Int) -> some View {
        Button(role: .destructive) {
            Task {
                siliniyor = true
                let sonuc = await depo.copuBosalt()
                siliniyor = false
                if let sonuc { acilan = sonuc } else { hata = true }
            }
        } label: {
            HStack(spacing: 10) {
                if siliniyor {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "trash.fill")
                }
                Text("\(sayi) öğeyi sil")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: [Tema.silRengi, Color(red: 0.9, green: 0.15, blue: 0.4)],
                               startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .shadow(color: Tema.silRengi.opacity(0.4), radius: 14, y: 6)
        }
        .buttonStyle(BasmaStili())
        .disabled(siliniyor)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

private struct OzetSeridi: View {
    let sayi: Int
    let boyut: Int64

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "externaldrive.fill.badge.minus")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Tema.anaGradyan, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(boyut.okunur) açılacak")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .contentTransition(.numericText())
                Text("Yanlışlıkla eklediğin olursa üstüne dokun, geri çıksın.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .kartYuzeyi(kose: 20)
    }
}

private struct CopHucresi: View {
    let varlik: PHAsset
    let kurtar: () -> Void
    @Environment(FotoDeposu.self) private var depo

    var body: some View {
        Button(action: kurtar) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    GeometryReader { geo in
                        VarlikGorseli(varlik: varlik, boyut: geo.size)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    HStack(spacing: 4) {
                        if varlik.mediaType == .video { Image(systemName: "video.fill") }
                        Text(depo.boyut(varlik).okunur)
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.45), in: Capsule())
                    .padding(6)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.35))
                        .padding(6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(BasmaStili())
        .accessibilityLabel("Geri çıkar")
    }
}
