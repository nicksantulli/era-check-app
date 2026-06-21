import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: EraCheckModel
    @ObservedObject private var purchases = PurchaseManager.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
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
                if !purchases.isProUnlocked {
                    Button(action: { model.isShowingSettings = true }) {
                        Text("Remove Ads")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .underline()
                    }
                    .padding(.top, 8)
                }
            }
            .padding(32)

            Button {
                model.isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(12)
            }
            .accessibilityLabel("Open settings")
            .padding([.top, .trailing], 16)
        }
    }
}
