//
//  CashWeightRecord.swift
//  MoneyPrinter
//
//  Created by yangjs on 10/13/26.
//
import Foundation

/// Jev 현금 비중 판단. 이후 화면에서 과거 기록을 읽습니다.
struct CashWeightRecord: Codable, Identifiable {
    var id: String {
        "\(day)|\(snapshot.ticker)"
    }

    /// 서울 기준 날짜. `yyyy-MM-dd`
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
        responseJSON: String = ""
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
