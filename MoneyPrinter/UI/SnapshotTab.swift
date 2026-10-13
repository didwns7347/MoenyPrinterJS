import SwiftUI

@MainActor
@Observable
private final class SnapshotStore {
    private(set) var snapshot: MarketSnapshot?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            snapshot = try await KoreaInvestmentAPIService.shared.makeKODEXUSSP500HSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SnapshotTab: View {
    @State private var store = SnapshotStore()

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = store.snapshot {
                    snapshotList(snapshot)
                } else if store.isLoading {
                    ProgressView("KODEX 미국S&P500(H) 지표를 계산하는 중")
                } else {
                    ContentUnavailableView {
                        Label("오늘 지표가 없습니다", systemImage: "chart.xyaxis.line")
                    } description: {
                        Text(store.errorMessage ?? "지표를 불러오지 못했습니다.")
                    } actions: {
                        Button("다시 시도") {
                            Task { await store.reload() }
                        }
                    }
                }
            }
            .navigationTitle("오늘")
            .toolbar { refreshButton }
        }
        .task { await store.reload() }
    }

    private func snapshotList(_ snapshot: MarketSnapshot) -> some View {
        List {
            Section {
                LabeledContent("기준일", value: snapshot.asOf)
                LabeledContent("종목", value: snapshot.ticker)
                if let price = snapshot.latestClosingPrice {
                    LabeledContent("현재 가격", value: DisplayNumber.decimal(price, digits: 0) + "원")
                }
                MetricRow(
                    title: "200거래일 전 종가 = 100",
                    value: DisplayNumber.decimal(snapshot.priceIndexed, digits: 1),
                    tone: snapshot.priceIndexed - 100
                )
            }
            Section("추세") {
                MetricRow(title: "20거래일 이동평균 대비", value: DisplayNumber.percent(snapshot.priceVsMa20Pct), tone: snapshot.priceVsMa20Pct)
                MetricRow(title: "60거래일 이동평균 대비", value: DisplayNumber.percent(snapshot.priceVsMa60Pct), tone: snapshot.priceVsMa60Pct)
                MetricRow(title: "200거래일 이동평균 대비", value: DisplayNumber.percent(snapshot.priceVsMa200Pct), tone: snapshot.priceVsMa200Pct)
                MetricRow(title: "200거래일 이동평균의 20거래일 변화", value: DisplayNumber.percent(snapshot.ma200Slope20dPct), tone: snapshot.ma200Slope20dPct)
                MetricRow(title: "200거래일 최고가 대비", value: DisplayNumber.percent(snapshot.drawdownFrom200dHighPct), tone: snapshot.drawdownFrom200dHighPct)
            }
            Section("연율 변동성") {
                MetricRow(title: "20거래일 일간 수익률", value: DisplayNumber.percent(snapshot.volatility20dPct), tone: nil)
                MetricRow(title: "60거래일 일간 수익률", value: DisplayNumber.percent(snapshot.volatility60dPct), tone: nil)
            }
            if let histogram = snapshot.macdHistogramAsPercentOfClose {
                Section("탄력") {
                    MetricRow(title: "MACD 히스토그램", value: DisplayNumber.percent(histogram), tone: histogram)
                }
            }
            Section("수익률") {
                MetricRow(title: "21거래일", value: DisplayNumber.percent(snapshot.return1mPct), tone: snapshot.return1mPct)
                MetricRow(title: "63거래일", value: DisplayNumber.percent(snapshot.return3mPct), tone: snapshot.return3mPct)
                MetricRow(title: "126거래일", value: DisplayNumber.percent(snapshot.return6mPct), tone: snapshot.return6mPct)
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

    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("새로고침", systemImage: "arrow.clockwise") {
                Task { await store.reload() }
            }
            .disabled(store.isLoading)
        }
    }
}
