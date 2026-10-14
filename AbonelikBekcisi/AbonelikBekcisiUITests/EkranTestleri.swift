import XCTest

/// Bulut Mac'te uygulamayı gerçek kullanıcı gibi gezip her adımda ekran görüntüsü alır.
final class EkranTestleri: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = true
    }

    func testBosEkran() throws {
        app.launch()
        sleep(2)
        cek("0-bos")
    }

    func testAkis() throws {
        app.launchArguments = ["-ornekVeri"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Aylık toplam"].waitForExistence(timeout: 10))
        sleep(1)
        cek("1-ana-ekran")

        app.swipeUp()
        sleep(1)
        cek("2-liste")
        app.swipeDown()

        app.buttons["Abonelik ekle"].tap()
        sleep(2)
        cek("3-hazir-liste")

        let spotify = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Disney+'")).firstMatch
        XCTAssertTrue(spotify.waitForExistence(timeout: 5))
        spotify.tap()
        sleep(1)
        app.typeText("349,99")
        sleep(1)
        cek("4-form")

        app.buttons["Kaydet"].tap()
        izinVer()
        sleep(2)
        cek("5-eklendi")

        let satir = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Netflix'")).firstMatch
        if satir.waitForExistence(timeout: 3) {
            satir.tap()
            sleep(2)
            cek("6-duzenle")
        }
    }

    private func izinVer() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let uyari = springboard.alerts.firstMatch
        guard uyari.waitForExistence(timeout: 5) else { return }
        let izin = uyari.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Allow' OR label CONTAINS[c] 'İzin'")).firstMatch
        if izin.exists { izin.tap() } else { uyari.buttons.element(boundBy: 1).tap() }
    }

    private func cek(_ ad: String) {
        let ek = XCTAttachment(screenshot: app.screenshot())
        ek.name = ad
        ek.lifetime = .keepAlways
        add(ek)
    }
}
