import SwiftUI
import UIKit

@main
struct KararApp: App {
    @State private var depo = KararDeposu()

    var body: some Scene {
        WindowGroup {
            AnaEkran()
                .environment(depo)
                .tint(Tema.vurgu)
        }
    }
}

// MARK: - Telefonu sallama algılama

extension Notification.Name {
    static let telefonSallandi = Notification.Name("telefonSallandi")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .telefonSallandi, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

struct Sallaninca: ViewModifier {
    let eylem: () -> Void

    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: .telefonSallandi)) { _ in eylem() }
    }
}

extension View {
    func sallaninca(_ eylem: @escaping () -> Void) -> some View { modifier(Sallaninca(eylem: eylem)) }
}
