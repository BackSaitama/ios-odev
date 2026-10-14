import SwiftUI

@main
struct AbonelikApp: App {
    @State private var depo = AbonelikDeposu()

    var body: some Scene {
        WindowGroup {
            AnaEkran()
                .environment(depo)
                .tint(Tema.vurgu)
        }
    }
}
