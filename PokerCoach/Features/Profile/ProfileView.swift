import SwiftUI

struct ProfileView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            PokerGlassBackdrop()
                .ignoresSafeArea()
            PokerAmbientLayer()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    pageHeader
                    profileHeader
                    proPlan
                    settingsList
                    logoutButton
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, PokerLayout.floatingTabBarClearance)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var pageHeader: some View {
        PokerPageHeader(
            eyebrow: "个人训练档案",
            title: "Profile",
            subtitle: session.user?.level ?? "新手入门",
            icon: "person.crop.circle.fill",
            tint: PokerTheme.ink
        )
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(PokerTheme.ink)
                    .frame(width: 68, height: 68)
                    .shadow(color: PokerTheme.ink.opacity(0.18), radius: 18, y: 10)
                Text(String(session.user?.name.prefix(1) ?? "P"))
                    .font(.title.weight(.black))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(session.user?.name ?? "Player")
                    .font(.title2.weight(.black))
                    .foregroundStyle(PokerTheme.ink)
                Text(session.user?.level ?? "新手入门")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PokerTheme.felt)
                Text(session.user?.email ?? "")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PokerTheme.muted)
            }
            Spacer(minLength: 0)
        }
    }

    private var proPlan: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title2.weight(.black))
                .foregroundStyle(PokerTheme.amber)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 6) {
                Text("Pro 训练计划")
                    .font(.headline.weight(.black))
                    .foregroundStyle(PokerTheme.ink)
                Text("高级范围表、错题复盘和专题训练会在下一版接入 StoreKit。")
                    .font(.subheadline)
                    .foregroundStyle(PokerTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var settingsList: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsRow(icon: "bell", title: "训练提醒", value: "20:30", tint: PokerTheme.amber)
            settingsRow(icon: "server.rack", title: "数据模式", value: session.usesOfflineMock ? "Mock" : "API", tint: PokerTheme.felt)
            settingsRow(icon: "shield", title: "隐私", value: "本地优先", tint: PokerTheme.violet)
        }
    }

    private func settingsRow(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 30)
            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(PokerTheme.ink)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(PokerTheme.muted)
        }
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            session.signOut()
        } label: {
            Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.headline.weight(.black))
        }
        .buttonStyle(.plain)
        .foregroundStyle(PokerTheme.coral)
        .padding(.top, 8)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let session = AppSession()
        session.startOfflineDemo()
        return NavigationStack {
            ProfileView()
        }
        .environment(session)
    }
}
