import SwiftUI

@MainActor
@Observable
private final class CashWeightScreen {
    var market: CashWeightMarket = .kodexSP500
    private(set) var today: CashWeightRecord?
    private(set) var history: [CashWeightRecord] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private var reloadGeneration = 0

    func reload() async {
        reloadGeneration += 1
        let generation = reloadGeneration
        let market = market
        isLoading = true
        errorMessage = nil
        defer {
            if generation == reloadGeneration {
                isLoading = false
            }
        }

        let store = CashWeightStore.shared
        let day = CashWeightStore.seoulDay()
        do {
            let snapshot = try await market.makeSnapshot()
            let client = try JevClient.fromEnvironment()
            let previous = store.history(ticker: market.ticker).first { $0.day != day }?.fraction ?? 1
            _ = try await CashWeight.ask(
                snapshot: snapshot,
                previousFraction: previous,
                client: client,
                question: market.question,
                store: store
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        guard generation == reloadGeneration else { return }
        today = store.record(on: day, ticker: market.ticker)
        history = store.history(ticker: market.ticker).filter { $0.day != day }
    }
}

struct CashWeightTab: View {
    @State private var screen = CashWeightScreen()

    var body: some View {
        @Bindable var screen = screen
        NavigationStack {
            VStack(spacing: 0) {
                Picker("지표", selection: $screen.market) {
                    ForEach(CashWeightMarket.allCases) { market in
                        Text(market.title).tag(market)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal)
                .padding(.vertical, 8)
                Group {
                    if let today = screen.today {
                        recordList(today)
                    } else if screen.isLoading {
                        ProgressView("\(screen.market.title) 현금 비중을 판단하는 중")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ContentUnavailableView {
                            Label("비중 판단이 없습니다", systemImage: "chart.pie")
                        } description: {
                            Text(screen.errorMessage ?? "오늘 판단을 불러오지 못했습니다.")
                        } actions: {
                            Button("다시 시도") {
                                Task { await screen.reload() }
                            }
                        }
                    }
                }
            }
            .navigationTitle("비중")
            .toolbar { refreshButton }
        }
        .task { await screen.reload() }
        .onChange(of: screen.market) {
            Task { await screen.reload() }
        }
    }

    private func recordList(_ today: CashWeightRecord) -> some View {
        List {
            Section("오늘 판단") {
                LabeledContent("지표", value: screen.market.title)
                LabeledContent("날짜", value: today.day)
                LabeledContent("현금", value: percent(today.fraction))
                LabeledContent("주식", value: percent(1 - today.fraction))
                LabeledContent("Score", value: DisplayNumber.decimal(today.score, digits: 2))
                LabeledContent("confidence", value: DisplayNumber.decimal(today.confidence, digits: 2))
                if today.heldPrevious {
                    Text("confidence가 0.5 미만이라 어제 현금 비중 \(percent(today.previousFraction))을 유지했습니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("모델", value: today.model)
                LabeledContent("입력 토큰", value: DisplayNumber.decimal(Double(today.inputTokens), digits: 0))
            }
            JSONSection(title: "요청 JSON", json: today.requestJSON)
            JSONSection(title: "응답 JSON", json: today.responseJSON)
            snapshotSections(today.snapshot)
            if !screen.history.isEmpty {
                Section("이전 판단") {
                    ForEach(screen.history) { record in
                        NavigationLink {
                            CashWeightDetail(record: record)
                        } label: {
                            LabeledContent(record.day, value: "현금 \(percent(record.fraction))")
                        }
                    }
                }
            }
            if let errorMessage = screen.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .refreshable { await screen.reload() }
    }

    @ViewBuilder
    private func snapshotSections(_ snapshot: MarketSnapshot) -> some View {
        Section("판단에 쓴 지표") {
            LabeledContent("기준일", value: snapshot.asOf)
            LabeledContent("종목", value: snapshot.ticker)
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
        Section("수익률") {
            MetricRow(title: "21거래일", value: DisplayNumber.percent(snapshot.return1mPct), tone: snapshot.return1mPct)
            MetricRow(title: "63거래일", value: DisplayNumber.percent(snapshot.return3mPct), tone: snapshot.return3mPct)
            MetricRow(title: "126거래일", value: DisplayNumber.percent(snapshot.return6mPct), tone: snapshot.return6mPct)
        }
    }

    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("새로고침", systemImage: "arrow.clockwise") {
                Task { await screen.reload() }
            }
            .disabled(screen.isLoading)
        }
    }

    private func percent(_ fraction: Double) -> String {
        DisplayNumber.decimal(fraction * 100, digits: 1) + "%"
    }
}

private struct JSONSection: View {
    let title: String
    let json: String

    var body: some View {
        Section(title) {
            if json.isEmpty {
                Text("이 기록은 \(title)을 저장하기 전에 만들었습니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text(json)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }
}

private struct CashWeightDetail: View {
    let record: CashWeightRecord

    var body: some View {
        List {
            Section(record.day) {
                LabeledContent("현금", value: DisplayNumber.decimal(record.fraction * 100, digits: 1) + "%")
                LabeledContent("주식", value: DisplayNumber.decimal((1 - record.fraction) * 100, digits: 1) + "%")
                LabeledContent("Score", value: DisplayNumber.decimal(record.score, digits: 2))
                LabeledContent("confidence", value: DisplayNumber.decimal(record.confidence, digits: 2))
                LabeledContent("모델", value: record.model)
            }
            JSONSection(title: "요청 JSON", json: record.requestJSON)
            JSONSection(title: "응답 JSON", json: record.responseJSON)
            Section("판단에 쓴 지표") {
                LabeledContent("기준일", value: record.snapshot.asOf)
                MetricRow(
                    title: "200거래일 전 종가 = 100",
                    value: DisplayNumber.decimal(record.snapshot.priceIndexed, digits: 1),
                    tone: record.snapshot.priceIndexed - 100
                )
                MetricRow(title: "20거래일 이동평균 대비", value: DisplayNumber.percent(record.snapshot.priceVsMa20Pct), tone: record.snapshot.priceVsMa20Pct)
                MetricRow(title: "60거래일 이동평균 대비", value: DisplayNumber.percent(record.snapshot.priceVsMa60Pct), tone: record.snapshot.priceVsMa60Pct)
                MetricRow(title: "200거래일 이동평균 대비", value: DisplayNumber.percent(record.snapshot.priceVsMa200Pct), tone: record.snapshot.priceVsMa200Pct)
                MetricRow(title: "200거래일 이동평균의 20거래일 변화", value: DisplayNumber.percent(record.snapshot.ma200Slope20dPct), tone: record.snapshot.ma200Slope20dPct)
                MetricRow(title: "200거래일 최고가 대비", value: DisplayNumber.percent(record.snapshot.drawdownFrom200dHighPct), tone: record.snapshot.drawdownFrom200dHighPct)
                MetricRow(title: "20거래일 연율 변동성", value: DisplayNumber.percent(record.snapshot.volatility20dPct), tone: nil)
                MetricRow(title: "60거래일 연율 변동성", value: DisplayNumber.percent(record.snapshot.volatility60dPct), tone: nil)
                MetricRow(title: "21거래일", value: DisplayNumber.percent(record.snapshot.return1mPct), tone: record.snapshot.return1mPct)
                MetricRow(title: "63거래일", value: DisplayNumber.percent(record.snapshot.return3mPct), tone: record.snapshot.return3mPct)
                MetricRow(title: "126거래일", value: DisplayNumber.percent(record.snapshot.return6mPct), tone: record.snapshot.return6mPct)
            }
        }
        .navigationTitle(record.day)
    }
}
