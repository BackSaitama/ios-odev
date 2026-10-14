import SwiftUI
import WidgetKit

struct SayacGirdisi: TimelineEntry {
    let date: Date
    let etkinlikler: [Etkinlik]
}

struct SayacSaglayici: TimelineProvider {
    func placeholder(in context: Context) -> SayacGirdisi {
        SayacGirdisi(date: .now, etkinlikler: [
            Etkinlik(ad: "Yaz tatili", emoji: "🏖️", tarih: .now.addingTimeInterval(86400 * 42), renk: 2),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SayacGirdisi) -> Void) {
        let liste = OrtakKayit.sirala(OrtakKayit.oku())
        completion(liste.isEmpty ? placeholder(in: context) : SayacGirdisi(date: .now, etkinlikler: liste))
    }

    /// Her gece yarısı yenilenen 7 günlük zaman çizelgesi.
    func getTimeline(in context: Context, completion: @escaping (Timeline<SayacGirdisi>) -> Void) {
        let takvim = Calendar.current
        let bugun = takvim.startOfDay(for: .now)
        let ham = OrtakKayit.oku()
        var girdiler = [SayacGirdisi(date: .now, etkinlikler: OrtakKayit.sirala(ham))]
        for g in 1...7 {
            if let gun = takvim.date(byAdding: .day, value: g, to: bugun) {
                girdiler.append(SayacGirdisi(date: gun, etkinlikler: OrtakKayit.sirala(ham)))
            }
        }
        completion(Timeline(entries: girdiler, policy: .atEnd))
    }
}

struct GeriSayimWidgetGorunumu: View {
    @Environment(\.widgetFamily) private var boyut
    let girdi: SayacGirdisi

    var body: some View {
        let ilk = girdi.etkinlikler.first
        Group {
            switch boyut {
            case .systemMedium:
                OrtaSayacGorunumu(etkinlikler: girdi.etkinlikler)
            default:
                KucukSayacGorunumu(etkinlik: ilk)
            }
        }
        .containerBackground(for: .widget) {
            if let ilk {
                ilk.gradyan
            } else {
                LinearGradient(colors: Renkler.cift(1), startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
}

@main
struct GeriSayimWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GeriSayimWidget", provider: SayacSaglayici()) { girdi in
            GeriSayimWidgetGorunumu(girdi: girdi)
        }
        .configurationDisplayName("Geri Sayım")
        .description("En yakın etkinliğine kaç gün kaldığını gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
