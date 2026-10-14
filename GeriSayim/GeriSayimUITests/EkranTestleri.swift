import XCTest

/// Bulut Mac'te uygulamayı gerçek kullanıcı gibi gezip her adımda ekran görüntüsü alır.
final class EkranTestleri: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = true
    }

    func testBos() throws {
        app.launchArguments = ["-UITest"]
        app.launch()
        sleep(2)
        cek("0-bos")
    }

    func testAkis() throws {
        app.launchArguments = ["-UITest", "-ornekVeri"]
        app.launch()
        XCTAssertTrue(app.staticTexts["EN YAKIN"].waitForExistence(timeout: 10))
        sleep(1)
        cek("1-ana-ekran")

        app.swipeUp()
        sleep(1)
        cek("2-asagi")
        app.swipeUp()
        sleep(1)
        cek("3-widget")
        app.swipeDown()
        app.swipeDown()

        app.buttons["Etkinlik ekle"].tap()
        sleep(1)
        let hazir = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Cumhuriyet'")).firstMatch
        if hazir.waitForExistence(timeout: 3) { hazir.tap() }
        sleep(1)
        cek("4-form")
    }

    private func cek(_ ad: String) {
        let ek = XCTAttachment(screenshot: app.screenshot())
        ek.name = ad
        ek.lifetime = .keepAlways
        add(ek)
    }
}
