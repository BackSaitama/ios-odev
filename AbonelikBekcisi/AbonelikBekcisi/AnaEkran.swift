import SwiftUI

struct AnaEkran: View {
    @Environment(AbonelikDeposu.self) private var depo
    @State private var yeniAcik = false
    @State private var duzenlenen: Abonelik?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ToplamKarti()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if depo.abonelikler.isEmpty {
                    Section {
                        BosDurum { yeniAcik = true }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    if !depo.yaklasanlar.isEmpty {
                        Section {
                            YaklasanSeridi(liste: depo.yaklasanlar) { duzenlenen = $0 }
                        } header: {
                            Text("Bu hafta çekilecek")
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    if depo.tasarrufYillik > 0 {
                        Section {
                            TasarrufKarti()
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        ForEach(depo.sirali) { a in
                            Button { duzenlenen = a } label: { AbonelikSatiri(a: a) }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { withAnimation { depo.sil(a) } } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    ForEach(Kullanim.allCases.filter { $0 != a.kullanim }) { k in
                                        Button { withAnimation { depo.kullanimDegistir(a, k) } } label: {
                                            Text(k.ad + " kullanıyorum")
                                        }
                                        .tint(k.renk)
                                    }
                                }
                        }
                    } header: {
                        Text("Tüm abonelikler (\(depo.abonelikler.count))")
                    } footer: {
                        Text("İpucu: Bir aboneliği sağa kaydırıp ne kadar kullandığını işaretle.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(18)
            .navigationTitle("Abonelik Bekçisi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { yeniAcik = true } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .accessibilityLabel("Abonelik ekle")
                }
            }
            .sheet(isPresented: $yeniAcik) {
                AbonelikFormu(mevcut: nil)
            }
            .sheet(item: $duzenlenen) { a in
                AbonelikFormu(mevcut: a)
            }
        }
    }
}

private struct ToplamKarti: View {
    @Environment(AbonelikDeposu.self) private var depo

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Aylık toplam")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Label("\(depo.abonelikler.count)", systemImage: "repeat")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.2), in: Capsule())
            }
            Text(depo.aylikToplam.tl)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text("Yılda \(depo.yillikToplam.tlYuvarlak)")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.15), in: Capsule())
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                Tema.anaGradyan
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 150))
                    .foregroundStyle(.white.opacity(0.08))
                    .offset(x: 120, y: 10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Tema.vurgu.opacity(0.35), radius: 16, y: 8)
        .animation(.spring, value: depo.aylikToplam)
    }
}

private struct YaklasanSeridi: View {
    let liste: [Abonelik]
    let sec: (Abonelik) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(liste) { a in
                    Button { sec(a) } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HarfLogo(harf: a.harf, renk: a.renkDegeri, boyut: 36)
                                Spacer()
                                if a.denemeMi {
                                    Text("DENEME")
                                        .font(.caption2.weight(.black))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(.orange, in: Capsule())
                                }
                            }
                            Text(a.ad)
                                .font(.subheadline.weight(.bold))
                                .lineLimit(1)
                            Text(a.ucret.tl)
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                            Text(a.kalanMetni)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(a.kalanGun <= 1 ? Color.red : Color.secondary)
                        }
                        .frame(width: 140, alignment: .leading)
                        .padding(14)
                        .kartYuzeyi(kose: 20)
                    }
                    .buttonStyle(BasmaStili())
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 2)
        }
    }
}

private struct TasarrufKarti: View {
    @Environment(AbonelikDeposu.self) private var depo

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "lightbulb.max.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [.orange, .yellow], startPoint: .bottomLeading, endPoint: .topTrailing),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text("Yılda \(depo.tasarrufYillik.tlYuvarlak) tasarruf edebilirsin")
                    .font(.subheadline.weight(.bold))
                Text("Az ya da hiç kullanmadığın \(depo.azKullanilanlar.count) abonelik: " +
                     depo.azKullanilanlar.map(\.ad).joined(separator: ", "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .kartYuzeyi(kose: 20)
    }
}

private struct AbonelikSatiri: View {
    let a: Abonelik

    var body: some View {
        HStack(spacing: 14) {
            HarfLogo(harf: a.harf, renk: a.renkDegeri)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(a.ad).font(.headline).lineLimit(1)
                    if a.denemeMi {
                        Image(systemName: "hourglass")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                }
                HStack(spacing: 6) {
                    Text(a.kalanMetni)
                        .foregroundStyle(a.kalanGun <= 1 ? Color.red : Color.secondary)
                        .fontWeight(a.kalanGun <= 1 ? .bold : .regular)
                    Circle().fill(a.kullanim.renk).frame(width: 6, height: 6)
                    Text(a.kullanim.ad + " kullanım")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(a.ucret.tl)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                Text("/ " + a.periyot.kisa)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

private struct BosDurum: View {
    let ekle: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                .font(.system(size: 64))
                .foregroundStyle(Tema.anaGradyan)
            Text("Paran nereye gidiyor?")
                .font(.title2.bold())
            Text("Netflix, Spotify, oyun üyelikleri… Hepsini ekle; ne kadar ödediğini gör, yenilenmeden bir gün önce haber vereyim.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: ekle) {
                Label("İlk aboneliğini ekle", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Tema.anaGradyan, in: Capsule())
            }
            .buttonStyle(BasmaStili())
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}
