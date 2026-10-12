import Foundation


class KoreaInvestmentAPIService {
    static let shared = KoreaInvestmentAPIService()
    private let tokenManager: TokenManager
    private let http: HTTPClient
    enum ExchangeCode : String, Codable {
        /// 홍콩
        case HKS
        /// 뉴욕
        case NYS
        /// 나스닥
        case NAS
        /// 아멕스
        case AMS
        /// 도쿄
        case TSE
        /// 상해
        case SHS
        /// 상해지수/
        case SHI
        /// 심천
        case SZS
        /// 호치민
        case HSX
        /// 하노이
        case HNX
    }

    private init(
        http: HTTPClient? = nil,
        secureStorage: StorageProtocol = KeychainStorage.shared
    ) {
        let client = http ?? Self.makeHTTPClient()
        self.http = client
        self.tokenManager = TokenManager(http: client, secureStorage: secureStorage)
    }

    private static func makeHTTPClient() -> HTTPClient {
        guard let baseURL = URL(string: APIConfigManager.shared.baseURL) else {
            fatalError("URL_BASE가 올바른 URL이 아닙니다.")
        }
        return HTTPClient(baseURL: baseURL)
    }

    private func request<T: Decodable>(_ endpoint: KoreaInvestmentEndpoint) async throws -> T {
        try await http.send(try endpoint.makeRequest(), as: T.self)
    }



    func resetToken() async {
        await tokenManager.resetToken()
    }

    /// 국내주식 일별 주가 데이터를 가져옵니다.
    func fetchDomesticDailyPrice(stockCode: String, period: String = "D") async throws -> [DailyPriceInfo] {
        let token = try await tokenManager.getValidToken()
        let (start,fin) = getStartFinDates()
        let endpoint = KoreaInvestmentEndpoint.fetchDailyPrice(
            token: token,
            stockCode: stockCode,
            periodDivCode: period,
            startDate: start,
            finDate: fin
        )
        let response: StockPriceResponse = try await request(endpoint)
        
        guard response.returnCode == "0" else {
            throw NSError(domain: "KoreaInvestmentAPI", code: Int(response.returnCode) ?? -1, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
        
        return response.dailyPrices
    }
    /// 해외주식 일별 주가 데이터를 가져옵니다.
    func fetchOverseasDailyPrice(stockCode: String, excd: ExchangeCode = .NAS ) async throws -> [OverseasDailyStockPrice] {
        let token = try await tokenManager.getValidToken()
        let endpoint = KoreaInvestmentEndpoint.fetchOverseasDailyPrice(token: token, EXCD: excd.rawValue, SYMB: stockCode)
        let response: OverseasStockPriceInfo = try await request(endpoint)
        
        guard response.returnCode == "0" else {
            throw NSError(domain: "KoreaInvestmentAPI", code: Int(response.returnCode) ?? -1, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
        return response.priceHistories
    }
    
    /// 국내주식 잔고를 조회합니다.
    func fetchDomesticStockBalance() async throws -> DomesticStockBalanceResponse {
        let token = try await tokenManager.getValidToken()
        let endpoint = KoreaInvestmentEndpoint.fetchDomesticStockBalance(
            token: token
        )
        let response: DomesticStockBalanceResponse = try await request(endpoint)
        
        // API 에러 체크 (더 상세한 에러 처리)
        guard response.isSuccess else {
            let errorMessage = "[\(response.messageCode)] \(response.message)"
            throw NSError(
                domain: "KoreaInvestmentAPI", 
                code: Int(response.returnCode) ?? -1, 
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }
        
        return response
    }
    /// 국내주식 영업 실적 조회
    func fetchDomesticStockPerformance(code: String) async throws -> DomesticStockPerformanceResponse {
        let token = try await tokenManager.getValidToken()
        let endpoint = KoreaInvestmentEndpoint.fetchDomesticStockPerformance(token: token, stockCode: code)
        let response: DomesticStockPerformanceResponse = try await request(endpoint)
        return response
    }
    
    /// 국내주식 기본 조회
    func fetchDomesticStockDetail(code: String) async throws -> DomesticStockDetail {
        let token = try await tokenManager.getValidToken()
        let endpoint = KoreaInvestmentEndpoint.fetchDomesticStockInfo(token: token, stockCode: code)
        let response: DomesticStockDetailResponse = try await request(endpoint)
        return response.output
    }
    
    /// 해외주식 잔고를 조회합니다.
    func fetchOverseasStockBalance(
        exchangeCode: String = "NASD", // 기본값: 나스닥
        currencyCode: String = "USD"   // 기본값: 미국 달러
    ) async throws -> OverseasStockBalanceResponse {
        let token = try await tokenManager.getValidToken()
        let endpoint = KoreaInvestmentEndpoint.fetchOverseasStockBalance(
            token: token,
            OVRS_EXCG_CD: exchangeCode,
            TR_CRCY_CD: currencyCode
        )
        let response: OverseasStockBalanceResponse = try await request(endpoint)
        
        // API 에러 체크 (더 상세한 에러 처리)
        guard response.isSuccess else {
            let errorMessage = "[\(response.messageCode)] \(response.message)"
            throw NSError(
                domain: "KoreaInvestmentAPI", 
                code: Int(response.returnCode) ?? -1, 
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }
        
        return response
    }
    
    /// 해외주식 예수금 조회
    func fetchOverseasAccountBalance() async throws -> OverseasAccountBalance {
        let token = try await tokenManager.getValidToken()
        let endpoint = KoreaInvestmentEndpoint.fetchOverseasAccountBalance(token: token, OVRS_EXCG_CD: "NASD")
        let response: OverseasAccountInfo = try await request(endpoint)
        guard response.isSuccess else {
            let errorMessage = "[\(response.messageCode)] \(response.message)"
            throw NSError(
                domain: "KoreaInvestmentAPI",
                code: Int(response.returnCode) ?? -1,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }
        return response.balance
    }
    
    

    // 3달치
    private func getStartFinDates() -> (String, String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let start = Calendar.current.date(byAdding: .month, value: -3, to: Date())
        return (start.map { formatter.string(from: $0) } ?? "", formatter.string(from: Date()))
    }
}





