import SwiftUI

@main
struct EraCheckApp: App {
    @StateObject private var model = EraCheckModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            StudioIntroGate {
                RootView()
                    .environmentObject(model)
                    .preferredColorScheme(.dark)
                    .task {
                        _ = PurchaseManager.shared
                        #if canImport(GoogleMobileAds)
                        AdManager.shared.start()
                        #endif
                    }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                model.resetAdSession()
            }
        }
    }
}
