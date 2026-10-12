import Foundation

struct OverseasStockBalanceResponse: Decodable {
    let stockList: [OverseasStockInfo]?
    let accountSummary: OverseasAccountSummaryResponse?
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

    var safeStockList: [OverseasStockInfo] {
        stockList ?? []
    }
}

struct OverseasStockInfo: Codable {
    let ticker: String
    let name: String
    let gainLoss: String
    let gainLossRate: String
    let currentPrice: String
    let avgBuyingPrice: String
    let totalCurrentPrice: String
    let totalBuyingPrice: String
    let quantity: String
    let excgCd: String

    enum CodingKeys: String, CodingKey {
        case ticker = "ovrs_pdno"
        case name = "ovrs_item_name"
        case gainLoss = "frcr_evlu_pfls_amt"
        case gainLossRate = "evlu_pfls_rt"
        case currentPrice = "now_pric2"
        case avgBuyingPrice = "pchs_avg_pric"
        case totalCurrentPrice = "ovrs_stck_evlu_amt"
        case totalBuyingPrice = "frcr_pchs_amt1"
        case quantity = "ovrs_cblc_qty"
        case excgCd = "ovrs_excg_cd"
    }
}

struct OverseasAccountSummaryResponse: Codable {
    let totalAmount: String
    let totalGainLoss: String
    let totalGainLossRate: String

    enum CodingKeys: String, CodingKey {
        case totalAmount = "frcr_pchs_amt1"
        case totalGainLoss = "ovrs_tot_pfls"
        case totalGainLossRate = "tot_pftrt"
    }
}

struct OverseasAccountInfo: Codable {
    let balance: OverseasAccountBalance
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

struct OverseasAccountBalance: Codable {
    let currencyCode: String
    let orderableCash: String
    let exchangeRate: String

    enum CodingKeys: String, CodingKey {
        case currencyCode = "tr_crcy_cd"
        case orderableCash = "ovrs_ord_psbl_amt"
        case exchangeRate = "exrt"
    }
}
