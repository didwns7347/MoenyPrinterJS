import SwiftUI

@MainActor
@Observable
private final class AccountStore {
    private(set) var summary: DomesticAccountSummaryResponse?
    private(set) var holdings: [DomesticStockInfo] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await KoreaInvestmentAPIService.shared.fetchDomesticStockBalance()
            summary = response.accountSummary?.first
            holdings = (response.stockList ?? []).filter(Self.isHeld)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func isHeld(_ stock: DomesticStockInfo) -> Bool {
        let name = stock.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantity = Double(stock.quantity) ?? 0
        return !name.isEmpty && quantity > 0
    }
}

struct AccountTab: View {
    @State private var store = AccountStore()

    var body: some View {
        NavigationStack {
            Group {
                if store.summary == nil, store.holdings.isEmpty, store.isLoading {
                    ProgressView("계좌를 불러오는 중")
                } else if store.summary == nil, store.holdings.isEmpty, let errorMessage = store.errorMessage {
                    ContentUnavailableView {
                        Label("계좌를 불러오지 못했습니다", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("다시 시도") {
                            Task { await store.reload() }
                        }
                    }
                } else {
                    accountList
                }
            }
            .navigationTitle("계좌")
            .toolbar { refreshButton }
        }
        .task { await store.reload() }
    }

    private var accountList: some View {
        List {
            if let summary = store.summary {
                Section("요약") {
                    LabeledContent("전일 총자산", value: DisplayNumber.won(summary.totalAmount))
                    signedRow("자산 증감", raw: summary.totalGainLoss, suffix: "원")
                    signedRow("증감률", raw: summary.totalGainLossRate, suffix: "%")
                    LabeledContent("예수금", value: DisplayNumber.won(summary.orderableCash))
                }
            }
            Section("보유 종목") {
                if store.holdings.isEmpty {
                    Text("보유 종목이 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.holdings, id: \.rowID) { stock in
                        HoldingRow(stock: stock)
                    }
                }
            }
            if let errorMessage = store.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .refreshable { await store.reload() }
    }

    private func signedRow(_ title: String, raw: String, suffix: String) -> some View {
        let number = DisplayNumber.value(raw)
        return LabeledContent(title) {
            Text(DisplayNumber.signed(raw, suffix: suffix))
                .foregroundStyle(QuoteTone.color(number))
                .monospacedDigit()
        }
    }

    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("새로고침", systemImage: "arrow.clockwise") {
                Task { await store.reload() }
            }
            .disabled(store.isLoading)
        }
    }
}

private struct HoldingRow: View {
    let stock: DomesticStockInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stock.name)
                    .font(.headline)
                Spacer()
                Text(DisplayNumber.won(stock.totalCurrentPrice))
                    .monospacedDigit()
            }
            HStack {
                Text(stock.code ?? "")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(DisplayNumber.signed(stock.gainLoss, suffix: "원"))
                    .foregroundStyle(QuoteTone.color(DisplayNumber.value(stock.gainLoss)))
                Text(DisplayNumber.signed(stock.gainLossRate, suffix: "%"))
                    .foregroundStyle(QuoteTone.color(DisplayNumber.value(stock.gainLossRate)))
            }
            .font(.subheadline)
            .monospacedDigit()
            HStack {
                Text("\(DisplayNumber.quantity(stock.quantity))주")
                Text("현재가 \(DisplayNumber.won(stock.currentPrice))")
                Text("평단 \(DisplayNumber.won(stock.avgBuyingPrice))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

private extension DomesticStockInfo {
    var rowID: String { "\(code ?? "")-\(name)-\(quantity)" }
}
