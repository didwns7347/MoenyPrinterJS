import Foundation


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
