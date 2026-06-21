import SwiftUI
import UIKit

private let kAdShownThisSession = "adShownThisSession"
private let kTotalQuizzesTaken = "totalQuizzesTaken"

enum EraPhase: Equatable {
    case home
    case quiz
    case result
}

struct EraResult {
    let primary: EraProfile
    let secondary: EraProfile?

    var title: String {
        if let secondary { return "\(primary.name) with \(secondary.name) energy" }
        return primary.name
    }

    var subtitle: String { primary.tagline.uppercased() }
    var description: String {
        if let secondary {
            return "You're a \(primary.name) with \(secondary.name) energy. \(primary.blurb)"
        }
        return primary.blurb
    }
}

@MainActor
final class EraCheckModel: ObservableObject {
    @Published var phase: EraPhase = .home
    @Published var questions: [QuizQuestion] = []
    @Published var profiles: [EraID: EraProfile] = [:]
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswerIndex: Int?
    @Published var eraScores: [EraID: Int] = [:]
    @Published var result: EraResult?
    @Published var isShowingSettings = false
    @Published var shareImage: UIImage?
    @Published var isRenderingShareCard = false
    @Published var isShareSheetPresented = false
    @Published var totalQuizzesTaken: Int {
        didSet { UserDefaults.standard.set(totalQuizzesTaken, forKey: kTotalQuizzesTaken) }
    }
    @Published var adShownThisSession: Bool {
        didSet { UserDefaults.standard.set(adShownThisSession, forKey: kAdShownThisSession) }
    }
    private let launchArguments = ProcessInfo.processInfo.arguments

    init() {
        totalQuizzesTaken = UserDefaults.standard.integer(forKey: kTotalQuizzesTaken)
        adShownThisSession = UserDefaults.standard.bool(forKey: kAdShownThisSession)
        loadContent()
    }

    var currentQuestion: QuizQuestion? {
        questions[safe: currentQuestionIndex]
    }

    func startQuiz() {
        resetSessionState()
        phase = .quiz
    }

    func selectAnswer(at index: Int) {
        selectedAnswerIndex = index
    }

    func submitCurrentAnswer() {
        guard let question = currentQuestion, let index = selectedAnswerIndex else { return }
        guard question.answers.indices.contains(index) else { return }
        let answer = question.answers[index]
        apply(score: answer)
        selectedAnswerIndex = nil
        currentQuestionIndex += 1
        if currentQuestionIndex >= questions.count {
            finalizeResult()
        }
    }

    func retake() {
        startQuiz()
    }

    func generateShareCard() {
        guard let result else { return }
        isRenderingShareCard = true
        Task { @MainActor in
            shareImage = EraShareCardRenderer.render(result: result)
            isRenderingShareCard = false
            isShareSheetPresented = shareImage != nil
        }
    }

    func resetAdSession() {
        adShownThisSession = false
    }

    private func loadContent() {
        profiles = (try? loadProfiles())?.reduce(into: [:]) { $0[$1.id] = $1 } ?? [:]
        questions = (try? loadQuestions()) ?? []
    }

    private func apply(score answer: QuizAnswer) {
        for (era, points) in answer.weights {
            eraScores[era, default: 0] += points
        }
    }

    private func finalizeResult() {
        guard !eraScores.isEmpty else {
            phase = .home
            return
        }
        let sorted = eraScores.sorted { $0.value > $1.value }
        guard let top = sorted.first, let primary = profiles[top.key] else {
            phase = .home
            return
        }
        var secondary: EraProfile? = nil
        if sorted.count > 1, let tie = profiles[sorted[1].key], top.value - sorted[1].value <= 2 {
            secondary = tie
        }
        result = EraResult(primary: primary, secondary: secondary)
        totalQuizzesTaken += 1
        phase = .result
        maybeShowInterstitial()
    }

    private func maybeShowInterstitial() {
        // UI tests must run deterministic core flows without ad overlays.
        guard !launchArguments.contains("-skipInterstitialAds") else { return }
        guard !PurchaseManager.shared.isProUnlocked else { return }
        guard !adShownThisSession else { return }
        #if canImport(GoogleMobileAds)
        Task { @MainActor in
            await AdManager.shared.presentInterstitial()
            adShownThisSession = true
        }
        #else
        adShownThisSession = true
        #endif
    }

    private func resetSessionState() {
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        eraScores = [:]
        result = nil
    }

    private func loadProfiles() throws -> [EraProfile] {
        let decoder = JSONDecoder()
        guard let url = Bundle.main.url(forResource: "era-profiles", withExtension: "json") else {
            throw NSError(domain: "EraCheck", code: 1)
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode([EraProfile].self, from: data)
    }

    private func loadQuestions() throws -> [QuizQuestion] {
        let decoder = JSONDecoder()
        guard let url = Bundle.main.url(forResource: "quiz-questions", withExtension: "json") else {
            throw NSError(domain: "EraCheck", code: 2)
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode([QuizQuestion].self, from: data)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
