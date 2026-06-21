import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var model: EraCheckModel

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("ERA CHECK")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(6)
                Text("10 questions. One verdict. Are you really who you think you are?")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            Spacer()
            Button(action: model.startQuiz) {
                Text("FIND YOUR ERA")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(18)
            }
            VStack(spacing: 6) {
                Button(action: { model.isShowingSettings = true }) {
                    Text("Remove Ads")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                Button(action: openMoreApps) {
                    Text("More Apps")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 16))
                }
                Button(action: openPrivacy) {
                    Text("Privacy & Data")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 14))
                }
            }
            .padding(.bottom, 32)
        }
        .padding(32)
    }

    private func openMoreApps() {
        openUrl("https://dudleyapps.com")
    }

    private func openPrivacy() {
        openUrl("https://dudleyapps.com/privacy")
    }

    private func openUrl(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}
