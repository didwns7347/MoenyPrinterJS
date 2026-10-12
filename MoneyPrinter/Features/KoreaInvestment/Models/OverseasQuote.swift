import Foundation

struct OverseasStockPriceInfo: Codable {
    let priceHistories: [OverseasDailyStockPrice]
    let returnCode: String
    let messageCode: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case priceHistories = "output2"
        case returnCode = "rt_cd"
        case messageCode = "msg_cd"
        case message = "msg1"
    }
}

struct OverseasDailyStockPrice: Codable {
    let date: String
    let closingPrice: String
    let changeSign: String
    let differenceFromPreviousDay: String
    let changeRate: String
    let openingPrice: String
    let highPrice: String
    let lowPrice: String
    let tradingVolume: String
    let tradingAmount: String
    let priceBid: String
    let volumeBid: String
    let priceAsk: String
    let volumeAsk: String

    private enum CodingKeys: String, CodingKey {
        case date = "xymd"
        case closingPrice = "clos"
        case changeSign = "sign"
        case differenceFromPreviousDay = "diff"
        case changeRate = "rate"
        case openingPrice = "open"
        case highPrice = "high"
        case lowPrice = "low"
        case tradingVolume = "tvol"
        case tradingAmount = "tamt"
        case priceBid = "pbid"
        case volumeBid = "vbid"
        case priceAsk = "pask"
        case volumeAsk = "vask"
    }
}
