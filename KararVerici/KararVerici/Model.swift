import Foundation
import Observation

struct Secenek: Identifiable, Codable, Hashable {
    var id = UUID()
    var ad: String
    /// Beğendikçe artar, beğenmedikçe azalır (0.2 ... 3).
    var agirlik: Double = 1
}

struct KararListesi: Identifiable, Codable, Hashable {
    var id = UUID()
    var ad: String
    var emoji: String
    var secenekler: [Secenek]
}

struct Karar: Identifiable, Codable, Hashable {
    var id = UUID()
    var listeId: UUID
    var secenekId: UUID
    var secenekAd: String
    var tarih: Date = .now
    /// 1 = beğendi, -1 = beğenmedi, nil = sormadık / cevapsız
    var puan: Int?
}

private struct Kayit: Codable {
    var listeler: [KararListesi]
    var kararlar: [Karar]
}

@MainActor
@Observable
final class KararDeposu {
    private(set) var listeler: [KararListesi] = []
    private(set) var kararlar: [Karar] = []

    init() {
        if let kayit = Self.oku() {
            listeler = kayit.listeler
            kararlar = kayit.kararlar
        } else {
            listeler = Self.hazirListeler
        }
    }

    // MARK: - Listeler

    func liste(_ id: UUID) -> KararListesi? { listeler.first { $0.id == id } }

    func kaydet(_ liste: KararListesi) {
        if let i = listeler.firstIndex(where: { $0.id == liste.id }) {
            listeler[i] = liste
        } else {
            listeler.append(liste)
        }
        yaz()
    }

    func sil(_ liste: KararListesi) {
        listeler.removeAll { $0.id == liste.id }
        kararlar.removeAll { $0.listeId == liste.id }
        yaz()
    }

    // MARK: - Kararlar

    func gecmis(_ listeId: UUID) -> [Karar] {
        kararlar.filter { $0.listeId == listeId }.sorted { $0.tarih > $1.tarih }
    }

    func sonKarar(_ listeId: UUID) -> Karar? { gecmis(listeId).first }

    /// Ağırlıklı rastgele seçim: beğenilenler daha sık, son çıkanlar daha seyrek gelir.
    func sec(_ liste: KararListesi) -> Secenek? {
        guard !liste.secenekler.isEmpty else { return nil }
        let son = gecmis(liste.id).prefix(3).map(\.secenekId)
        let agirliklar = liste.secenekler.map { s -> Double in
            let tekrar = son.filter { $0 == s.id }.count
            return s.agirlik * pow(0.35, Double(tekrar))
        }
        let toplam = agirliklar.reduce(0, +)
        var zar = Double.random(in: 0..<max(toplam, 0.0001))
        for (i, a) in agirliklar.enumerated() {
            zar -= a
            if zar < 0 { return liste.secenekler[i] }
        }
        return liste.secenekler.last
    }

    /// Sonucun yanında gösterilen "hatırlıyorum" cümlesi.
    func hafizaNotu(_ liste: KararListesi, secilen: Secenek) -> String? {
        let gecmis = gecmis(liste.id)
        guard let onceki = gecmis.first else { return nil }
        let ayniArdArda = gecmis.prefix(while: { $0.secenekId == onceki.secenekId }).count
        if ayniArdArda >= 2 && onceki.secenekId != secilen.id {
            return "Son \(ayniArdArda) kez \(onceki.secenekAd) çıkmıştı, bu sefer değiştirdim."
        }
        if let begenilmeyen = gecmis.first(where: { $0.secenekId == secilen.id && $0.puan == -1 }) {
            let gun = Calendar.current.dateComponents([.day], from: begenilmeyen.tarih, to: .now).day ?? 0
            return gun == 0 ? "Bugün beğenmemiştin ama şans böyle dedi 😅" : "\(gun) gün önce beğenmemiştin, bir şans daha?"
        }
        if let son = gecmis.first(where: { $0.secenekId == secilen.id }) {
            let gun = Calendar.current.dateComponents([.day], from: son.tarih, to: .now).day ?? 0
            if gun >= 7 { return "En son \(gun) gün önce çıkmıştı." }
        } else {
            return "Bu ilk kez çıkıyor! ✨"
        }
        return "Geçen sefer \(onceki.secenekAd) çıkmıştı."
    }

    @discardableResult
    func kaydet(_ secenek: Secenek, liste: KararListesi) -> Karar {
        let karar = Karar(listeId: liste.id, secenekId: secenek.id, secenekAd: secenek.ad)
        kararlar.append(karar)
        if kararlar.count > 500 { kararlar.removeFirst(kararlar.count - 500) }
        yaz()
        return karar
    }

    func puanla(_ kararId: UUID, _ puan: Int) {
        guard let k = kararlar.firstIndex(where: { $0.id == kararId }) else { return }
        let eski = kararlar[k].puan
        kararlar[k].puan = puan
        guard eski == nil,
              let l = listeler.firstIndex(where: { $0.id == kararlar[k].listeId }),
              let s = listeler[l].secenekler.firstIndex(where: { $0.id == kararlar[k].secenekId }) else { yaz(); return }
        let carpan = puan > 0 ? 1.25 : 0.6
        listeler[l].secenekler[s].agirlik = min(3, max(0.2, listeler[l].secenekler[s].agirlik * carpan))
        yaz()
    }

    // MARK: - Kayıt

    private func yaz() {
        if let veri = try? JSONEncoder().encode(Kayit(listeler: listeler, kararlar: kararlar)) {
            try? veri.write(to: Self.dosya, options: .atomic)
        }
    }

    private static var dosya: URL {
        let klasor = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: klasor, withIntermediateDirectories: true)
        return klasor.appendingPathComponent("kararlar.json")
    }

    private static func oku() -> Kayit? {
        guard let veri = try? Data(contentsOf: dosya) else { return nil }
        return try? JSONDecoder().decode(Kayit.self, from: veri)
    }

    static var hazirListeler: [KararListesi] {
        func l(_ ad: String, _ emoji: String, _ s: [String]) -> KararListesi {
            KararListesi(ad: ad, emoji: emoji, secenekler: s.map { Secenek(ad: $0) })
        }
        return [
            l("Bugün ne yesem?", "🍔", ["Pizza", "Döner", "Hamburger", "Lahmacun", "Ev yemeği", "Mantı", "Tost"]),
            l("Ne izlesem?", "🎬", ["Komedi", "Aksiyon", "Korku", "Belgesel", "Anime", "Bilim kurgu"]),
            l("Ne oynasam?", "🎮", ["Minecraft", "Valorant", "GTA V", "FIFA", "Roblox"]),
            l("Hafta sonu ne yapsam?", "🌤️", ["Sinema", "Yürüyüş", "Arkadaşlarla buluş", "Evde film gecesi", "Kafe", "Bisiklet"]),
            l("Hangi dersi çalışsam?", "📚", ["Matematik", "Fen", "Türkçe", "İngilizce", "Sosyal"]),
        ]
    }
}
