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

        The portfolio is reviewed daily and has a long-term investment horizon. The objective is to participate in sustained market advances while reducing exposure during persistent downtrends and elevated market risk.

        Raise the ETF allocation once a recovery after a decline is confirmed, and lower it once upward momentum near a high is confirmed to be fading. Do not try to catch the exact bottom or the exact top.

        Evaluate the supplied indicators jointly:
        - Price relative to the 20-, 60-, and 200-trading-day moving averages
        - Direction of the 200-trading-day moving average over the prior 20 trading days
        - Returns over the prior 21, 63, and 126 trading days
        - Annualized volatility of daily returns over 20 and 60 trading days
        - Change from the highest high of the last 200 trading days
        - Histogram of the 12-trading-day exponential moving average minus the 26-trading-day exponential moving average, minus its 9-trading-day signal, as a percent of the closing price. Positive means the shorter upward pace is still above that signal.
        - Change of that histogram over the prior 5 trading days. Positive means momentum is strengthening, negative means it is fading.
        - Percent change of the 20-trading-day moving average over the prior 5 trading days
        - Trading days since the close last crossed the 60-trading-day moving average. Whether the close is now above or below that average is given by the price relative to the 60-trading-day moving average. If no cross occurred in the available history, the value is the number of trading days checked.

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

    /// 정규장 종가가 정해진 일봉만 씁니다.
    func makeSnapshot() async throws -> MarketSnapshot {
        switch self {
        case .kodexSP500:
            try await KoreaInvestmentAPIService.shared.makeKODEXUSSP500HSnapshot(closedOnly: true)
        case .kodex200:
            try await KoreaInvestmentAPIService.shared.makeKODEX200Snapshot(closedOnly: true)
        }
    }
}

/// Jev Score로 정한 현금 비중. 0은 전액 주식, 1은 전액 현금입니다.
struct CashWeight {
    static let questionID = "cash_weight"
    /// 같은 스냅샷으로 물어 평균을 내는 횟수.
    static let sampleCount = 3

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
        var samples: [CashWeightSample] = []
        var model = ""
        var requestJSON = ""
        var responseJSONs: [String] = []
        for _ in 0 ..< sampleCount {
            let (response, request, responseJSON) = try await client.systemOneRaw(
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
            samples.append(CashWeightSample(score: score, confidence: confidence, inputTokens: response.usage.inputTokens))
            model = response.model
            requestJSON = request
            responseJSONs.append(responseJSON)
        }
        let count = Double(samples.count)
        let weight = resolve(
            score: samples.map(\.score).reduce(0, +) / count,
            confidence: samples.map(\.confidence).reduce(0, +) / count
        )
        try store.save(
            CashWeightRecord(
                day: snapshot.asOf,
                calledAt: Date(),
                model: model,
                inputTokens: samples.map(\.inputTokens).reduce(0, +),
                snapshot: snapshot,
                fraction: weight.fraction,
                score: weight.score,
                confidence: weight.confidence,
                heldPrevious: weight.heldPrevious,
                previousFraction: previousFraction,
                requestJSON: requestJSON,
                responseJSON: "[\n" + responseJSONs.joined(separator: ",\n") + "\n]",
                samples: samples
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
