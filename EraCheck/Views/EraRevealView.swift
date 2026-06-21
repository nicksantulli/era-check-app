import SwiftUI

struct EraRevealView: View {
    @EnvironmentObject private var model: EraCheckModel

    var body: some View {
        if let result = model.result {
            let fg = result.primary.textColor
            let fgSoft = fg.opacity(0.85)
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.title)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(fg)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)
                    Text(result.subtitle)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(fgSoft)
                        .tracking(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 60)
                Text(result.description)
                    .foregroundColor(fgSoft)
                    .font(.system(size: 19, weight: .regular))
                    .lineSpacing(4)
                    .lineLimit(6)
                Spacer()
                VStack(spacing: 12) {
                    Button(action: model.generateShareCard) {
                        Text("SHARE THIS ERA")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(result.primary.displayColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(fg)
                            .cornerRadius(16)
                    }
                    Button(action: model.retake) {
                        Text("RETAKE")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(fg)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 16).stroke(fg.opacity(0.5), lineWidth: 2)
                            )
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(32)
            .overlay(alignment: .center) {
                if model.isRenderingShareCard {
                    ProgressView("Preparing card...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                }
            }
        }
    }
}
