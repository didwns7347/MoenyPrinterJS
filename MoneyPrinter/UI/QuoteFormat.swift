import SwiftUI

struct MetricRow: View {
    let title: String
    let value: String
    var tone: Double?

    var body: some View {
        LabeledContent(title) {
            Text(value)
                .foregroundStyle(QuoteTone.color(tone))
                .monospacedDigit()
        }
    }
}

struct MomentumSection: View {
    let snapshot: MarketSnapshot

    var body: some View {
        if snapshot.macdHistogramAsPercentOfClose != nil || snapshot.ma20Slope5dPct != nil {
            Section("탄력") {
                if let histogram = snapshot.macdHistogramAsPercentOfClose {
                    MetricRow(title: "MACD 히스토그램", value: DisplayNumber.percent(histogram), tone: histogram)
                }
                if let change = snapshot.macdHistogramChangeOver5dPct {
                    MetricRow(title: "MACD 히스토그램 5거래일 변화", value: DisplayNumber.percent(change) + "p", tone: change)
                }
                if let slope = snapshot.ma20Slope5dPct {
                    MetricRow(title: "20거래일 이동평균의 5거래일 변화", value: DisplayNumber.percent(slope), tone: slope)
                }
                if let days = snapshot.tradingDaysSinceCloseCrossedMa60 {
                    LabeledContent(
                        "60거래일 이동평균 \(snapshot.priceVsMa60Pct >= 0 ? "위" : "아래")에서",
                        value: "\(days)거래일째"
                    )
                }
            }
        }
    }
}

enum QuoteTone {
    static func color(_ value: Double?) -> Color {
        guard let value, value != 0 else { return .primary }
        return value > 0 ? .red : .blue
    }
}

enum DisplayNumber {
    static func value(_ raw: String) -> Double? {
        Double(raw.replacingOccurrences(of: ",", with: ""))
    }

    static func won(_ raw: String) -> String {
        guard let number = value(raw) else { return raw }
        return (plain(number, digits: number.rounded() == number ? 0 : 2) ?? raw) + "원"
    }

    static func quantity(_ raw: String) -> String {
        guard let number = value(raw) else { return raw }
        return plain(number, digits: number.rounded() == number ? 0 : 4) ?? raw
    }

    static func signed(_ raw: String, suffix: String) -> String {
        guard let number = value(raw) else { return raw }
        let body = plain(abs(number), digits: 2) ?? raw
        let sign = number > 0 ? "+" : (number < 0 ? "-" : "")
        return sign + body + suffix
    }

    static func percent(_ value: Double) -> String {
        let body = plain(abs(value), digits: 2) ?? String(format: "%.2f", abs(value))
        let sign = value > 0 ? "+" : (value < 0 ? "-" : "")
        return sign + body + "%"
    }

    static func decimal(_ value: Double, digits: Int) -> String {
        plain(value, digits: digits) ?? String(format: "%.\(digits)f", value)
    }

    private static func plain(_ number: Double, digits: Int) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: number))
    }
}
