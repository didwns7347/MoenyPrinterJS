import Foundation

struct DomesticStockBalanceResponse: Decodable {
    let stockList: [DomesticStockInfo]?
    let accountSummary: [DomesticAccountSummaryResponse]?
    let returnCode: String
    let messageCode: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case stockList = "output1"
        case accountSummary = "output2"
        case returnCode = "rt_cd"
        case messageCode = "msg_cd"
        case message = "msg1"
    }

    var isSuccess: Bool {
        returnCode == "0"
    }
}

struct DomesticStockInfo: Codable {
    let code: String?
    let name: String
    let gainLoss: String
    let gainLossRate: String
    let currentPrice: String
    let avgBuyingPrice: String
    let totalCurrentPrice: String
    let totalBuyingPrice: String
    let quantity: String

    enum CodingKeys: String, CodingKey {
        case code = "pdno"
        case name = "prdt_name"
        case gainLoss = "evlu_pfls_amt"
        case gainLossRate = "evlu_pfls_rt"
        case currentPrice = "prpr"
        case avgBuyingPrice = "pchs_avg_pric"
        case totalCurrentPrice = "evlu_amt"
        case totalBuyingPrice = "pchs_amt"
        case quantity = "hldg_qty"
    }
}

struct DomesticAccountSummaryResponse: Codable {
    let totalAmount: String
    let totalGainLoss: String
    let totalGainLossRate: String
    let orderableCash: String

    enum CodingKeys: String, CodingKey {
        case totalAmount = "bfdy_tot_asst_evlu_amt"
        case totalGainLoss = "asst_icdc_amt"
        case totalGainLossRate = "asst_icdc_erng_rt"
        case orderableCash = "dnca_tot_amt"
    }
}

struct DomesticAccountInfo: Codable {
    let balance: DomesticAccountBalance
    let returnCode: String
    let messageCode: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case balance = "output"
        case returnCode = "rt_cd"
        case messageCode = "msg_cd"
        case message = "msg1"
    }

    var isSuccess: Bool {
        returnCode == "0"
    }
}

struct DomesticAccountBalance: Codable {
    let cash: String
}
