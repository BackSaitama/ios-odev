import Foundation
import SwiftUI

/// Uygulama ile widget'ın ortak kullandığı model ve kayıt.
struct Etkinlik: Identifiable, Codable, Hashable {
    var id = UUID()
    var ad: String
    var emoji: String
    var tarih: Date
    var renk: Int
    /// Doğum günü gibi her yıl tekrar edenler.
    var yillik: Bool = false
    var olusturma: Date = .now

    /// Sayılan gün: yıllıksa bir sonraki yıldönümü, değilse kendisi.
    var hedef: Date {
        guard yillik else { return tarih }
        let takvim = Calendar.current
        let bugun = takvim.startOfDay(for: .now)
        var p = takvim.dateComponents([.month, .day], from: tarih)
        p.year = takvim.component(.year, from: bugun)
        var aday = takvim.date(from: p) ?? tarih
        if aday < bugun {
            p.year = (p.year ?? 0) + 1
            aday = takvim.date(from: p) ?? tarih
        }
        return aday
    }

    /// Geçmişte kalan tek seferlik etkinlik ("... gündür") mi?
    var gecmisMi: Bool { !yillik && Calendar.current.startOfDay(for: tarih) < Calendar.current.startOfDay(for: .now) }

    /// Bugünden hedefe kalan (ya da geçen) tam gün sayısı, hep pozitif.
    var gun: Int {
        let takvim = Calendar.current
        let fark = takvim.dateComponents([.day], from: takvim.startOfDay(for: .now), to: takvim.startOfDay(for: hedef)).day ?? 0
        return abs(fark)
    }

    var bugunMu: Bool { Calendar.current.isDateInToday(hedef) }

    var gunEtiketi: String {
        if bugunMu { return "Bugün!" }
        return gecmisMi ? "gündür" : "gün kaldı"
    }

    /// Oluşturulduğu günden hedefe ne kadar yol alındı (0...1).
    var ilerleme: Double {
        let toplam = hedef.timeIntervalSince(olusturma)
        guard toplam > 0, !gecmisMi else { return 1 }
        return min(1, max(0, Date.now.timeIntervalSince(olusturma) / toplam))
    }

    var gradyan: LinearGradient {
        LinearGradient(colors: Renkler.cift(renk), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

enum Renkler {
    static let ciftler: [[Color]] = [
        [Color(red: 1.00, green: 0.45, blue: 0.35), Color(red: 0.93, green: 0.25, blue: 0.55)],
        [Color(red: 0.35, green: 0.40, blue: 1.00), Color(red: 0.62, green: 0.30, blue: 0.95)],
        [Color(red: 0.10, green: 0.75, blue: 0.70), Color(red: 0.10, green: 0.45, blue: 0.90)],
        [Color(red: 1.00, green: 0.70, blue: 0.15), Color(red: 1.00, green: 0.40, blue: 0.20)],
        [Color(red: 0.30, green: 0.80, blue: 0.40), Color(red: 0.05, green: 0.55, blue: 0.45)],
        [Color(red: 0.95, green: 0.40, blue: 0.75), Color(red: 0.55, green: 0.30, blue: 0.95)],
        [Color(red: 0.20, green: 0.22, blue: 0.35), Color(red: 0.40, green: 0.30, blue: 0.60)],
        [Color(red: 0.00, green: 0.65, blue: 0.95), Color(red: 0.30, green: 0.90, blue: 0.85)],
    ]

    static func cift(_ i: Int) -> [Color] { ciftler[((i % ciftler.count) + ciftler.count) % ciftler.count] }
}

enum OrtakKayit {
    static let grup = "group.com.kuzeykilinc.gerisayim"

    static var dosya: URL {
        let klasor = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: grup)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: klasor, withIntermediateDirectories: true)
        return klasor.appendingPathComponent("etkinlikler.json")
    }

    static func oku() -> [Etkinlik] {
        guard let veri = try? Data(contentsOf: dosya),
              let liste = try? JSONDecoder().decode([Etkinlik].self, from: veri) else { return [] }
        return liste
    }

    static func yaz(_ liste: [Etkinlik]) {
        if let veri = try? JSONEncoder().encode(liste) {
            try? veri.write(to: dosya, options: .atomic)
        }
    }

    /// Yaklaşanlar önce (en yakın en başta), sonra "gündür" sayılanlar.
    static func sirala(_ liste: [Etkinlik]) -> [Etkinlik] {
        let gelecek = liste.filter { !$0.gecmisMi }.sorted { $0.hedef < $1.hedef }
        let gecmis = liste.filter(\.gecmisMi).sorted { $0.tarih > $1.tarih }
        return gelecek + gecmis
    }
}

/// Küçük widget görünümü; uygulama içinde önizleme olarak da kullanılır.
struct KucukSayacGorunumu: View {
    let etkinlik: Etkinlik?

    var body: some View {
        if let e = etkinlik {
            VStack(alignment: .leading, spacing: 2) {
                Text(e.emoji).font(.system(size: 30))
                Spacer(minLength: 0)
                Text(e.bugunMu ? "🎉" : "\(e.gun)")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(e.gunEtiketi)
                    .font(.caption.weight(.bold))
                    .opacity(0.85)
                Text(e.ad)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            VStack(spacing: 6) {
                Text("⏳").font(.system(size: 34))
                Text("Bir etkinlik ekle")
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Orta boy widget: en yakın üç etkinlik.
struct OrtaSayacGorunumu: View {
    let etkinlikler: [Etkinlik]

    var body: some View {
        if etkinlikler.isEmpty {
            KucukSayacGorunumu(etkinlik: nil)
        } else {
            VStack(spacing: 8) {
                ForEach(etkinlikler.prefix(3)) { e in
                    HStack(spacing: 10) {
                        Text(e.emoji)
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Text(e.ad)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(e.bugunMu ? "🎉" : "\(e.gun)")
                                .font(.system(.title3, design: .rounded).weight(.heavy))
                            Text(e.gecmisMi ? "gündür" : "gün")
                                .font(.caption2.weight(.semibold))
                                .opacity(0.8)
                        }
                    }
                }
            }
            .foregroundStyle(.white)
        }
    }
}
