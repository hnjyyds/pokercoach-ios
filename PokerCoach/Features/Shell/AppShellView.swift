import SwiftUI

struct AppShellView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("训练", systemImage: "target")
            }

            NavigationStack {
                TrainingView()
            }
            .tabItem {
                Label("题库", systemImage: "rectangle.stack")
            }

            NavigationStack {
                AIBattleView()
            }
            .tabItem {
                Label("对战", systemImage: "person.3.fill")
            }

            NavigationStack {
                OddsCalculatorView()
            }
            .tabItem {
                Label("工具", systemImage: "percent")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person.crop.circle")
            }
        }
        .tint(PokerTheme.ink)
        .task {
            await session.loadHomeData()
        }
    }
}

struct AppShellView_Previews: PreviewProvider {
    static var previews: some View {
        let session = AppSession()
        session.startOfflineDemo()
        return AppShellView()
            .environment(session)
    }
}
