import Photos
import SwiftUI

struct CopKutusu: View {
    @Environment(FotoDeposu.self) private var depo
    @Environment(\.dismiss) private var kapat
    @State private var siliniyor = false
    @State private var acilan: Int64?
    @State private var hata = false

    private let sutunlar = [GridItem(.adaptive(minimum: 104), spacing: 4)]

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
                        Text("Yanlışlıkla eklediğine dokun, geri çıksın.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        LazyVGrid(columns: sutunlar, spacing: 4) {
                            ForEach(varliklar, id: \.localIdentifier) { varlik in
                                Button {
                                    withAnimation { depo.kurtar(varlik.localIdentifier) }
                                } label: {
                                    VarlikGorseli(varlik: varlik, boyut: CGSize(width: 110, height: 110))
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .frame(height: 110)
                                        .clipped()
                                        .overlay(alignment: .bottomTrailing) {
                                            if varlik.mediaType == .video {
                                                Image(systemName: "video.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.white)
                                                    .padding(6)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
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
        VStack(spacing: 6) {
            Button(role: .destructive) {
                Task {
                    siliniyor = true
                    let sonuc = await depo.copuBosalt()
                    siliniyor = false
                    if let sonuc { acilan = sonuc } else { hata = true }
                }
            } label: {
                HStack {
                    if siliniyor { ProgressView().tint(.white) }
                    Text("\(sayi) öğeyi sil · \(depo.copBoyutu.okunur)")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
            .disabled(siliniyor)
        }
        .padding()
        .background(.bar)
    }
}
