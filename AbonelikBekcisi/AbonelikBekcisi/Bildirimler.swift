import Foundation
import UserNotifications

/// Yenilenmeden bir gün önce (saat 10:00) hatırlatma kurar.
enum Bildirimler {
    static func izinIste() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func planla(_ abonelikler: [Abonelik]) {
        let merkez = UNUserNotificationCenter.current()
        merkez.removeAllPendingNotificationRequests()
        let takvim = Calendar.current

        // iOS en fazla 64 bekleyen bildirime izin verir; en yakınları seç.
        let sirali = abonelikler.sorted { $0.sonrakiYenilenme < $1.sonrakiYenilenme }.prefix(60)
        for a in sirali {
            guard let oncekiGun = takvim.date(byAdding: .day, value: -1, to: a.sonrakiYenilenme) else { continue }
            var zaman = takvim.dateComponents([.year, .month, .day], from: oncekiGun)
            zaman.hour = 10
            guard let tarih = takvim.date(from: zaman), tarih > .now else { continue }

            let icerik = UNMutableNotificationContent()
            if a.denemeMi {
                icerik.title = "\(a.ad) denemen yarın bitiyor ⚠️"
                icerik.body = "İptal etmezsen yarın \(a.ucret.tl) çekilecek."
            } else {
                icerik.title = "\(a.ad) yarın yenileniyor"
                icerik.body = a.kullanim == .cok
                    ? "\(a.ucret.tl) çekilecek."
                    : "\(a.ucret.tl) çekilecek. \(a.kullanim == .hic ? "Hiç" : "Az") kullandığını söylemiştin, iptal etmeyi düşünür müsün?"
            }
            icerik.sound = .default

            let tetik = UNCalendarNotificationTrigger(dateMatching: zaman, repeats: false)
            merkez.add(UNNotificationRequest(identifier: a.id.uuidString, content: icerik, trigger: tetik))
        }
    }
}
