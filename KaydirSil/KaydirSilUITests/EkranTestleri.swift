import XCTest

/// Bulut Mac'te uygulamayı gerçek kullanıcı gibi gezip her adımda ekran görüntüsü alır.
final class EkranTestleri: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = true
    }

    func testAkis() throws {
        app.launch()
        cek("1-karsilama")

        let basla = app.buttons["Başlayalım"]
        if basla.waitForExistence(timeout: 5) {
            basla.tap()
            izinVer()
        }

        let karisik = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Karışık'")).firstMatch
        XCTAssertTrue(karisik.waitForExistence(timeout: 15), "Ana ekran açılmadı")
        sleep(2)
        cek("2-ana-ekran")

        karisik.tap()
        sleep(3)
        cek("3-kart")

        app.swipeLeft()
        sleep(2)
        app.swipeRight()
        sleep(2)
        app.swipeLeft()
        sleep(2)
        cek("4-kaydirildi")

        let cop = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Çöp kutusu'")).firstMatch
        if cop.waitForExistence(timeout: 3) {
            cop.tap()
            sleep(3)
            cek("5-cop-kutusu")
        }
    }

    private func izinVer() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let uyari = springboard.alerts.firstMatch
        guard uyari.waitForExistence(timeout: 8) else { return }
        cek("izin-sorusu", uygulama: springboard)
        let tamIzin = uyari.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'Full' OR label CONTAINS[c] 'All Photos' OR label CONTAINS[c] 'Tüm'"
        )).firstMatch
        if tamIzin.exists {
            tamIzin.tap()
        } else {
            uyari.buttons.element(boundBy: 1).tap()
        }
        // Bazı iOS sürümleri ikinci bir onay sorar.
        let ikinci = springboard.alerts.firstMatch
        if ikinci.waitForExistence(timeout: 3) {
            let onay = ikinci.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Allow' OR label CONTAINS[c] 'İzin'")).firstMatch
            if onay.exists { onay.tap() }
        }
    }

    private func cek(_ ad: String, uygulama: XCUIApplication? = nil) {
        let ek = XCTAttachment(screenshot: (uygulama ?? app).screenshot())
        ek.name = ad
        ek.lifetime = .keepAlways
        add(ek)
    }
}
