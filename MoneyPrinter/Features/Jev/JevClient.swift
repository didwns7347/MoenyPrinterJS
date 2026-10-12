import Foundation

final class JevClient {
    static let defaultModel = "jev-latest"
    static let environmentKey = "TYPESAFE_API_KEY"
    static let defaultBaseURL = URL(string: "https://api.typesafe.ai")!

    private let http: HTTPClient
    private let defaultModel: String

    init(
        apiKey: String,
        baseURL: URL = JevClient.defaultBaseURL,
        defaultModel: String = JevClient.defaultModel,
        timeout: TimeInterval = 30,
        maxRetries: Int = 3,
        session: URLSession? = nil
    ) {
        self.defaultModel = defaultModel
        self.http = HTTPClient(
            baseURL: baseURL,
            defaultHeaders: ["Authorization": "Bearer \(apiKey)"],
            timeout: timeout,
            retryPolicy: RetryPolicy(maxRetries: maxRetries, retryableStatusCodes: [429, 529]),
            requestIDHeader: "x-typesafe-request-id",
            session: session
        )
    }

    static func fromEnvironment(
        baseURL: URL = JevClient.defaultBaseURL,
        defaultModel: String = JevClient.defaultModel,
        timeout: TimeInterval = 30,
        maxRetries: Int = 3
    ) throws -> JevClient {
        guard let apiKey = resolvedAPIKey() else {
            throw JevError.missingAPIKey
        }
        return JevClient(
            apiKey: apiKey,
            baseURL: baseURL,
            defaultModel: defaultModel,
            timeout: timeout,
            maxRetries: maxRetries
        )
    }

    static func resolvedAPIKey() -> String? {
        let candidates = [
            Bundle.main.object(forInfoDictionaryKey: environmentKey) as? String,
            ProcessInfo.processInfo.environment[environmentKey],
        ]
        for candidate in candidates {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty, !trimmed.hasPrefix("$(") {
                return trimmed
            }
        }
        return nil
    }

    func systemOne<State: Encodable>(
        state: State,
        questions: [String: JevQuestion],
        model: String? = nil
    ) async throws -> JevSystemOneResponse {
        try validate(questions)
        let body = RequestBody(
            state: state,
            model: model ?? defaultModel,
            questions: questions
        )
        return try await http.post("v1/systemone", body: body)
    }

    func listModels() async throws -> [JevModelCard] {
        let list: JevModelList = try await http.get("v1/models")
        return list.models
    }

    private func validate(_ questions: [String: JevQuestion]) throws {
        guard !questions.isEmpty else {
            throw JevError.invalidQuestion("질문은 하나 이상 필요합니다.")
        }
        for (id, question) in questions {
            switch question {
            case .noul:
                continue
            case .choice(_, let criteria):
                guard !criteria.isEmpty else {
                    throw JevError.invalidQuestion("'\(id)' choice에는 선택지가 필요합니다.")
                }
                guard criteria.count <= 255 else {
                    throw JevError.invalidQuestion("'\(id)' choice 선택지는 255개를 넘을 수 없습니다.")
                }
            case .score(_, let criteria):
                guard (2...10).contains(criteria.count) else {
                    throw JevError.invalidQuestion("'\(id)' score 단계는 2개 이상 10개 이하여야 합니다.")
                }
            }
        }
    }
}

private struct RequestBody<State: Encodable>: Encodable {
    let state: State
    let model: String
    let questions: [String: JevQuestion]
}
