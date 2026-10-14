import Observation
import SwiftUI
import WidgetKit

@main
struct GeriSayimApp: App {
    @State private var depo = EtkinlikDeposu()

    var body: some Scene {
        WindowGroup {
            AnaEkran()
                .environment(depo)
                .tint(Color(red: 0.93, green: 0.30, blue: 0.50))
        }
    }
}

@MainActor
@Observable
final class EtkinlikDeposu {
    private(set) var etkinlikler: [Etkinlik] = []

    /// Arayüz testlerinde canlı saati durdurmak için.
    let testModu = ProcessInfo.processInfo.arguments.contains("-UITest")

    init() {
        etkinlikler = OrtakKayit.oku()
        if ProcessInfo.processInfo.arguments.contains("-ornekVeri") {
            etkinlikler = Self.ornekler
        }
    }

    var sirali: [Etkinlik] { OrtakKayit.sirala(etkinlikler) }
    var yaklasanlar: [Etkinlik] { sirali.filter { !$0.gecmisMi } }
    var gecmistekiler: [Etkinlik] { sirali.filter(\.gecmisMi) }

    func kaydet(_ e: Etkinlik) {
        if let i = etkinlikler.firstIndex(where: { $0.id == e.id }) {
            etkinlikler[i] = e
        } else {
            etkinlikler.append(e)
        }
        degisti()
    }

    func sil(_ e: Etkinlik) {
        etkinlikler.removeAll { $0.id == e.id }
        degisti()
    }

    private func degisti() {
        OrtakKayit.yaz(etkinlikler)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static var ornekler: [Etkinlik] {
        let takvim = Calendar.current
        func gun(_ n: Int) -> Date { takvim.date(byAdding: .day, value: n, to: .now) ?? .now }
        let gecen = takvim.date(byAdding: .day, value: -60, to: .now) ?? .now
        return [
            Etkinlik(ad: "Yarıyıl tatili", emoji: "🏖️", tarih: gun(96), renk: 2, olusturma: gecen),
            Etkinlik(ad: "Doğum günüm", emoji: "🎂", tarih: gun(23), renk: 0, yillik: true, olusturma: gecen),
            Etkinlik(ad: "Konser", emoji: "🎸", tarih: gun(9), renk: 5, olusturma: gecen),
            Etkinlik(ad: "Yılbaşı", emoji: "🎄", tarih: gun(78), renk: 4, yillik: true, olusturma: gecen),
            Etkinlik(ad: "Spora başladım", emoji: "💪", tarih: gun(-47), renk: 3),
        ]
    }
}
