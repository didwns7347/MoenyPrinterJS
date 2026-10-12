import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AccountTab()
                .tabItem {
                    Label("계좌", systemImage: "wonsign.circle")
                }
            SnapshotTab()
                .tabItem {
                    Label("오늘", systemImage: "chart.xyaxis.line")
                }
            CashWeightTab()
                .tabItem {
                    Label("비중", systemImage: "chart.pie")
                }
        }
    }
}

#Preview {
    ContentView()
}
