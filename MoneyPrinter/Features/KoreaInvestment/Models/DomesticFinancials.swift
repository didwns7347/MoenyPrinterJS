import Foundation

struct DomesticStockPerformanceResponse: Decodable {
    let output: [FinancialStatement]
}

struct FinancialStatement: Codable {
    /// 결산 년월 (예: 202506)
    let fiscalYearMonth: String
    /// 매출액 (Sales Revenue)
    let salesRevenue: String
    /// 매출 원가 (Cost of Sales)
    let costOfSales: String
    /// 매출 총이익 (Gross Profit)
    let grossProfit: String
    /// 감가상각비 (Depreciation Cost)
    let depreciationCost: String
    /// 판매 및 관리비 (Selling & Administrative Expenses)
    let sellingAdminExpense: String
    /// 영업이익 (Operating Income)
    let operatingIncome: String
    /// 영업 외 수익 (Non-operating Income)
    let nonOperatingIncome: String
    /// 영업 외 비용 (Non-operating Expense)
    let nonOperatingExpense: String
    /// 경상 이익 (Ordinary Income)
    let ordinaryIncome: String
    /// 특별 이익 (Extraordinary Income)
    let specialIncome: String
    /// 특별 손실 (Extraordinary Loss)
    let specialLoss: String
    /// 당기순이익 (Net Income)
    let netIncome: String

    enum CodingKeys: String, CodingKey {
        case fiscalYearMonth = "stac_yymm"
        case salesRevenue = "sale_account"
        case costOfSales = "sale_cost"
        case grossProfit = "sale_totl_prfi"
        case depreciationCost = "depr_cost"
        case sellingAdminExpense = "sell_mang"
        case operatingIncome = "bsop_prti"
        case nonOperatingIncome = "bsop_non_ernn"
        case nonOperatingExpense = "bsop_non_expn"
        case ordinaryIncome = "op_prfi"
        case specialIncome = "spec_prfi"
        case specialLoss = "spec_loss"
        case netIncome = "thtr_ntin"
    }
}

struct StockPerformance: Encodable {
    let name: String?
    let code: String
    let marketCapitalization: String
    let per: String
    let pbr: String
    let eps: String
    let financialStates: [FinancialStatement]
}

struct DomesticStockDetailResponse: Decodable {
    let output: DomesticStockDetail
}

struct DomesticStockDetail: Decodable {
    let code: String
    let name: String
    let marketCapitalization: String
    let per: String
    let pbr: String
    let eps: String

    enum CodingKeys: String, CodingKey {
        case code = "stck_shrn_iscd"
        case marketCapitalization = "hts_avls"
        case name = "rprs_mrkt_kor_name"
        case per
        case pbr
        case eps
    }
}
