import Foundation
import Observation
import SwiftUI

enum Periyot: String, Codable, CaseIterable, Identifiable {
    case haftalik, aylik, yillik

    var id: String { rawValue }

    var ad: String {
        switch self {
        case .haftalik: return "Haftalık"
        case .aylik: return "Aylık"
        case .yillik: return "Yıllık"
        }
    }

    var kisa: String {
        switch self {
        case .haftalik: return "hafta"
        case .aylik: return "ay"
        case .yillik: return "yıl"
        }
    }

    /// Bu periyottaki ücretin aylık karşılığı için çarpan.
    var ayCarpani: Double {
        switch self {
        case .haftalik: return 52.0 / 12.0
        case .aylik: return 1
        case .yillik: return 1.0 / 12.0
        }
    }

    func sonraki(_ tarih: Date) -> Date {
        let takvim = Calendar.current
        switch self {
        case .haftalik: return takvim.date(byAdding: .weekOfYear, value: 1, to: tarih) ?? tarih
        case .aylik: return takvim.date(byAdding: .month, value: 1, to: tarih) ?? tarih
        case .yillik: return takvim.date(byAdding: .year, value: 1, to: tarih) ?? tarih
        }
    }
}

enum Kullanim: String, Codable, CaseIterable, Identifiable {
    case cok, az, hic

    var id: String { rawValue }

    var ad: String {
        switch self {
        case .cok: return "Sık"
        case .az: return "Az"
        case .hic: return "Hiç"
        }
    }

    var renk: Color {
        switch self {
        case .cok: return .green
        case .az: return .orange
        case .hic: return .red
        }
    }
}

struct Abonelik: Identifiable, Codable, Hashable {
    var id = UUID()
    var ad: String
    var ucret: Double
    var periyot: Periyot
    /// İlk (ya da bilinen) yenilenme tarihi; sonrakiler bundan hesaplanır.
    var yenilenme: Date
    var renk: Int
    var denemeMi: Bool = false
    var kullanim: Kullanim = .cok

    var aylik: Double { ucret * periyot.ayCarpani }
    var yillik: Double { aylik * 12 }
    var harf: String { String(ad.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased() }
    var renkDegeri: Color { Palet.renk(renk) }

    /// Bugünden itibaren gelecek ilk yenilenme günü.
    var sonrakiYenilenme: Date {
        let bugun = Calendar.current.startOfDay(for: .now)
        var tarih = Calendar.current.startOfDay(for: yenilenme)
        var guvenlik = 0
        while tarih < bugun && guvenlik < 2000 {
            tarih = periyot.sonraki(tarih)
            guvenlik += 1
        }
        return tarih
    }

    var kalanGun: Int {
        let bugun = Calendar.current.startOfDay(for: .now)
        return Calendar.current.dateComponents([.day], from: bugun, to: sonrakiYenilenme).day ?? 0
    }

    var kalanMetni: String {
        switch kalanGun {
        case 0: return "Bugün"
        case 1: return "Yarın"
        default: return "\(kalanGun) gün sonra"
        }
    }
}

enum Palet {
    static let renkler: [Color] = [
        Color(red: 0.90, green: 0.07, blue: 0.14),  // kırmızı
        Color(red: 0.11, green: 0.73, blue: 0.33),  // yeşil
        Color(red: 1.00, green: 0.00, blue: 0.00),  // parlak kırmızı
        Color(red: 0.07, green: 0.20, blue: 0.55),  // lacivert
        Color(red: 0.00, green: 0.66, blue: 0.88),  // mavi
        Color(red: 0.98, green: 0.36, blue: 0.53),  // pembe
        Color(red: 0.55, green: 0.32, blue: 0.95),  // mor
        Color(red: 1.00, green: 0.58, blue: 0.00),  // turuncu
        Color(red: 0.20, green: 0.20, blue: 0.22),  // siyah
        Color(red: 0.06, green: 0.55, blue: 0.13),  // koyu yeşil
        Color(red: 0.35, green: 0.40, blue: 0.95),  // indigo
        Color(red: 0.00, green: 0.60, blue: 0.55),  // camgöbeği
    ]

    static func renk(_ i: Int) -> Color { renkler[((i % renkler.count) + renkler.count) % renkler.count] }
}

/// Hızlı eklemek için hazır abonelik adları.
struct Hazir: Identifiable, Hashable {
    let ad: String
    let renk: Int
    let kategori: String
    var id: String { ad }

    static let liste: [Hazir] = [
        Hazir(ad: "Netflix", renk: 0, kategori: "Dizi & film"),
        Hazir(ad: "Disney+", renk: 3, kategori: "Dizi & film"),
        Hazir(ad: "Amazon Prime", renk: 4, kategori: "Dizi & film"),
        Hazir(ad: "HBO Max", renk: 6, kategori: "Dizi & film"),
        Hazir(ad: "Exxen", renk: 7, kategori: "Dizi & film"),
        Hazir(ad: "TOD", renk: 6, kategori: "Dizi & film"),
        Hazir(ad: "Spotify", renk: 1, kategori: "Müzik"),
        Hazir(ad: "Apple Music", renk: 5, kategori: "Müzik"),
        Hazir(ad: "YouTube Premium", renk: 2, kategori: "Müzik"),
        Hazir(ad: "iCloud+", renk: 4, kategori: "Depolama"),
        Hazir(ad: "Google One", renk: 10, kategori: "Depolama"),
        Hazir(ad: "Xbox Game Pass", renk: 9, kategori: "Oyun"),
        Hazir(ad: "PlayStation Plus", renk: 3, kategori: "Oyun"),
        Hazir(ad: "Discord Nitro", renk: 10, kategori: "Oyun"),
        Hazir(ad: "ChatGPT Plus", renk: 11, kategori: "Uygulama"),
        Hazir(ad: "Duolingo", renk: 1, kategori: "Uygulama"),
        Hazir(ad: "Spor salonu", renk: 7, kategori: "Diğer"),
        Hazir(ad: "Telefon faturası", renk: 8, kategori: "Diğer"),
    ]
}

@MainActor
@Observable
final class AbonelikDeposu {
    private(set) var abonelikler: [Abonelik] = []

    init() {
        abonelikler = Self.oku()
        if ProcessInfo.processInfo.arguments.contains("-ornekVeri") {
            abonelikler = Self.ornekler
        }
    }

    var sirali: [Abonelik] { abonelikler.sorted { $0.sonrakiYenilenme < $1.sonrakiYenilenme } }
    var aylikToplam: Double { abonelikler.reduce(0) { $0 + $1.aylik } }
    var yillikToplam: Double { aylikToplam * 12 }
    var yaklasanlar: [Abonelik] { sirali.filter { $0.kalanGun <= 7 } }
    var azKullanilanlar: [Abonelik] { abonelikler.filter { $0.kullanim != .cok } }
    var tasarrufYillik: Double { azKullanilanlar.reduce(0) { $0 + $1.yillik } }

    func kaydet(_ a: Abonelik) {
        if let i = abonelikler.firstIndex(where: { $0.id == a.id }) {
            abonelikler[i] = a
        } else {
            abonelikler.append(a)
        }
        degisti()
    }

    func sil(_ a: Abonelik) {
        abonelikler.removeAll { $0.id == a.id }
        degisti()
    }

    func kullanimDegistir(_ a: Abonelik, _ k: Kullanim) {
        var yeni = a
        yeni.kullanim = k
        kaydet(yeni)
    }

    private func degisti() {
        if let veri = try? JSONEncoder().encode(abonelikler) {
            try? veri.write(to: Self.dosya, options: .atomic)
        }
        Bildirimler.planla(abonelikler)
    }

    private static var dosya: URL {
        let klasor = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: klasor, withIntermediateDirectories: true)
        return klasor.appendingPathComponent("abonelikler.json")
    }

    private static func oku() -> [Abonelik] {
        guard let veri = try? Data(contentsOf: dosya),
              let liste = try? JSONDecoder().decode([Abonelik].self, from: veri) else { return [] }
        return liste
    }

    private static var ornekler: [Abonelik] {
        let bugun = Date.now
        func gun(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: n, to: bugun) ?? bugun }
        return [
            Abonelik(ad: "Spotify", ucret: 99.99, periyot: .aylik, yenilenme: gun(1), renk: 1),
            Abonelik(ad: "Netflix", ucret: 229.99, periyot: .aylik, yenilenme: gun(4), renk: 0, kullanim: .az),
            Abonelik(ad: "iCloud+", ucret: 39.99, periyot: .aylik, yenilenme: gun(12), renk: 4),
            Abonelik(ad: "Xbox Game Pass", ucret: 449.99, periyot: .aylik, yenilenme: gun(2), renk: 9, denemeMi: true),
            Abonelik(ad: "Exxen", ucret: 1199, periyot: .yillik, yenilenme: gun(40), renk: 7, kullanim: .hic),
        ]
    }
}

extension Double {
    var tl: String { formatted(.currency(code: "TRY").locale(Locale(identifier: "tr_TR"))) }
    var tlYuvarlak: String {
        formatted(.currency(code: "TRY").locale(Locale(identifier: "tr_TR")).precision(.fractionLength(0)))
    }
}
