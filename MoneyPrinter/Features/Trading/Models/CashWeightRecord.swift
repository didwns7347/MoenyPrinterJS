//
//  CashWeightRecord.swift
//  MoneyPrinter
//
//  Created by yangjs on 10/13/26.
//
import Foundation

/// 같은 스냅샷으로 Jev에 한 번 물은 답.
struct CashWeightSample: Codable {
    let score: Double
    let confidence: Double
    let inputTokens: Int
}

/// Jev 현금 비중 판단. 이후 화면에서 과거 기록을 읽습니다.
struct CashWeightRecord: Codable, Identifiable {
    var id: String {
        "\(day)|\(snapshot.ticker)"
    }

    /// 판단에 쓴 종가의 거래일. `yyyy-MM-dd`. 거래일 기준으로 바꾸기 전 기록은 호출한 서울 날짜입니다.
    let day: String
    let calledAt: Date
    let model: String
    let inputTokens: Int
    let snapshot: MarketSnapshot
    let fraction: Double
    let score: Double
    let confidence: Double
    let heldPrevious: Bool
    let previousFraction: Double
    /// Jev에 보낸 요청 원문. 이 필드를 저장하기 전의 기록은 빈 문자열입니다.
    let requestJSON: String
    /// Jev가 돌려준 응답 원문. 이 필드를 저장하기 전의 기록은 빈 문자열입니다.
    let responseJSON: String
    /// `score`와 `confidence`는 이 답들의 평균입니다. 여러 번 묻기 전의 기록은 비어 있습니다.
    let samples: [CashWeightSample]

    private enum CodingKeys: String, CodingKey {
        case day
        case calledAt
        case model
        case inputTokens
        case snapshot
        case fraction
        case score
        case confidence
        case heldPrevious
        case previousFraction
        case requestJSON
        case responseJSON
        case samples
    }

    init(
        day: String,
        calledAt: Date,
        model: String,
        inputTokens: Int,
        snapshot: MarketSnapshot,
        fraction: Double,
        score: Double,
        confidence: Double,
        heldPrevious: Bool,
        previousFraction: Double,
        requestJSON: String = "",
        responseJSON: String = "",
        samples: [CashWeightSample] = []
    ) {
        self.day = day
        self.calledAt = calledAt
        self.model = model
        self.inputTokens = inputTokens
        self.snapshot = snapshot
        self.fraction = fraction
        self.score = score
        self.confidence = confidence
        self.heldPrevious = heldPrevious
        self.previousFraction = previousFraction
        self.requestJSON = requestJSON
        self.responseJSON = responseJSON
        self.samples = samples
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decode(String.self, forKey: .day)
        calledAt = try container.decode(Date.self, forKey: .calledAt)
        model = try container.decode(String.self, forKey: .model)
        inputTokens = try container.decode(Int.self, forKey: .inputTokens)
        snapshot = try container.decode(MarketSnapshot.self, forKey: .snapshot)
        fraction = try container.decode(Double.self, forKey: .fraction)
        score = try container.decode(Double.self, forKey: .score)
        confidence = try container.decode(Double.self, forKey: .confidence)
        heldPrevious = try container.decode(Bool.self, forKey: .heldPrevious)
        previousFraction = try container.decode(Double.self, forKey: .previousFraction)
        requestJSON = try container.decodeIfPresent(String.self, forKey: .requestJSON) ?? ""
        responseJSON = try container.decodeIfPresent(String.self, forKey: .responseJSON) ?? ""
        samples = try container.decodeIfPresent([CashWeightSample].self, forKey: .samples) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(day, forKey: .day)
        try container.encode(calledAt, forKey: .calledAt)
        try container.encode(model, forKey: .model)
        try container.encode(inputTokens, forKey: .inputTokens)
        try container.encode(snapshot, forKey: .snapshot)
        try container.encode(fraction, forKey: .fraction)
        try container.encode(score, forKey: .score)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(heldPrevious, forKey: .heldPrevious)
        try container.encode(previousFraction, forKey: .previousFraction)
        try container.encode(requestJSON, forKey: .requestJSON)
        try container.encode(responseJSON, forKey: .responseJSON)
        try container.encode(samples, forKey: .samples)
    }

    var weight: CashWeight {
        CashWeight(
            fraction: fraction,
            score: score,
            confidence: confidence,
            heldPrevious: heldPrevious
        )
    }
}
