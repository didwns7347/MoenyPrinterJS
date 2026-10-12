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
