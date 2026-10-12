import Foundation

enum KoreaInvestmentEndpoint {
    case issueToken
    case fetchDailyPrice(
        token: String,
        stockCode: String,
        periodDivCode: String,
        startDate: String,
        finDate: String
    )
    case fetchOverseasDailyPrice(
        token: String,
        EXCD: String,
        SYMB: String
    )
    case fetchOverseasIndexDailyPrice(
        token: String,
        symbol: String,
        startDate: String,
        endDate: String
    )
    case fetchDomesticStockBalance(token: String)
    case fetchOverseasStockBalance(
        token: String,
        OVRS_EXCG_CD: String,
        TR_CRCY_CD: String
    )
    case fetchOverseasAccountBalance(
        token: String,
        OVRS_EXCG_CD: String
    )
    case fetchDomesticStockPerformance(
        token: String,
        stockCode: String
    )
    case fetchDomesticStockInfo(
        token: String,
        stockCode: String
    )

    func makeRequest() throws -> HTTPRequest {
        _ = Self.didCheck
        return HTTPRequest(
            method: method,
            path: path,
            query: query,
            headers: try headerFields(),
            body: try body()
        )
    }

    var method: HTTPMethod {
        switch self {
        case .issueToken:
            return .post
        default:
            return .get
        }
    }

    var path: String {
        switch self {
        case .issueToken:
            return "/oauth2/tokenP"
        case .fetchDailyPrice:
            return "/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice"
        case .fetchDomesticStockBalance:
            return "/uapi/domestic-stock/v1/trading/inquire-balance"
        case .fetchOverseasStockBalance:
            return "/uapi/overseas-stock/v1/trading/inquire-balance"
        case .fetchOverseasAccountBalance:
            return "/uapi/overseas-stock/v1/trading/inquire-psamount"
        case .fetchOverseasDailyPrice:
            return "/uapi/overseas-price/v1/quotations/dailyprice"
        case .fetchOverseasIndexDailyPrice:
            return "/uapi/overseas-price/v1/quotations/inquire-daily-chartprice"
        case .fetchDomesticStockPerformance:
            return "/uapi/domestic-stock/v1/finance/income-statement"
        case .fetchDomesticStockInfo:
            return "/uapi/domestic-stock/v1/quotations/inquire-price"
        }
    }

    private var transactionID: String? {
        switch self {
        case .issueToken:
            return nil
        case .fetchDomesticStockInfo:
            return "FHKST01010100"
        case .fetchDailyPrice:
            return "FHKST03010100"
        case .fetchOverseasDailyPrice:
            return "HHDFS76240000"
        case .fetchOverseasIndexDailyPrice:
            return "FHKST03030100"
        case .fetchDomesticStockBalance:
            return APIConfigManager.isDemo ? "VTTC8434R" : "TTTC8434R"
        case .fetchOverseasStockBalance:
            return APIConfigManager.isDemo ? "VTTS3012R" : "TTTS3012R"
        case .fetchOverseasAccountBalance:
            return "TTTS3007R"
        case .fetchDomesticStockPerformance:
            return "FHKST66430200"
        }
    }

    private var query: [URLQueryItem] {
        switch self {
        case .issueToken:
            return []
        case .fetchDailyPrice(_, let stockCode, let period, let startDate, let finDate):
            return [
                URLQueryItem(name: "fid_cond_mrkt_div_code", value: "J"),
                URLQueryItem(name: "fid_input_iscd", value: stockCode),
                URLQueryItem(name: "fid_input_date_1", value: startDate),
                URLQueryItem(name: "fid_input_date_2", value: finDate),
                URLQueryItem(name: "fid_period_div_code", value: period),
                URLQueryItem(name: "fid_org_adj_prc", value: "1"),
            ]
        case .fetchOverseasDailyPrice(_, let excd, let symb):
            return [
                URLQueryItem(name: "EXCD", value: excd),
                URLQueryItem(name: "SYMB", value: symb),
                URLQueryItem(name: "GUBN", value: "0"),
                URLQueryItem(name: "BYMD", value: ""),
                URLQueryItem(name: "MODP", value: "0"),
            ]
        case .fetchOverseasIndexDailyPrice(_, let symbol, let startDate, let endDate):
            return [
                URLQueryItem(name: "FID_COND_MRKT_DIV_CODE", value: "N"),
                URLQueryItem(name: "FID_INPUT_ISCD", value: symbol),
                URLQueryItem(name: "FID_INPUT_DATE_1", value: startDate),
                URLQueryItem(name: "FID_INPUT_DATE_2", value: endDate),
                URLQueryItem(name: "FID_PERIOD_DIV_CODE", value: "D"),
            ]
        case .fetchDomesticStockBalance:
            return accountItems([
                URLQueryItem(name: "AFHR_FLPR_YN", value: "N"),
                URLQueryItem(name: "OFL_YN", value: ""),
                URLQueryItem(name: "INQR_DVSN", value: "02"),
                URLQueryItem(name: "UNPR_DVSN", value: "01"),
                URLQueryItem(name: "FUND_STTL_ICLD_YN", value: "N"),
                URLQueryItem(name: "FNCG_AMT_AUTO_RDPT_YN", value: "N"),
                URLQueryItem(name: "PRCS_DVSN", value: "00"),
                URLQueryItem(name: "CTX_AREA_FK100", value: ""),
                URLQueryItem(name: "CTX_AREA_NK100", value: ""),
            ])
        case .fetchOverseasStockBalance(_, let exchangeCode, let currencyCode):
            return accountItems([
                URLQueryItem(name: "OVRS_EXCG_CD", value: exchangeCode),
                URLQueryItem(name: "TR_CRCY_CD", value: currencyCode),
                URLQueryItem(name: "CTX_AREA_FK200", value: ""),
                URLQueryItem(name: "CTX_AREA_NK200", value: ""),
            ])
        case .fetchOverseasAccountBalance(_, let exchangeCode):
            return accountItems([
                URLQueryItem(name: "OVRS_EXCG_CD", value: exchangeCode),
                URLQueryItem(name: "OVRS_ORD_UNPR", value: "1.4"),
                URLQueryItem(name: "ITEM_CD", value: "TRVG"),
            ])
        case .fetchDomesticStockPerformance(_, let code):
            return [
                URLQueryItem(name: "fid_cond_mrkt_div_code", value: "J"),
                URLQueryItem(name: "fid_input_iscd", value: code),
                URLQueryItem(name: "fid_div_cls_code", value: "1"),
            ]
        case .fetchDomesticStockInfo(_, let code):
            return [
                URLQueryItem(name: "fid_cond_mrkt_div_code", value: "J"),
                URLQueryItem(name: "fid_input_iscd", value: code),
            ]
        }
    }

    private func headerFields() throws -> [String: String] {
        switch self {
        case .issueToken:
            return ["content-type": "application/json"]
        case .fetchDomesticStockPerformance(let token, _),
             .fetchOverseasIndexDailyPrice(let token, _, _, _):
            var headers = try authHeaders(token: token, trID: transactionID ?? "")
            headers["custtype"] = "P"
            return headers
        default:
            return try authHeaders(token: accessToken, trID: transactionID ?? "", keepAlive: keepsConnection)
        }
    }

    private var accessToken: String {
        switch self {
        case .issueToken:
            return ""
        case .fetchDailyPrice(let token, _, _, _, _),
             .fetchOverseasDailyPrice(let token, _, _),
             .fetchOverseasIndexDailyPrice(let token, _, _, _),
             .fetchDomesticStockBalance(let token),
             .fetchOverseasStockBalance(let token, _, _),
             .fetchOverseasAccountBalance(let token, _),
             .fetchDomesticStockPerformance(let token, _),
             .fetchDomesticStockInfo(let token, _):
            return token
        }
    }

    private var keepsConnection: Bool {
        switch self {
        case .fetchDomesticStockInfo, .fetchDailyPrice, .fetchOverseasDailyPrice, .fetchOverseasIndexDailyPrice:
            return true
        default:
            return false
        }
    }

    private func body() throws -> Data? {
        switch self {
        case .issueToken:
            let config = try APIConfigManager.load()
            let payload = IssueTokenBody(
                appkey: config.appKey,
                appsecret: config.appSecret
            )
            do {
                return try JSONEncoder().encode(payload)
            } catch {
                throw NetworkError.encoding(error.localizedDescription)
            }
        default:
            return nil
        }
    }

    private func authHeaders(token: String, trID: String, keepAlive: Bool = false) throws -> [String: String] {
        let config = try APIConfigManager.load()
        var headers = [
            "content-type": "application/json",
            "Authorization": "Bearer \(token)",
            "appkey": config.appKey,
            "appsecret": config.appSecret,
            "tr_id": trID,
        ]
        if keepAlive {
            headers["Connection"] = "keep-alive"
        }
        return headers
    }

    private func accountItems(_ more: [URLQueryItem]) -> [URLQueryItem] {
        let config = try? APIConfigManager.load()
        return [
            URLQueryItem(name: "CANO", value: config?.cano ?? ""),
            URLQueryItem(name: "ACNT_PRDT_CD", value: config?.accountCode ?? ""),
        ] + more
    }

    private static let didCheck: Void = {
        let issued = KoreaInvestmentEndpoint.issueToken
        assert(issued.method == .post && issued.path == "/oauth2/tokenP")
        let daily = KoreaInvestmentEndpoint.fetchDailyPrice(
            token: "t",
            stockCode: "005930",
            periodDivCode: "D",
            startDate: "20260101",
            finDate: "20260401"
        )
        assert(daily.method == .get)
        assert(daily.path == "/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice")
        assert(daily.transactionID == "FHKST03010100")
        assert(daily.query.contains(URLQueryItem(name: "fid_input_iscd", value: "005930")))
        assert(daily.query.contains(URLQueryItem(name: "fid_period_div_code", value: "D")))
        let overseas = KoreaInvestmentEndpoint.fetchOverseasDailyPrice(token: "t", EXCD: "NAS", SYMB: "AAPL")
        assert(overseas.path == "/uapi/overseas-price/v1/quotations/dailyprice")
        assert(overseas.transactionID == "HHDFS76240000")
        assert(overseas.query.contains(URLQueryItem(name: "GUBN", value: "0")))
        let index = KoreaInvestmentEndpoint.fetchOverseasIndexDailyPrice(
            token: "t",
            symbol: "SPX",
            startDate: "20260101",
            endDate: "20260401"
        )
        assert(index.path == "/uapi/overseas-price/v1/quotations/inquire-daily-chartprice")
        assert(index.transactionID == "FHKST03030100")
        assert(index.query.contains(URLQueryItem(name: "FID_INPUT_ISCD", value: "SPX")))
        assert(index.query.contains(URLQueryItem(name: "FID_COND_MRKT_DIV_CODE", value: "N")))
    }()
}

private struct IssueTokenBody: Encodable {
    var grantType = "client_credentials"
    var appkey: String
    var appsecret: String

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case appkey
        case appsecret
    }
}
