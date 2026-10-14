import XCTest

/// Bulut Mac'te uygulamayı gerçek kullanıcı gibi gezip her adımda ekran görüntüsü alır.
final class EkranTestleri: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = true
    }

    func testAkis() throws {
        app.launch()
        let liste = app.buttons.containing(NSPredicate(format: "label CONTAINS 'ne yesem'")).firstMatch
        XCTAssertTrue(liste.waitForExistence(timeout: 10))
        sleep(1)
        cek("1-ana-ekran")

        liste.tap()
        sleep(1)
        cek("2-liste")

        let kararVer = app.buttons["Karar ver"]
        XCTAssertTrue(kararVer.waitForExistence(timeout: 5))
        kararVer.tap()
        usleep(600_000)
        cek("3-donuyor")
        sleep(4)
        cek("4-sonuc")

        app.buttons["Beğendim"].tap()
        sleep(1)
        kararVer.tap()
        sleep(5)
        app.swipeUp()
        sleep(1)
        cek("5-gecmis")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        app.buttons.containing(NSPredicate(format: "label CONTAINS 'Yeni liste'")).firstMatch.tap()
        sleep(1)
        app.textFields.firstMatch.tap()
        app.typeText("Bugün ne giysem?")
        let yeni = app.textFields["Yeni seçenek"]
        for s in ["Kot ve tişört", "Eşofman", "Gömlek"] {
            yeni.tap()
            app.typeText(s + "\n")
        }
        sleep(1)
        cek("6-yeni-liste")
    }

    private func cek(_ ad: String) {
        let ek = XCTAttachment(screenshot: app.screenshot())
        ek.name = ad
        ek.lifetime = .keepAlways
        add(ek)
    }
}
