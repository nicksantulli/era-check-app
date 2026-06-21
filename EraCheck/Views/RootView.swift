import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: EraCheckModel

    private var backgroundColor: Color {
        if model.phase == .result, let result = model.result {
            return result.primary.displayColor
        }
        return EraTheme.background
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
                .animation(.easeOut(duration: 0.4), value: model.phase)
            switch model.phase {
            case .home:
                HomeView()
                    .transition(.opacity)
            case .quiz:
                QuizView()
                    .transition(.opacity)
            case .result:
                EraRevealView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: model.phase)
        .sheet(isPresented: $model.isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $model.isShareSheetPresented, onDismiss: { model.isShareSheetPresented = false }) {
            if let image = model.shareImage {
                ShareSheet(activityItems: [image])
            } else {
                Text("Preparing share card...")
            }
        }
    }
}
