import Foundation

struct MarketSnapshot: Codable {
    /// 200일 이동평균의 20일 기울기를 계산하려면 최신 200일 앞에 20일이 더 필요합니다.
    static let lookback = 200
    static let slopeLag = 20
    static let requiredBarCount = lookback + slopeLag

    let ticker: String
    /// 마지막 일봉의 거래일. `yyyy-MM-dd`
    let asOf: String
    /// 마지막 일봉의 종가. 이 값을 저장하기 전의 기록에는 없습니다.
    let latestClosingPrice: Double?
    /// 최근 200거래일 첫 종가를 100으로 둔 현재 지수.
    let priceIndexed: Double
    /// 현재 종가가 20거래일 이동평균보다 높은 정도. 단위는 퍼센트 포인트입니다.
    let priceVsMa20Pct: Double
    let priceVsMa60Pct: Double
    let priceVsMa200Pct: Double
    /// 200거래일 이동평균이 20거래일 전 값보다 변한 정도. 단위는 퍼센트 포인트입니다.
    let ma200Slope20dPct: Double
    /// 최근 일간 수익률의 표본 표준편차를 1년(252거래일)으로 환산한 값. 단위는 퍼센트입니다.
    let volatility20dPct: Double
    let volatility60dPct: Double
    /// 최근 200거래일 최고가 대비 현재 종가. 0 이하면 그 최고가 아래입니다.
    let drawdownFrom200dHighPct: Double
    /// 21, 63, 126거래일 전 종가 대비 현재 종가. 단위는 퍼센트 포인트입니다.
    let return1mPct: Double
    let return3mPct: Double
    let return6mPct: Double

    enum CodingKeys: String, CodingKey {
        case ticker = "index_symbol"
        case asOf = "last_trading_day"
        case latestClosingPrice = "latest_closing_price"
        case priceIndexed = "price_with_close_200_trading_days_ago_set_to_100"
        case priceVsMa20Pct = "percent_difference_from_20_trading_day_moving_average"
        case priceVsMa60Pct = "percent_difference_from_60_trading_day_moving_average"
        case priceVsMa200Pct = "percent_difference_from_200_trading_day_moving_average"
        case ma200Slope20dPct = "percent_change_of_200_trading_day_moving_average_over_prior_20_trading_days"
        case volatility20dPct = "annualized_percent_volatility_of_daily_returns_over_20_trading_days"
        case volatility60dPct = "annualized_percent_volatility_of_daily_returns_over_60_trading_days"
        case drawdownFrom200dHighPct = "percent_change_from_highest_high_of_last_200_trading_days"
        case return1mPct = "percent_return_over_prior_21_trading_days"
        case return3mPct = "percent_return_over_prior_63_trading_days"
        case return6mPct = "percent_return_over_prior_126_trading_days"
    }

    init(bars: [IndexDailyBar], ticker: String = "SPX") throws {
        let ordered = bars.sorted { $0.date < $1.date }
        guard ordered.count >= Self.requiredBarCount else {
            throw MarketSnapshotError.insufficientHistory(have: ordered.count, need: Self.requiredBarCount)
        }
        let window = Array(ordered.suffix(Self.requiredBarCount))
        let closes = try window.map { bar -> Double in
            guard bar.close > 0, bar.high > 0 else {
                throw MarketSnapshotError.invalidPrice(date: bar.date)
            }
            return bar.close
        }
        let highs = window.map(\.high)
        let price = closes[closes.count - 1]
        let recentCloses = Array(closes.suffix(Self.lookback))
        let recentHighs = Array(highs.suffix(Self.lookback))

        self.ticker = ticker
        self.asOf = Self.isoDate(window[window.count - 1].date)
        self.latestClosingPrice = price
        self.priceIndexed = price / recentCloses[0] * 100
        self.priceVsMa20Pct = Self.gapPercent(price: price, average: Self.mean(closes, period: 20))
        self.priceVsMa60Pct = Self.gapPercent(price: price, average: Self.mean(closes, period: 60))
        let ma200 = Self.mean(closes, period: Self.lookback)
        self.priceVsMa200Pct = Self.gapPercent(price: price, average: ma200)
        let ma200Then = Self.mean(Array(closes.dropLast(Self.slopeLag)), period: Self.lookback)
        self.ma200Slope20dPct = Self.gapPercent(price: ma200, average: ma200Then)
        self.volatility20dPct = Self.annualizedVolatilityPercent(closes, period: 20)
        self.volatility60dPct = Self.annualizedVolatilityPercent(closes, period: 60)
        self.drawdownFrom200dHighPct = Self.gapPercent(price: price, average: recentHighs.max() ?? price)
        self.return1mPct = Self.gapPercent(price: price, average: closes[closes.count - 1 - 21])
        self.return3mPct = Self.gapPercent(price: price, average: closes[closes.count - 1 - 63])
        self.return6mPct = Self.gapPercent(price: price, average: closes[closes.count - 1 - 126])
    }

    private static func mean(_ values: [Double], period: Int) -> Double {
        let slice = values.suffix(period)
        return slice.reduce(0, +) / Double(period)
    }

    private static func gapPercent(price: Double, average: Double) -> Double {
        (price / average - 1) * 100
    }

    private static func annualizedVolatilityPercent(_ closes: [Double], period: Int) -> Double {
        let slice = Array(closes.suffix(period + 1))
        let returns = zip(slice, slice.dropFirst()).map { yesterday, today in
            today / yesterday - 1
        }
        let count = Double(returns.count)
        let mean = returns.reduce(0, +) / count
        let variance = returns.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / (count - 1)
        return variance.squareRoot() * (252 as Double).squareRoot() * 100
    }

    private static func isoDate(_ yyyymmdd: String) -> String {
        guard yyyymmdd.count == 8 else { return yyyymmdd }
        let year = yyyymmdd.prefix(4)
        let month = yyyymmdd.dropFirst(4).prefix(2)
        let day = yyyymmdd.suffix(2)
        return "\(year)-\(month)-\(day)"
    }
}

enum MarketSnapshotError: LocalizedError {
    case insufficientHistory(have: Int, need: Int)
    case invalidPrice(date: String)

    var errorDescription: String? {
        switch self {
        case .insufficientHistory(let have, let need):
            return "일봉이 \(have)개입니다. 지표 계산에는 \(need)개가 필요합니다."
        case .invalidPrice(let date):
            return "\(date) 종가 또는 고가가 없습니다."
        }
    }
}

extension KoreaInvestmentAPIService {
    /// KODEX 200. 코스피200을 따르는 ETF입니다.
    static let kodex200 = "069500"
    /// KODEX 미국S&P500(H). 코스피에 상장된 미국 S&P500 환헤지 ETF입니다.
    static let kodexUSSP500H = "449180"

    func makeSPXSnapshot() async throws -> MarketSnapshot {
        let bars = try await fetchSPXDailyBars(tradingDays: MarketSnapshot.requiredBarCount)
        return try MarketSnapshot(bars: bars)
    }

    func makeKODEX200Snapshot() async throws -> MarketSnapshot {
        try await makeDomesticETFSnapshot(stockCode: Self.kodex200)
    }

    func makeKODEXUSSP500HSnapshot() async throws -> MarketSnapshot {
        try await makeDomesticETFSnapshot(stockCode: Self.kodexUSSP500H)
    }

    private func makeDomesticETFSnapshot(stockCode: String) async throws -> MarketSnapshot {
        let bars = try await fetchDomesticDailyBars(
            stockCode: stockCode,
            tradingDays: MarketSnapshot.requiredBarCount
        )
        return try MarketSnapshot(bars: bars, ticker: stockCode)
    }
}
