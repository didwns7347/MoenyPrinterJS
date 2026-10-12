import Foundation

struct StockPriceResponse: Decodable {
    let currentPriceInfo: CurrentPriceInfo
    let dailyPrices: [DailyPriceInfo]
    let returnCode: String
    let messageCode: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case currentPriceInfo = "output1"
        case dailyPrices = "output2"
        case returnCode = "rt_cd"
        case messageCode = "msg_cd"
        case message = "msg1"
    }
}

struct CurrentPriceInfo: Decodable {
    let previousDayComparison: String
    let previousDaySign: String
    let previousDayContrastRatio: String
    let previousDayClosingPrice: String
    let accumulatedVolume: String
    let accumulatedTradePayment: String
    let htsKoreanStockName: String
    let stockPrice: String
    let stockShortCode: String
    let previousDayVolume: String
    let stockMaxPrice: String
    let stockMinPrice: String
    let stockOpeningPrice: String
    let stockHighPrice: String
    let stockLowPrice: String
    let previousDayOpeningPrice: String
    let previousDayHighPrice: String
    let previousDayLowPrice: String
    let askPrice: String
    let bidPrice: String
    let previousDayVolumeChange: String
    let volumeTurnoverRate: String
    let stockFaceValue: String
    let listedStockCount: String
    let capital: String
    let htsAvailableVolume: String
    let per: String
    let eps: String
    let pbr: String
    let itewholLoanRmndRateName: String

    enum CodingKeys: String, CodingKey {
        case previousDayComparison = "prdy_vrss"
        case previousDaySign = "prdy_vrss_sign"
        case previousDayContrastRatio = "prdy_ctrt"
        case previousDayClosingPrice = "stck_prdy_clpr"
        case accumulatedVolume = "acml_vol"
        case accumulatedTradePayment = "acml_tr_pbmn"
        case htsKoreanStockName = "hts_kor_isnm"
        case stockPrice = "stck_prpr"
        case stockShortCode = "stck_shrn_iscd"
        case previousDayVolume = "prdy_vol"
        case stockMaxPrice = "stck_mxpr"
        case stockMinPrice = "stck_llam"
        case stockOpeningPrice = "stck_oprc"
        case stockHighPrice = "stck_hgpr"
        case stockLowPrice = "stck_lwpr"
        case previousDayOpeningPrice = "stck_prdy_oprc"
        case previousDayHighPrice = "stck_prdy_hgpr"
        case previousDayLowPrice = "stck_prdy_lwpr"
        case askPrice = "askp"
        case bidPrice = "bidp"
        case previousDayVolumeChange = "prdy_vrss_vol"
        case volumeTurnoverRate = "vol_tnrt"
        case stockFaceValue = "stck_fcam"
        case listedStockCount = "lstn_stcn"
        case capital = "cpfn"
        case htsAvailableVolume = "hts_avls"
        case per = "per"
        case eps = "eps"
        case pbr = "pbr"
        case itewholLoanRmndRateName = "itewhol_loan_rmnd_ratem name"
    }
}

struct DailyPriceInfo: Codable {
    let businessDate: String
    let closingPrice: String
    let openingPrice: String
    let highPrice: String
    let lowPrice: String
    let accumulatedVolume: String
    let accumulatedTradePayment: String
    let fallingClosingCode: String
    let protectionRate: String
    let modificationYN: String
    let previousDaySign: String
    let previousDayComparison: String
    let revaluationIssueReason: String

    enum CodingKeys: String, CodingKey {
        case businessDate = "stck_bsop_date"
        case closingPrice = "stck_clpr"
        case openingPrice = "stck_oprc"
        case highPrice = "stck_hgpr"
        case lowPrice = "stck_lwpr"
        case accumulatedVolume = "acml_vol"
        case accumulatedTradePayment = "acml_tr_pbmn"
        case fallingClosingCode = "flng_cls_code"
        case protectionRate = "prtt_rate"
        case modificationYN = "mod_yn"
        case previousDaySign = "prdy_vrss_sign"
        case previousDayComparison = "prdy_vrss"
        case revaluationIssueReason = "revl_issu_reas"
    }
}

struct StockDailyHistory: Encodable {
    let code: String
    let closingPrices: [[String: String]]
}
