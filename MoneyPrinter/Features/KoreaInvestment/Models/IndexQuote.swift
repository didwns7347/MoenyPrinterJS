import Foundation

struct OverseasIndexChartResponse: Decodable {
    let candles: [OverseasIndexCandle]
    let returnCode: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case candles = "output2"
        case returnCode = "rt_cd"
        case message = "msg1"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        candles = try container.decodeIfPresent([OverseasIndexCandle].self, forKey: .candles) ?? []
        returnCode = try container.decode(String.self, forKey: .returnCode)
        message = try container.decode(String.self, forKey: .message)
    }
}

struct OverseasIndexCandle: Decodable {
    let date: String
    let close: String
    let high: String

    enum CodingKeys: String, CodingKey {
        case date = "stck_bsop_date"
        case close = "ovrs_nmix_prpr"
        case high = "ovrs_nmix_hgpr"
    }
}

struct IndexDailyBar {
    let date: String
    let close: Double
    let high: Double
}
