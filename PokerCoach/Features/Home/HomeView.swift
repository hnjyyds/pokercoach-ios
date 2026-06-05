import SwiftUI

struct HomeView: View {
    @Environment(AppSession.self) private var session
    @State private var isModuleProgressExpanded = false
    @State private var isMistakesExpanded = true

    var body: some View {
        ZStack {
            PokerGlassBackdrop()
                .ignoresSafeArea()

            HomeAmbientLayer()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if let dashboard = session.dashboard {
                        DailyPlanView(plan: dashboard.dailyPlan)
                        metricGrid(user: dashboard.user)
                        moduleProgress(plan: dashboard.dailyPlan)
                        mistakesView(dashboard.recentMistakes)
                    } else {
                        EmptyStateView(icon: "suit.spade", title: "训练数据加载中", message: "稍后会显示今日训练安排。")
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, PokerLayout.floatingTabBarClearance)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if session.usesOfflineMock {
                    Label("Mock", systemImage: "server.rack")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PokerTheme.amber)
                }
            }
        }
        .refreshable {
            await session.loadHomeData()
        }
    }

    private var header: some View {
        PokerPageHeader(
            eyebrow: "今日训练节奏",
            title: "Hi, \(session.user?.name ?? "Player")",
            subtitle: "把关键决策练成直觉",
            icon: "target",
            tint: PokerTheme.ink
        )
    }

    private func metricGrid(user: AppUser) -> some View {
        HStack(spacing: 24) {
            FloatingMetric(title: "连续训练", value: "\(user.streakDays) 天", icon: "flame.fill", tint: PokerTheme.coral)
            FloatingMetric(title: "技能分", value: "\(user.skillScore)", icon: "chart.line.uptrend.xyaxis", tint: PokerTheme.felt)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    private func moduleProgress(plan: DailyPlan) -> some View {
        VStack(alignment: .leading, spacing: isModuleProgressExpanded ? 12 : 0) {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                    isModuleProgressExpanded.toggle()
                }
            } label: {
                HomeSectionHeader(title: "模块进度", icon: "rectangle.stack.fill") {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .black))
                        .rotationEffect(.degrees(isModuleProgressExpanded ? 180 : 0))
                        .frame(width: 28, height: 28)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isModuleProgressExpanded ? "收起模块进度" : "展开模块进度")

            if isModuleProgressExpanded {
                ForEach(plan.modules) { module in
                    ModuleRow(module: module)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private func mistakesView(_ mistakes: [String]) -> some View {
        VStack(alignment: .leading, spacing: isMistakesExpanded ? 12 : 0) {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                    isMistakesExpanded.toggle()
                }
            } label: {
                HomeSectionHeader(title: "最近错题", icon: "lightbulb.fill") {
                    HStack(spacing: 8) {
                        Text("\(mistakes.count) 条")
                            .font(.caption.monospacedDigit().weight(.black))
                            .foregroundStyle(PokerTheme.amber)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(PokerTheme.amber.opacity(0.12), in: Capsule())

                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .black))
                            .rotationEffect(.degrees(isMistakesExpanded ? 180 : 0))
                            .frame(width: 28, height: 28)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isMistakesExpanded ? "收起最近错题" : "展开最近错题")

            if isMistakesExpanded {
                ForEach(Array(mistakes.enumerated()), id: \.element) { index, mistake in
                    MistakeRow(index: index, text: mistake)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(.top, 4)
    }
}

private struct HomeSectionHeader<Trailing: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var trailing: Trailing

    init(title: String, icon: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.icon = icon
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(PokerTheme.ink)
                .frame(width: 30, height: 30)

            Text(title)
                .font(.title3.weight(.black))
                .foregroundStyle(PokerTheme.ink)

            Spacer(minLength: 0)

            trailing
                .foregroundStyle(PokerTheme.ink)
        }
    }
}

private extension HomeSectionHeader where Trailing == EmptyView {
    init(title: String, icon: String) {
        self.title = title
        self.icon = icon
        self.trailing = EmptyView()
    }
}

private struct DailyPlanView: View {
    let plan: DailyPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.title)
                    .font(.title2.weight(.black))
                    .foregroundStyle(PokerTheme.ink)
                Spacer()
                Text("\(plan.completedMinutes)/\(plan.targetMinutes)")
                    .font(.title3.monospacedDigit().weight(.black))
                    .foregroundStyle(PokerTheme.felt)
            }

            Text(plan.focus)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PokerTheme.muted)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "#DDE3EA").opacity(0.74))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [PokerTheme.felt, Color(hex: "#6DE7D0")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, proxy.size.width * plan.progress))
                        .shadow(color: PokerTheme.felt.opacity(0.28), radius: 12, y: 5)
                }
            }
            .frame(height: 7)
        }
        .padding(.vertical, 6)
    }
}

private struct HomeAmbientLayer: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                var table = Path()
                table.addEllipse(in: CGRect(
                    x: -size.width * 0.18,
                    y: size.height * 0.50,
                    width: size.width * 1.36,
                    height: size.height * 0.42
                ))
                context.fill(
                    table,
                    with: .radialGradient(
                        Gradient(colors: [
                            PokerTheme.felt.opacity(0.22),
                            PokerTheme.felt.opacity(0.08),
                            Color.clear
                        ]),
                        center: CGPoint(x: size.width * 0.50, y: size.height * 0.71),
                        startRadius: 16,
                        endRadius: size.width * 0.70
                    )
                )

                var orbit = Path()
                orbit.addEllipse(in: CGRect(
                    x: size.width * 0.05,
                    y: size.height * 0.57,
                    width: size.width * 0.90,
                    height: size.height * 0.24
                ))
                context.stroke(
                    orbit,
                    with: .color(PokerTheme.felt.opacity(0.14)),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 14])
                )

                let chipColors = [
                    PokerTheme.violet,
                    PokerTheme.felt,
                    PokerTheme.amber,
                    PokerTheme.coral
                ]
                for index in chipColors.indices {
                    let phase = time * 0.55 + Double(index) * 0.76
                    let center = CGPoint(
                        x: size.width * (0.64 + CGFloat(index) * 0.075),
                        y: size.height * 0.82 + CGFloat(sin(phase)) * 4
                    )
                    let rect = CGRect(x: center.x - 15, y: center.y - 15, width: 30, height: 30)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                chipColors[index].opacity(0.24),
                                chipColors[index].opacity(0.12),
                                chipColors[index].opacity(0.03)
                            ]),
                            center: center,
                            startRadius: 2,
                            endRadius: 20
                        )
                    )
                    context.stroke(
                        Path(ellipseIn: rect.insetBy(dx: 4, dy: 4)),
                        with: .color(.white.opacity(0.22)),
                        lineWidth: 2
                    )
                }

                for index in 0..<3 {
                    var path = Path()
                    let y = size.height * (0.18 + CGFloat(index) * 0.18)
                    let offset = CGFloat(sin(time * 0.24 + Double(index))) * 10
                    path.move(to: CGPoint(x: -40, y: y + offset))
                    path.addCurve(
                        to: CGPoint(x: size.width + 40, y: y + 18 - offset),
                        control1: CGPoint(x: size.width * 0.24, y: y - 24),
                        control2: CGPoint(x: size.width * 0.78, y: y + 32)
                    )
                    context.stroke(path, with: .color(Color(hex: "#D8E4F2").opacity(0.32)), lineWidth: 1)
                }
            }
        }
    }
}

private struct FloatingMetric: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.monospacedDigit().weight(.black))
                    .foregroundStyle(PokerTheme.ink)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PokerTheme.muted)
            }
        }
    }
}

private struct ModuleRow: View {
    let module: ModuleCard

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: module.icon)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Color(hex: module.accent), in: Circle())
                .shadow(color: Color(hex: module.accent).opacity(0.18), radius: 10, y: 6)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(module.title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(PokerTheme.ink)
                    Spacer()
                    Text("\(Int(module.progress * 100))%")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(PokerTheme.muted)
                }
                ProgressView(value: module.progress)
                    .tint(Color(hex: module.accent))
            }
        }
        .padding(.vertical, 8)
    }
}

private struct MistakeRow: View {
    let index: Int
    let text: String

    private var tint: Color {
        index.isMultiple(of: 2) ? PokerTheme.amber : PokerTheme.coral
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: index.isMultiple(of: 2) ? "exclamationmark" : "arrow.triangle.2.circlepath")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(tint, in: Circle())
                .shadow(color: tint.opacity(0.18), radius: 9, y: 5)
                .padding(.top, 1)

            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PokerTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let session = AppSession()
        session.startOfflineDemo()
        return NavigationStack {
            HomeView()
        }
        .environment(session)
    }
}
