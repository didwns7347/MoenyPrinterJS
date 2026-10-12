import Foundation

/// Jev 현금 비중 판단. 이후 화면에서 과거 기록을 읽습니다.
struct CashWeightRecord: Codable, Identifiable {
    var id: String { "\(day)|\(snapshot.ticker)" }
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

final class CashWeightStore {
    static let shared = CashWeightStore()

    private var records: [String: CashWeightRecord] = [:]
    private var didLoad = false
    private var needsFlush = false
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func seoulDay(for date: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    func record(on day: String, ticker: String) -> CashWeightRecord? {
        loadIfNeeded()
        return records[Self.storageKey(day: day, ticker: ticker)]
    }

    /// 최근 판단이 앞에 옵니다.
    func history(ticker: String) -> [CashWeightRecord] {
        loadIfNeeded()
        return records.values
            .filter { $0.snapshot.ticker == ticker }
            .sorted { $0.day > $1.day }
    }

    func save(_ record: CashWeightRecord) throws {
        loadIfNeeded()
        records[Self.storageKey(day: record.day, ticker: record.snapshot.ticker)] = record
        needsFlush = true
        try flush()
    }

    /// 저장이 실패해도 메모리의 최신 기록은 남아 있습니다. 다음 저장 때 파일 쓰기를 다시 시도합니다.
    func flush() throws {
        guard needsFlush else { return }
        do {
            let folder = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try encoder.encode(Array(records.values)).write(to: fileURL, options: .atomic)
            needsFlush = false
        } catch {
            throw CashWeightError.failedToSave(error.localizedDescription)
        }
    }

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base
            .appendingPathComponent("MoneyPrinter", isDirectory: true)
            .appendingPathComponent("cash-weights.json")
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([CashWeightRecord].self, from: data) else { return }
        for record in decoded {
            records[Self.storageKey(day: record.day, ticker: record.snapshot.ticker)] = record
        }
    }

    private static func storageKey(day: String, ticker: String) -> String {
        "\(day)|\(ticker)"
    }
}
