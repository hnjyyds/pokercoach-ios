import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            if session.isAuthenticated {
                AppShellView()
            } else {
                AuthView()
            }
        }
        .tint(PokerTheme.ink)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environment(AppSession())
    }
}
