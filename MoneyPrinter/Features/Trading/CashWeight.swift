import Foundation

enum CashWeightMarket: String, CaseIterable, Identifiable {
    case kodexSP500
    case kodex200

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .kodexSP500: "KODEX SNP500(H)"
        case .kodex200: "KODEX 200"
        }
    }

    var ticker: String {
        switch self {
        case .kodexSP500: KoreaInvestmentAPIService.kodexUSSP500H
        case .kodex200: KoreaInvestmentAPIService.kodex200
        }
    }

    var question: String {
        """
        Determine the appropriate cash allocation for a portfolio invested in the \(instrumentName).

        Use only the supplied MarketSnapshot derived from daily prices. Do not use external data, fundamentals, news, or macroeconomic assumptions.

        The portfolio is reviewed weekly and has a long-term investment horizon. The objective is to participate in sustained market advances while reducing exposure during persistent downtrends and elevated market risk.

        Evaluate the supplied indicators jointly:
        - Price relative to the 20-, 60-, and 200-trading-day moving averages
        - Direction of the 200-trading-day moving average over the prior 20 trading days
        - Returns over the prior 21, 63, and 126 trading days
        - Annualized volatility of daily returns over 20 and 60 trading days
        - Change from the highest high of the last 200 trading days
        - Histogram of the 12-trading-day exponential moving average minus the 26-trading-day exponential moving average, minus its 9-trading-day signal, as a percent of the closing price. Positive means the shorter upward pace is still above that signal.

        Do not treat a high absolute price as evidence of overvaluation. Do not treat a recent decline alone as evidence that the market is cheap or that a rebound is imminent. Avoid counting correlated indicators as independent evidence.

        Select the cash allocation that best matches the overall technical market state, using the five defined criteria.
        """
    }

    private var instrumentName: String {
        switch self {
        case .kodexSP500: "KODEX U.S. S&P 500 currency-hedged ETF"
        case .kodex200: "KODEX 200 ETF"
        }
    }

    func makeSnapshot() async throws -> MarketSnapshot {
        switch self {
        case .kodexSP500:
            try await KoreaInvestmentAPIService.shared.makeKODEXUSSP500HSnapshot()
        case .kodex200:
            try await KoreaInvestmentAPIService.shared.makeKODEX200Snapshot()
        }
    }
}

/// Jev Score로 정한 현금 비중. 0은 전액 주식, 1은 전액 현금입니다.
struct CashWeight {
    static let questionID = "cash_weight"

    static let criteria = [
        "0% cash. Maximum allocation to the ETF.",
        "25% cash. High allocation to the ETF.",
        "50% cash. Balanced allocation between the ETF and cash.",
        "75% cash. Defensive allocation with a high cash reserve.",
        "100% cash. Maximum allocation to cash.",
    ]

    let fraction: Double
    let score: Double
    let confidence: Double
    /// confidence가 문턱 미만이라 어제 비중을 유지했습니다.
    let heldPrevious: Bool

    static func ask(
        snapshot: MarketSnapshot,
        previousFraction: Double,
        client: JevClient,
        question: String,
        store: CashWeightStore? = nil
    ) async throws -> CashWeight {
        let store = store ?? CashWeightStore.shared
        let day = CashWeightStore.seoulDay()
        let (response, requestJSON, responseJSON) = try await client.systemOneRaw(
            state: snapshot,
            questions: [
                questionID: .score(question, criteria: criteria),
            ]
        )
        guard let answer = response.answers[questionID],
              let score = answer.score,
              let confidence = answer.confidence
        else {
            throw CashWeightError.missingScore
        }
        let weight = resolve(score: score, confidence: confidence)
        try store.save(
            CashWeightRecord(
                day: day,
                calledAt: Date(),
                model: response.model,
                inputTokens: response.usage.inputTokens,
                snapshot: snapshot,
                fraction: weight.fraction,
                score: weight.score,
                confidence: weight.confidence,
                heldPrevious: weight.heldPrevious,
                previousFraction: previousFraction,
                requestJSON: requestJSON,
                responseJSON: responseJSON
            )
        )
        return weight
    }

    static func resolve(score: Double, confidence: Double) -> CashWeight {
        let upper = Double(criteria.count - 1)
        let fraction = clamp(score / upper)
        return CashWeight(fraction: fraction, score: score, confidence: confidence, heldPrevious: false)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

enum CashWeightError: LocalizedError {
    case missingScore
    case failedToSave(String)

    var errorDescription: String? {
        switch self {
        case .missingScore:
            return "Jev 응답에 현금 비중 Score가 없습니다."
        case .failedToSave(let message):
            return "현금 비중 기록을 저장하지 못했습니다: \(message)"
        }
    }
}
