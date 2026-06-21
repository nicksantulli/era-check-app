import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var model: EraCheckModel

    var body: some View {
        VStack(spacing: 24) {
            if let question = model.currentQuestion {
                HStack {
                    Text("Q\(model.currentQuestionIndex + 1) of \(model.questions.count)")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                }
                Text(question.question)
                    .foregroundColor(.white)
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.leading)
                VStack(spacing: 12) {
                    ForEach(Array(question.answers.enumerated()), id: \.offset) { index, answer in
                        Button(action: { model.selectAnswer(at: index) }) {
                            HStack {
                                Text(answer.text)
                                    .foregroundColor(model.selectedAnswerIndex == index ? .black : .white)
                                    .font(.system(size: 18, weight: .semibold))
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding()
                            .background(model.selectedAnswerIndex == index ? Color.white : Color.white.opacity(0.08))
                            .cornerRadius(16)
                        }
                    }
                }
            }
            Spacer()
            Button(action: model.submitCurrentAnswer) {
                Text(model.currentQuestionIndex + 1 == model.questions.count ? "SEE MY ERA" : "NEXT")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(model.selectedAnswerIndex != nil ? Color.white : Color.gray.opacity(0.4))
                    .cornerRadius(16)
            }
            .disabled(model.selectedAnswerIndex == nil)
        }
        .padding(32)
    }
}
