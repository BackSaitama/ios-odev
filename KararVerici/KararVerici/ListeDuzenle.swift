import SwiftUI

struct ListeDuzenle: View {
    let mevcut: KararListesi?
    @Environment(KararDeposu.self) private var depo
    @Environment(\.dismiss) private var kapat

    @State private var ad = ""
    @State private var emoji = "🤔"
    @State private var secenekler: [Secenek] = []
    @State private var yeni = ""
    @FocusState private var yeniOdakta: Bool

    private let emojiler = ["🤔", "🍔", "🍕", "🎬", "🎮", "🌤️", "📚", "👕", "🎵", "⚽️", "✈️", "🎁"]

    private var gecerli: Bool {
        !ad.trimmingCharacters(in: .whitespaces).isEmpty && secenekler.count >= 2
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Liste") {
                    TextField("Ör. Bugün ne giysem?", text: $ad)
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojiler, id: \.self) { e in
                                Text(e)
                                    .font(.system(size: 28))
                                    .frame(width: 46, height: 46)
                                    .background(e == emoji ? Tema.vurgu.opacity(0.18) : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .onTapGesture { emoji = e }
                            }
                        }
                    }
                }

                Section {
                    ForEach(secenekler) { s in
                        Text(s.ad)
                    }
                    .onDelete { secenekler.remove(atOffsets: $0) }
                    .onMove { secenekler.move(fromOffsets: $0, toOffset: $1) }
                    HStack {
                        TextField("Yeni seçenek", text: $yeni)
                            .focused($yeniOdakta)
                            .submitLabel(.next)
                            .onSubmit(ekle)
                        Button(action: ekle) {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                        .disabled(yeni.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Seçenekler (\(secenekler.count))")
                } footer: {
                    Text("En az 2 seçenek gerekli. Silmek için sola kaydır.")
                }

                if let mevcut {
                    Section {
                        Button("Listeyi sil", role: .destructive) {
                            depo.sil(mevcut)
                            kapat()
                        }
                    }
                }
            }
            .navigationTitle(mevcut == nil ? "Yeni liste" : "Listeyi düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { kapat() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", action: kaydet)
                        .fontWeight(.bold)
                        .disabled(!gecerli)
                }
            }
            .onAppear {
                guard let m = mevcut else { return }
                ad = m.ad
                emoji = m.emoji
                secenekler = m.secenekler
            }
        }
    }

    private func ekle() {
        let temiz = yeni.trimmingCharacters(in: .whitespaces)
        guard !temiz.isEmpty else { return }
        withAnimation { secenekler.append(Secenek(ad: temiz)) }
        yeni = ""
        yeniOdakta = true
    }

    private func kaydet() {
        var liste = mevcut ?? KararListesi(ad: ad, emoji: emoji, secenekler: [])
        liste.ad = ad.trimmingCharacters(in: .whitespaces)
        liste.emoji = emoji
        liste.secenekler = secenekler
        depo.kaydet(liste)
        kapat()
    }
}
