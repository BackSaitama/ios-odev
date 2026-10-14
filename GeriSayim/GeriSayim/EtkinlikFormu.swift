import SwiftUI

struct EtkinlikFormu: View {
    let mevcut: Etkinlik?
    @Environment(EtkinlikDeposu.self) private var depo
    @Environment(\.dismiss) private var kapat

    @State private var ad = ""
    @State private var emoji = "🎉"
    @State private var tarih = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var renk = 0
    @State private var yillik = false

    private let emojiler = ["🎉", "🎂", "🏖️", "✈️", "🎄", "🎸", "🎓", "⚽️", "💍", "❤️", "📚", "🎮", "🎁", "💪", "🌙", "🏆"]

    private struct Hazir: Identifiable {
        let ad: String
        let emoji: String
        let ay: Int
        let gun: Int
        let renk: Int
        var id: String { ad }
    }

    private let hazirlar = [
        Hazir(ad: "Yılbaşı", emoji: "🎄", ay: 1, gun: 1, renk: 4),
        Hazir(ad: "Sevgililer Günü", emoji: "❤️", ay: 2, gun: 14, renk: 0),
        Hazir(ad: "23 Nisan", emoji: "🎈", ay: 4, gun: 23, renk: 3),
        Hazir(ad: "19 Mayıs", emoji: "🏃", ay: 5, gun: 19, renk: 2),
        Hazir(ad: "Cumhuriyet Bayramı", emoji: "🇹🇷", ay: 10, gun: 29, renk: 0),
    ]

    private var onizleme: Etkinlik {
        Etkinlik(ad: ad.isEmpty ? "Etkinlik adı" : ad, emoji: emoji, tarih: tarih, renk: renk, yillik: yillik,
                 olusturma: mevcut?.olusturma ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    OnizlemeKarti(e: onizleme)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                if mevcut == nil {
                    Section("Hızlı seç") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(hazirlar) { h in
                                    Button { uygula(h) } label: {
                                        Text("\(h.emoji) \(h.ad)")
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(.tertiarySystemFill), in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                Section("Ne?") {
                    TextField("Ör. Yaz tatili", text: $ad)
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(emojiler, id: \.self) { e in
                                Text(e)
                                    .font(.system(size: 28))
                                    .frame(width: 44, height: 44)
                                    .background(e == emoji ? Color.accentColor.opacity(0.18) : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .onTapGesture { emoji = e }
                            }
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Renkler.ciftler.indices, id: \.self) { i in
                                Circle()
                                    .fill(LinearGradient(colors: Renkler.cift(i), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if i == renk {
                                            Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white)
                                        }
                                    }
                                    .onTapGesture { withAnimation { renk = i } }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    DatePicker("Tarih", selection: $tarih, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    Toggle("Her yıl tekrarla", isOn: $yillik)
                } header: {
                    Text("Ne zaman?")
                } footer: {
                    Text("Geçmiş bir tarih seçersen \"... gündür\" diye ileri sayar. Doğum günü gibi şeyler için \"Her yıl tekrarla\"yı aç.")
                }

                if let mevcut {
                    Section {
                        Button("Etkinliği sil", role: .destructive) {
                            depo.sil(mevcut)
                            kapat()
                        }
                    }
                }
            }
            .navigationTitle(mevcut == nil ? "Yeni etkinlik" : "Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { kapat() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", action: kaydet)
                        .fontWeight(.bold)
                        .disabled(ad.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard let m = mevcut else { return }
                ad = m.ad
                emoji = m.emoji
                tarih = m.tarih
                renk = m.renk
                yillik = m.yillik
            }
        }
    }

    private func uygula(_ h: Hazir) {
        let takvim = Calendar.current
        var p = DateComponents(month: h.ay, day: h.gun)
        p.year = takvim.component(.year, from: .now)
        var t = takvim.date(from: p) ?? .now
        if t < takvim.startOfDay(for: .now) {
            p.year = (p.year ?? 0) + 1
            t = takvim.date(from: p) ?? t
        }
        withAnimation {
            ad = h.ad
            emoji = h.emoji
            renk = h.renk
            tarih = t
            yillik = true
        }
    }

    private func kaydet() {
        var e = mevcut ?? Etkinlik(ad: ad, emoji: emoji, tarih: tarih, renk: renk)
        e.ad = ad.trimmingCharacters(in: .whitespaces)
        e.emoji = emoji
        e.tarih = tarih
        e.renk = renk
        e.yillik = yillik
        depo.kaydet(e)
        kapat()
    }
}

private struct OnizlemeKarti: View {
    let e: Etkinlik

    var body: some View {
        HStack(spacing: 16) {
            Text(e.emoji).font(.system(size: 46))
            VStack(alignment: .leading, spacing: 2) {
                Text(e.ad)
                    .font(.headline)
                    .lineLimit(1)
                Text(e.hedef.formatted(.dateTime.day().month(.wide).year()))
                    .font(.caption.weight(.semibold))
                    .opacity(0.85)
            }
            Spacer()
            VStack(spacing: 0) {
                Text(e.bugunMu ? "🎉" : "\(e.gun)")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                Text(e.bugunMu ? "Bugün" : e.gunEtiketi)
                    .font(.caption2.weight(.bold))
                    .opacity(0.85)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(e.gradyan, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .animation(.spring, value: e)
    }
}
