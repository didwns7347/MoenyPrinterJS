import Foundation

enum JevValue: Encodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JevValue])
    case array([JevValue])
    case null

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

enum JevInstructions: Encodable {
    case text(String)
    case object([String: JevValue])
    case list([JevValue])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text):
            try container.encode(text)
        case .object(let object):
            try container.encode(object)
        case .list(let list):
            try container.encode(list)
        }
    }
}

struct JevNoulCriteria: Encodable {
    var yes: String?
    var no: String?

    enum CodingKeys: String, CodingKey {
        case yes = "true"
        case no = "false"
    }
}

enum JevQuestion: Encodable {
    case noul(instructions: JevInstructions, criteria: JevNoulCriteria?)
    case choice(instructions: JevInstructions, criteria: [String: String?])
    case score(instructions: JevInstructions, criteria: [String])

    static func noul(
        _ instructions: String,
        yes: String? = nil,
        no: String? = nil
    ) -> JevQuestion {
        let criteria = (yes == nil && no == nil) ? nil : JevNoulCriteria(yes: yes, no: no)
        return .noul(instructions: .text(instructions), criteria: criteria)
    }

    static func choice(_ instructions: String, criteria: [String: String?]) -> JevQuestion {
        .choice(instructions: .text(instructions), criteria: criteria)
    }

    static func score(_ instructions: String, criteria: [String]) -> JevQuestion {
        .score(instructions: .text(instructions), criteria: criteria)
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case instructions
        case criteria
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .noul(let instructions, let criteria):
            try container.encode("noul", forKey: .type)
            try container.encode(instructions, forKey: .instructions)
            try container.encodeIfPresent(criteria, forKey: .criteria)
        case .choice(let instructions, let criteria):
            try container.encode("choice", forKey: .type)
            try container.encode(instructions, forKey: .instructions)
            try container.encode(ChoiceCriteria(options: criteria), forKey: .criteria)
        case .score(let instructions, let criteria):
            try container.encode("score", forKey: .type)
            try container.encode(instructions, forKey: .instructions)
            try container.encode(criteria, forKey: .criteria)
        }
    }
}

private struct ChoiceCriteria: Encodable {
    let options: [String: String?]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        for (key, value) in options {
            let codingKey = DynamicCodingKey(key)
            if let value {
                try container.encode(value, forKey: codingKey)
            } else {
                try container.encodeNil(forKey: codingKey)
            }
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }

    init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}

enum JevAnswer: Decodable {
    case noul(Double)
    case choice(choice: String, confidence: Double, probabilities: [String: Double])
    case score(
        score: Double,
        confidence: Double,
        legend: [String: String],
        probabilities: [String: Double]
    )

    var noul: Double? {
        switch self {
        case .noul(let value):
            value
        default:
            nil
        }
    }

    var choice: String? {
        switch self {
        case .choice(let choice, _, _):
            choice
        default:
            nil
        }
    }

    var score: Double? {
        switch self {
        case .score(let score, _, _, _):
            score
        default:
            nil
        }
    }

    var confidence: Double? {
        switch self {
        case .noul:
            nil
        case .choice(_, let confidence, _):
            confidence
        case .score(_, let confidence, _, _):
            confidence
        }
    }

    var probabilities: [String: Double]? {
        switch self {
        case .noul:
            nil
        case .choice(_, _, let probabilities):
            probabilities
        case .score(_, _, _, let probabilities):
            probabilities
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case noul
        case choice
        case confidence
        case probabilities
        case score
        case legend
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "noul":
            self = .noul(try container.decode(Double.self, forKey: .noul))
        case "choice":
            self = .choice(
                choice: try container.decode(String.self, forKey: .choice),
                confidence: try container.decode(Double.self, forKey: .confidence),
                probabilities: try container.decode([String: Double].self, forKey: .probabilities)
            )
        case "score":
            self = .score(
                score: try container.decode(Double.self, forKey: .score),
                confidence: try container.decode(Double.self, forKey: .confidence),
                legend: try container.decode([String: String].self, forKey: .legend),
                probabilities: try container.decode([String: Double].self, forKey: .probabilities)
            )
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "알 수 없는 답변 타입입니다: \(type)"
            )
        }
    }
}

struct JevUsage: Decodable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct JevSystemOneResponse: Decodable {
    let model: String
    let answers: [String: JevAnswer]
    let usage: JevUsage
}

struct JevModelCard: Decodable {
    let name: String
    let description: String?
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case releaseDate = "release_date"
    }
}

struct JevModelList: Decodable {
    let models: [JevModelCard]
}

enum JevError: LocalizedError {
    case missingAPIKey
    case invalidQuestion(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "TYPESAFE_API_KEY가 없습니다. JevSecrets.example.xcconfig를 JevSecrets.xcconfig로 복사한 뒤 키를 넣어 주세요."
        case .invalidQuestion(let message):
            return message
        }
    }
}
