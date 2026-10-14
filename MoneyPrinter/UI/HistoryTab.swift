//
//  HistoryTab.swift
//  MoneyPrinter
//
//  Created by yangjs on 10/15/26.
//

import Charts
import SwiftUI

@MainActor
@Observable
private final class CashWeightHistory {
    var market: CashWeightMarket = .kodexSP500
    private(set) var kospiRecords: [CashWeightRecord] = []
    private(set) var snpRecords: [CashWeightRecord] = []

    /// 최근 판단이 앞에 옵니다.
    var records: [CashWeightRecord] {
        switch market {
        case .kodexSP500: snpRecords
        case .kodex200: kospiRecords
        }
    }

    func load() {
        let store = CashWeightStore.shared
        kospiRecords = store.history(ticker: CashWeightMarket.kodex200.ticker)
        snpRecords = store.history(ticker: CashWeightMarket.kodexSP500.ticker)
    }
}

struct HistoryTab: View {
    @State private var screen = CashWeightHistory()

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
                if screen.records.isEmpty {
                    ContentUnavailableView {
                        Label("쌓인 판단이 없습니다", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("비중 탭에서 판단을 받으면 날짜별로 여기에 남습니다.")
                    }
                } else {
                    recordList(screen.records)
                }
            }
            .navigationTitle("기록")
        }
        .onAppear { screen.load() }
    }

    private func recordList(_ records: [CashWeightRecord]) -> some View {
        List {
            Section("현금 비중 추이") {
                CashWeightChart(records: Array(records.reversed()))
                    .frame(height: 200)
            }
            Section("요약") {
                LabeledContent("판단 수", value: "\(records.count)일")
                LabeledContent("평균 현금", value: percent(records.map(\.fraction).reduce(0, +) / Double(records.count)))
                if let first = records.last, let last = records.first {
                    LabeledContent("기간", value: "\(first.day) ~ \(last.day)")
                }
            }
            Section("날짜별 판단") {
                ForEach(records) { record in
                    NavigationLink {
                        CashWeightDetail(record: record)
                    } label: {
                        HistoryRow(record: record)
                    }
                }
            }
        }
        .refreshable { screen.load() }
    }

    private func percent(_ fraction: Double) -> String {
        DisplayNumber.decimal(fraction * 100, digits: 1) + "%"
    }
}

private struct CashWeightChart: View {
    let records: [CashWeightRecord]

    var body: some View {
        Chart(records) { record in
            LineMark(
                x: .value("날짜", record.day),
                y: .value("현금", record.fraction * 100)
            )
            PointMark(
                x: .value("날짜", record.day),
                y: .value("현금", record.fraction * 100)
            )
        }
        .chartYScale(domain: 0 ... 100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let number = value.as(Int.self) {
                        Text("\(number)%")
                    }
                }
            }
        }
        .chartXAxis(.hidden)
    }
}

private struct HistoryRow: View {
    let record: CashWeightRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.day)
                    .font(.headline)
                Spacer()
                Text("현금 \(DisplayNumber.decimal(record.fraction * 100, digits: 1))%")
                    .monospacedDigit()
            }
            HStack {
                Text("Score \(DisplayNumber.decimal(record.score, digits: 2))")
                Text("confidence \(DisplayNumber.decimal(record.confidence, digits: 2))")
                Spacer()
                if let histogram = record.snapshot.macdHistogramAsPercentOfClose {
                    Text("MACD \(DisplayNumber.percent(histogram))")
                        .foregroundStyle(QuoteTone.color(histogram))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
    }
}
