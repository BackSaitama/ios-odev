import Foundation
import Observation
import Photos
import UIKit

/// Bir aydaki fotoğrafların özeti (ay ay temizleme listesi için).
struct AyOzeti: Identifiable, Hashable {
    let yil: Int
    let ay: Int
    let kimlikler: [String]

    var id: String { "\(yil)-\(ay)" }
    var toplam: Int { kimlikler.count }

    var baslik: String {
        let adlar = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
                     "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
        return "\(adlar[ay - 1]) \(yil)"
    }

    static func == (a: AyOzeti, b: AyOzeti) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

/// Kaydırma ekranına hangi fotoğrafların geleceği.
enum Kaynak: Hashable {
    case karisik
    case ekranGoruntuleri
    case videolar
    case ay(AyOzeti)

    var baslik: String {
        switch self {
        case .karisik: return "Karışık"
        case .ekranGoruntuleri: return "Ekran görüntüleri"
        case .videolar: return "Videolar"
        case .ay(let ozet): return ozet.baslik
        }
    }
}

enum Karar {
    case sil
    case tut
}

/// Telefonda saklanan kalıcı bilgiler.
struct Kayit: Codable {
    var tutulanlar: Set<String> = []
    var copKutusu: [String] = []
    var acilanBayt: Int64 = 0
    var silinenSayisi: Int = 0
    var incelenenSayisi: Int = 0
}

@MainActor
@Observable
final class FotoDeposu {
    var izin: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    // Kaydırma ekranı
    var kuyruk: [PHAsset] = []
    var siradaki = 0
    var yukleniyor = false

    // Ana ekran özetleri
    var aylar: [AyOzeti] = []
    var ekranGoruntusuSayisi = 0
    var videoSayisi = 0
    var toplamSayi = 0

    private(set) var kayit = Kayit()
    private var gecmis: [(kimlik: String, karar: Karar)] = []
    @ObservationIgnored private var boyutlar: [String: Int64] = [:]

    init() {
        kayit = Self.oku()
    }

    // MARK: - İzin

    func izinIste() async {
        izin = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    var erisimVar: Bool { izin == .authorized || izin == .limited }

    // MARK: - Özetler

    func ozetleriYukle() async {
        guard erisimVar else { return }
        let sonuc = await Task.detached(priority: .userInitiated) { () -> (aylar: [AyOzeti], ekran: Int, video: Int, toplam: Int) in
            let secenek = PHFetchOptions()
            secenek.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let hepsi = PHAsset.fetchAssets(with: secenek)

            let takvim = Calendar.current
            var gruplar: [Int: [String]] = [:]   // yil * 100 + ay
            var sira: [Int] = []
            var ekran = 0
            var video = 0
            hepsi.enumerateObjects { varlik, _, _ in
                if varlik.mediaSubtypes.contains(.photoScreenshot) { ekran += 1 }
                if varlik.mediaType == .video { video += 1 }
                guard let tarih = varlik.creationDate else { return }
                let p = takvim.dateComponents([.year, .month], from: tarih)
                let anahtar = (p.year ?? 0) * 100 + (p.month ?? 1)
                if gruplar[anahtar] == nil { sira.append(anahtar) }
                gruplar[anahtar, default: []].append(varlik.localIdentifier)
            }
            let aylar = sira.map { AyOzeti(yil: $0 / 100, ay: $0 % 100, kimlikler: gruplar[$0] ?? []) }
            return (aylar, ekran, video, hepsi.count)
        }.value

        aylar = sonuc.aylar
        ekranGoruntusuSayisi = sonuc.ekran
        videoSayisi = sonuc.video
        toplamSayi = sonuc.toplam
    }

    func incelendiMi(_ kimlik: String) -> Bool {
        kayit.tutulanlar.contains(kimlik) || kayit.copKutusu.contains(kimlik)
    }

    func incelenenSayisi(_ ay: AyOzeti) -> Int {
        let cop = Set(kayit.copKutusu)
        return ay.kimlikler.reduce(0) { $0 + ((kayit.tutulanlar.contains($1) || cop.contains($1)) ? 1 : 0) }
    }

    // MARK: - Kaydırma

    var simdiki: PHAsset? { siradaki < kuyruk.count ? kuyruk[siradaki] : nil }
    var sonraki: PHAsset? { siradaki + 1 < kuyruk.count ? kuyruk[siradaki + 1] : nil }
    var geriAlinabilir: Bool { !gecmis.isEmpty }

    func baslat(_ kaynak: Kaynak) async {
        yukleniyor = true
        defer { yukleniyor = false }
        kuyruk = []
        siradaki = 0
        gecmis = []

        let cop = Set(kayit.copKutusu)
        let tutulan = kayit.tutulanlar
        let incelenmemis: (PHAsset) -> Bool = {
            !tutulan.contains($0.localIdentifier) && !cop.contains($0.localIdentifier)
        }

        switch kaynak {
        case .karisik:
            let hepsi = Self.getir(PHAsset.fetchAssets(with: PHFetchOptions()))
            kuyruk = Array(hepsi.filter(incelenmemis).shuffled().prefix(300))

        case .ekranGoruntuleri:
            let secenek = PHFetchOptions()
            secenek.predicate = NSPredicate(format: "(mediaSubtypes & %d) != 0",
                                            PHAssetMediaSubtype.photoScreenshot.rawValue)
            secenek.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            kuyruk = Self.getir(PHAsset.fetchAssets(with: .image, options: secenek)).filter(incelenmemis)

        case .videolar:
            let videolar = Self.getir(PHAsset.fetchAssets(with: .video, options: nil)).filter(incelenmemis)
            let kimlikler = videolar.map(\.localIdentifier)
            let olculen = await Task.detached(priority: .userInitiated) { () -> [String: Int64] in
                var sonuc: [String: Int64] = [:]
                let bulunan = PHAsset.fetchAssets(withLocalIdentifiers: kimlikler, options: nil)
                bulunan.enumerateObjects { varlik, _, _ in
                    sonuc[varlik.localIdentifier] = FotoDeposu.boyutHesapla(varlik)
                }
                return sonuc
            }.value
            boyutlar.merge(olculen) { _, yeni in yeni }
            kuyruk = videolar.sorted { (olculen[$0.localIdentifier] ?? 0) > (olculen[$1.localIdentifier] ?? 0) }

        case .ay(let ozet):
            let secenek = PHFetchOptions()
            secenek.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            kuyruk = Self.getir(PHAsset.fetchAssets(withLocalIdentifiers: ozet.kimlikler, options: secenek))
                .filter(incelenmemis)
        }
    }

    func karar(_ k: Karar) {
        guard let varlik = simdiki else { return }
        let kimlik = varlik.localIdentifier
        switch k {
        case .sil: kayit.copKutusu.append(kimlik)
        case .tut: kayit.tutulanlar.insert(kimlik)
        }
        kayit.incelenenSayisi += 1
        gecmis.append((kimlik, k))
        siradaki += 1
        kaydet()
    }

    func geriAl() {
        guard let son = gecmis.popLast() else { return }
        switch son.karar {
        case .sil: kayit.copKutusu.removeAll { $0 == son.kimlik }
        case .tut: kayit.tutulanlar.remove(son.kimlik)
        }
        kayit.incelenenSayisi = max(0, kayit.incelenenSayisi - 1)
        siradaki = max(0, siradaki - 1)
        kaydet()
    }

    // MARK: - Çöp kutusu

    var copVarliklari: [PHAsset] {
        let bulunan = Self.getir(PHAsset.fetchAssets(withLocalIdentifiers: kayit.copKutusu, options: nil))
        let sira = Dictionary(uniqueKeysWithValues: kayit.copKutusu.enumerated().map { ($1, $0) })
        return bulunan.sorted { (sira[$0.localIdentifier] ?? 0) > (sira[$1.localIdentifier] ?? 0) }
    }

    var copSayisi: Int { kayit.copKutusu.count }

    var copBoyutu: Int64 {
        copVarliklari.reduce(0) { $0 + boyut($1) }
    }

    /// Çöp kutusundan geri çıkarılan fotoğraf "kalsın" sayılır.
    func kurtar(_ kimlik: String) {
        kayit.copKutusu.removeAll { $0 == kimlik }
        kayit.tutulanlar.insert(kimlik)
        gecmis.removeAll { $0.kimlik == kimlik }
        kaydet()
    }

    /// iPhone silmeden önce kendi onayını sorar. Silinenler 30 gün "Son Silinenler"de kalır.
    func copuBosalt() async -> Int64? {
        let silinecek = copVarliklari
        guard !silinecek.isEmpty else {
            kayit.copKutusu = []
            kaydet()
            return 0
        }
        let toplam = silinecek.reduce(Int64(0)) { $0 + boyut($1) }
        let dizi = silinecek as NSArray
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(dizi)
            }
        } catch {
            return nil
        }
        let silinen = Set(silinecek.map(\.localIdentifier))
        kayit.copKutusu.removeAll { silinen.contains($0) }
        kayit.acilanBayt += toplam
        kayit.silinenSayisi += silinen.count
        gecmis.removeAll { silinen.contains($0.kimlik) }
        kaydet()
        await ozetleriYukle()
        return toplam
    }

    // MARK: - Boyut

    func boyut(_ varlik: PHAsset) -> Int64 {
        if let b = boyutlar[varlik.localIdentifier] { return b }
        let b = Self.boyutHesapla(varlik)
        boyutlar[varlik.localIdentifier] = b
        return b
    }

    nonisolated static func boyutHesapla(_ varlik: PHAsset) -> Int64 {
        PHAssetResource.assetResources(for: varlik).reduce(Int64(0)) { toplam, kaynak in
            toplam + ((kaynak.value(forKey: "fileSize") as? NSNumber)?.int64Value ?? 0)
        }
    }

    // MARK: - Yardımcılar

    nonisolated static func getir(_ sonuc: PHFetchResult<PHAsset>) -> [PHAsset] {
        var dizi: [PHAsset] = []
        dizi.reserveCapacity(sonuc.count)
        sonuc.enumerateObjects { varlik, _, _ in dizi.append(varlik) }
        return dizi
    }

    private static var dosya: URL {
        let klasor = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: klasor, withIntermediateDirectories: true)
        return klasor.appendingPathComponent("kayit.json")
    }

    private static func oku() -> Kayit {
        guard let veri = try? Data(contentsOf: dosya),
              let kayit = try? JSONDecoder().decode(Kayit.self, from: veri) else { return Kayit() }
        return kayit
    }

    private func kaydet() {
        if let veri = try? JSONEncoder().encode(kayit) {
            try? veri.write(to: Self.dosya, options: .atomic)
        }
    }
}

/// Fotoğraf küçük resimlerini yükler.
@MainActor
enum Gorsel {
    static let yonetici = PHCachingImageManager()

    static func yukle(_ varlik: PHAsset, boyut: CGSize) async -> UIImage? {
        await withCheckedContinuation { devam in
            let secenek = PHImageRequestOptions()
            secenek.deliveryMode = .highQualityFormat
            secenek.resizeMode = .fast
            secenek.isNetworkAccessAllowed = true
            yonetici.requestImage(for: varlik, targetSize: boyut, contentMode: .aspectFill, options: secenek) { resim, _ in
                devam.resume(returning: resim)
            }
        }
    }
}

extension Int64 {
    var okunur: String {
        let bicim = ByteCountFormatter()
        bicim.countStyle = .file
        bicim.allowsNonnumericFormatting = false
        return bicim.string(fromByteCount: self)
    }
}
