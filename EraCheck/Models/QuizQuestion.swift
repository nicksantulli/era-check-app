import Foundation

struct QuizQuestion: Identifiable, Codable {
    let id: Int
    let question: String
    let answers: [QuizAnswer]
}

struct QuizAnswer: Hashable {
    let text: String
    let weights: [EraID: Int]
}

extension QuizAnswer: Codable {
    enum CodingKeys: String, CodingKey {
        case text
        case weights
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        let rawWeights = try container.decode([String: Int].self, forKey: .weights)
        var mapped: [EraID: Int] = [:]
        for (key, value) in rawWeights {
            if let era = EraID(rawValue: key) {
                mapped[era] = value
            }
        }
        weights = mapped
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        var rawWeights: [String: Int] = [:]
        for (key, value) in weights {
            rawWeights[key.rawValue] = value
        }
        try container.encode(rawWeights, forKey: .weights)
    }
}
