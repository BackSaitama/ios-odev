import SwiftUI

struct AbonelikFormu: View {
    let mevcut: Abonelik?
    @Environment(AbonelikDeposu.self) private var depo
    @Environment(\.dismiss) private var kapat

    @State private var hazirSecildi = false
    @State private var ad = ""
    @State private var ucretMetni = ""
    @State private var periyot: Periyot = .aylik
    @State private var yenilenme = Date.now
    @State private var renk = 6
    @State private var denemeMi = false
    @State private var kullanim: Kullanim = .cok
    @FocusState private var ucretOdakta: Bool

    private var ucret: Double? {
        Double(ucretMetni.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) })
    }

    private var gecerli: Bool {
        !ad.trimmingCharacters(in: .whitespaces).isEmpty && (ucret ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Group {
                if mevcut == nil && !hazirSecildi {
                    HazirSecici { secilen in
                        if let secilen {
                            ad = secilen.ad
                            renk = secilen.renk
                        }
                        withAnimation { hazirSecildi = true }
                        if secilen != nil {
                            Task {
                                try? await Task.sleep(for: .milliseconds(450))
                                ucretOdakta = true
                            }
                        }
                    }
                } else {
                    form
                }
            }
            .navigationTitle(mevcut == nil ? "Yeni abonelik" : "Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { kapat() }
                }
                if mevcut != nil || hazirSecildi {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Kaydet", action: kaydet)
                            .fontWeight(.bold)
                            .disabled(!gecerli)
                    }
                }
            }
        }
        .onAppear(perform: doldur)
    }

    private var form: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    HarfLogo(harf: ad.isEmpty ? "?" : String(ad.prefix(1)).uppercased(), renk: Palet.renk(renk), boyut: 56)
                    TextField("Ad (ör. Netflix)", text: $ad)
                        .font(.title3.weight(.semibold))
                }
                .padding(.vertical, 4)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Palet.renkler.indices, id: \.self) { i in
                            Circle()
                                .fill(Palet.renk(i))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if i == renk {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { renk = i }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Ücret") {
                HStack {
                    TextField("0,00", text: $ucretMetni)
                        .keyboardType(.decimalPad)
                        .focused($ucretOdakta)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    Text("₺")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                Picker("Ne sıklıkla?", selection: $periyot) {
                    ForEach(Periyot.allCases) { Text($0.ad).tag($0) }
                }
                .pickerStyle(.segmented)
                if let ucret, ucret > 0, periyot != .aylik {
                    Text("Aylık karşılığı: \((ucret * periyot.ayCarpani).tl)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                DatePicker("Sonraki ödeme", selection: $yenilenme, displayedComponents: .date)
                Toggle(isOn: $denemeMi) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ücretsiz deneme")
                        Text("Bitmeden önce seni uyarırım")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Ödeme günü")
            } footer: {
                Text("Ödemeden bir gün önce saat 10:00'da hatırlatma gelir.")
            }

            Section("Ne kadar kullanıyorsun?") {
                Picker("Kullanım", selection: $kullanim) {
                    ForEach(Kullanim.allCases) { Text($0.ad).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            if let mevcut {
                Section {
                    Button("Aboneliği sil", role: .destructive) {
                        depo.sil(mevcut)
                        kapat()
                    }
                }
            }
        }
    }

    private func doldur() {
        guard let m = mevcut else { return }
        ad = m.ad
        ucretMetni = String(format: "%.2f", m.ucret).replacingOccurrences(of: ".", with: ",")
        periyot = m.periyot
        yenilenme = m.sonrakiYenilenme
        renk = m.renk
        denemeMi = m.denemeMi
        kullanim = m.kullanim
    }

    private func kaydet() {
        guard let ucret, gecerli else { return }
        var a = mevcut ?? Abonelik(ad: ad, ucret: ucret, periyot: periyot, yenilenme: yenilenme, renk: renk)
        a.ad = ad.trimmingCharacters(in: .whitespaces)
        a.ucret = ucret
        a.periyot = periyot
        a.yenilenme = yenilenme
        a.renk = renk
        a.denemeMi = denemeMi
        a.kullanim = kullanim
        depo.kaydet(a)
        Task { await Bildirimler.izinIste() }
        kapat()
    }
}

private struct HazirSecici: View {
    let sec: (Hazir?) -> Void
    @State private var arama = ""

    private var gruplar: [(String, [Hazir])] {
        let filtre = Hazir.liste.filter { arama.isEmpty || $0.ad.localizedCaseInsensitiveContains(arama) }
        var sira: [String] = []
        for h in filtre where !sira.contains(h.kategori) { sira.append(h.kategori) }
        return sira.map { k in (k, filtre.filter { $0.kategori == k }) }
    }

    private let sutunlar = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button { sec(nil) } label: {
                    Label("Listede yok, kendim yazacağım", systemImage: "square.and.pencil")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .kartYuzeyi(kose: 16)
                }
                .buttonStyle(BasmaStili())

                ForEach(gruplar, id: \.0) { kategori, liste in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(kategori)
                            .font(.headline)
                            .padding(.leading, 4)
                        LazyVGrid(columns: sutunlar, spacing: 12) {
                            ForEach(liste) { h in
                                Button { sec(h) } label: {
                                    VStack(spacing: 8) {
                                        HarfLogo(harf: String(h.ad.prefix(1)), renk: Palet.renk(h.renk), boyut: 48)
                                        Text(h.ad)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .frame(height: 30)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .kartYuzeyi(kose: 16)
                                }
                                .buttonStyle(BasmaStili())
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $arama, placement: .navigationBarDrawer(displayMode: .always), prompt: "Ara")
    }
}
