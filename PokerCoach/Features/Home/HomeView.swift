import Foundation
import SwiftUI

struct HomeView: View {
    @Environment(AppSession.self) private var session
    @State private var isModuleProgressExpanded = false
    @State private var isMistakesExpanded = true
    @State private var selectedMistake: BattleMistakeSummary?

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
                        mistakesView(session.mistakeSummaries)
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
        .task {
            if session.mistakeSummaries.isEmpty {
                await session.loadMistakes()
            }
        }
        .sheet(item: $selectedMistake) { mistake in
            MistakeReviewView(summary: mistake)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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

    private func mistakesView(_ mistakes: [BattleMistakeSummary]) -> some View {
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
                if mistakes.isEmpty {
                    EmptyStateView(icon: "checkmark.seal", title: "暂无错题", message: "对战或训练里出现偏差后会自动沉淀到这里。")
                        .padding(.top, 4)
                        .transition(.opacity)
                } else {
                    ForEach(Array(mistakes.enumerated()), id: \.element.id) { index, mistake in
                        Button {
                            selectedMistake = mistake
                        } label: {
                            MistakeRow(index: index, mistake: mistake)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
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
    let mistake: BattleMistakeSummary

    private var tint: Color {
        Color(hex: mistake.accent)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mistake.icon)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint, in: Circle())
                .shadow(color: tint.opacity(0.18), radius: 9, y: 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(mistakeDisplayTitle(mistake))
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(PokerTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                HStack(spacing: 8) {
                    PlayingCardsRow(
                        cardCodes: mistake.heroCards,
                        width: 24,
                        height: 32,
                        spacing: -5,
                        rotation: 2
                    )

                    Text("你\(mistake.userActionLabel) · 应\(mistake.recommendedActionLabel)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PokerTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }

            Spacer(minLength: 0)

            Text("-\(mistake.evDeltaBb, specifier: "%.1f")BB")
                .font(.caption.monospacedDigit().weight(.black))
                .foregroundStyle(PokerTheme.coral)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.black))
                .foregroundStyle(PokerTheme.muted)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
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

private struct MistakeReviewView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    let summary: BattleMistakeSummary

    @State private var detail: BattleMistakeDetail?
    @State private var draft = ""
    @State private var isLoading = false
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ZStack {
                PokerGlassBackdrop()
                    .ignoresSafeArea()
                PokerAmbientLayer()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            header

                            if let detail {
                                MistakeSpotView(detail: detail)
                                actionCompare(detail)
                                candidateList(detail)
                                explanation(detail)
                                coachThread(detail)
                            } else {
                                ProgressView()
                                    .tint(PokerTheme.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 80)
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 18)
                        .padding(.bottom, 24)
                    }

                    if detail != nil {
                        composer
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.black))
                            .foregroundStyle(PokerTheme.ink)
                            .frame(width: 34, height: 34)
                            .background(.white.opacity(0.74), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .task(id: summary.id) {
                await loadDetail()
            }
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        PokerPageHeader(
            eyebrow: "错题复盘",
            title: "\(summary.position) Spot",
            subtitle: mistakeDisplayTitle(summary),
            icon: summary.icon,
            tint: Color(hex: summary.accent)
        )
    }

    private func actionCompare(_ detail: BattleMistakeDetail) -> some View {
        HStack(spacing: 12) {
            ReviewActionPill(
                title: "你的动作",
                action: detail.userActionLabel,
                amount: bb(detail.userTotalBb),
                icon: "xmark.circle.fill",
                tint: PokerTheme.coral
            )

            Image(systemName: "arrow.right")
                .font(.headline.weight(.black))
                .foregroundStyle(PokerTheme.muted)

            ReviewActionPill(
                title: "建议动作",
                action: detail.recommendedActionLabel,
                amount: bb(detail.recommendedTotalBb),
                icon: "checkmark.seal.fill",
                tint: PokerTheme.felt
            )
        }
    }

    private func candidateList(_ detail: BattleMistakeDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "决策候选", icon: "point.3.connected.trianglepath.dotted")

            ForEach(detail.candidates) { candidate in
                ReviewCandidateRow(candidate: candidate)
            }
        }
    }

    private func explanation(_ detail: BattleMistakeDetail) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ReviewTextBlock(
                title: "为什么错",
                icon: "exclamationmark.bubble.fill",
                tint: PokerTheme.coral,
                text: detail.whyWrong
            )

            ReviewTextBlock(
                title: "应该怎么做",
                icon: "checkmark.seal.fill",
                tint: PokerTheme.felt,
                text: detail.correctPlay
            )
        }
    }

    private func coachThread(_ detail: BattleMistakeDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "导师复盘", icon: "person.wave.2.fill")

            ForEach(detail.coachMessages) { message in
                CoachBubble(message: message)
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("问德扑导师", text: $draft, axis: .vertical)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1...3)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(PokerTheme.border.opacity(0.70), lineWidth: 1)
                }

            Button {
                Task { await sendMessage() }
            } label: {
                if isSending {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                }
            }
            .frame(width: 48, height: 48)
            .background(PokerTheme.ink, in: Circle())
            .shadow(color: PokerTheme.ink.opacity(0.18), radius: 12, y: 7)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial)
    }

    private func loadDetail() async {
        isLoading = true
        detail = await session.mistakeDetail(id: summary.id)
        isLoading = false
    }

    private func sendMessage() async {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        draft = ""
        isSending = true
        if let updated = await session.coachMistake(id: summary.id, message: message) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                detail = updated
            }
        }
        isSending = false
    }
}

private struct MistakeSpotView: View {
    let detail: BattleMistakeDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Capsule()
                    .fill(
                        RadialGradient(
                            colors: [
                                PokerTheme.felt.opacity(0.22),
                                PokerTheme.felt.opacity(0.08),
                                Color(hex: "#EAF2FF").opacity(0.34)
                            ],
                            center: .center,
                            startRadius: 18,
                            endRadius: 170
                        )
                    )
                    .overlay {
                        Capsule()
                            .stroke(PokerTheme.felt.opacity(0.18), style: StrokeStyle(lineWidth: 1.3, dash: [8, 12]))
                            .padding(18)
                    }

                VStack(spacing: 16) {
                    if detail.board.isEmpty {
                        Text(streetDisplay(detail.street))
                            .font(.title3.weight(.black))
                            .foregroundStyle(PokerTheme.ink)
                    } else {
                        PlayingCardsRow(cardCodes: detail.board, width: 42, height: 56, spacing: -7, rotation: 3)
                    }

                    PlayingCardsRow(cardCodes: detail.heroCards, width: 42, height: 56, spacing: -6, rotation: 3)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "eye.fill")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(PokerTheme.ink, in: Circle())
                            .offset(x: 10, y: -8)
                    }
                }
            }
            .frame(height: 170)

            HStack(spacing: 18) {
                ReviewMetric(title: "Pot", value: bb(detail.scenario.potBb), icon: "circle.grid.3x3.fill", tint: PokerTheme.amber)
                ReviewMetric(title: "Stack", value: bb(detail.scenario.stackBb), icon: "square.stack.3d.up.fill", tint: PokerTheme.violet)
                ReviewMetric(title: "SPR", value: oneDecimal(detail.scenario.spr), icon: "speedometer", tint: PokerTheme.felt)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(detail.scenario.tableSeats) { seat in
                        SeatContextChip(seat: seat)
                    }
                }
            }
        }
    }
}

private struct ReviewActionPill: View {
    let title: String
    let action: String
    let amount: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(tint, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PokerTheme.muted)
                Text("\(action) \(amount)")
                    .font(.headline.monospacedDigit().weight(.black))
                    .foregroundStyle(PokerTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}

private struct ReviewCandidateRow: View {
    let candidate: BattleMistakeCandidate

    private var tint: Color {
        candidate.isRecommended ? PokerTheme.felt : PokerTheme.muted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: candidate.isRecommended ? "checkmark.seal.fill" : "circle")
                    .font(.headline.weight(.black))
                    .foregroundStyle(tint)
                    .frame(width: 26, height: 26)

                Text(candidate.label)
                    .font(.headline.weight(.black))
                    .foregroundStyle(PokerTheme.ink)

                Text(bb(candidate.targetTotalBb))
                    .font(.caption.monospacedDigit().weight(.black))
                    .foregroundStyle(PokerTheme.muted)

                Spacer(minLength: 0)

                Text("\(candidate.evBb, specifier: "%+.1f")BB")
                    .font(.caption.monospacedDigit().weight(.black))
                    .foregroundStyle(candidate.evBb >= 0 ? PokerTheme.felt : PokerTheme.coral)
            }

            Text(candidate.reason)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PokerTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 5)
    }
}

private struct ReviewTextBlock: View {
    let title: String
    let icon: String
    let tint: Color
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PokerTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct CoachBubble: View {
    let message: CoachMessageSnapshot

    private var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 38)
            }

            Text(message.content)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isUser ? .white : PokerTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(isUser ? PokerTheme.ink : .white.opacity(0.84), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: PokerTheme.ink.opacity(isUser ? 0.12 : 0.05), radius: 12, y: 6)

            if !isUser {
                Spacer(minLength: 38)
            }
        }
    }
}

private struct ReviewMetric: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.monospacedDigit().weight(.black))
                    .foregroundStyle(PokerTheme.ink)
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PokerTheme.muted)
            }
        }
    }
}

private struct SeatContextChip: View {
    let seat: BattleMistakeTableSeat

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: seat.isHero ? "person.fill.checkmark" : "person.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(seat.isHero ? PokerTheme.felt : PokerTheme.muted)
            Text("\(seat.position) \(seat.name)")
                .font(.caption.weight(.black))
                .foregroundStyle(PokerTheme.ink)
            Text(bb(seat.stackBb))
                .font(.caption2.monospacedDigit().weight(.bold))
                .foregroundStyle(PokerTheme.muted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(seat.isHero ? 0.88 : 0.60), in: Capsule())
    }
}

private func streetDisplay(_ street: String) -> String {
    switch street {
    case "preflop": "Preflop"
    case "flop": "Flop"
    case "turn": "Turn"
    case "river": "River"
    default: street.capitalized
    }
}

private func mistakeDisplayTitle(_ mistake: BattleMistakeSummary) -> String {
    let trimmed = mistake.title.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.contains("：") {
        return "\(mistake.position) 决策偏差"
    }
    if trimmed.range(of: #"[AKQJT2-9]{2}[so]?"#, options: .regularExpression) != nil {
        return "\(mistake.position) 决策偏差"
    }
    return trimmed
}

private func bb(_ value: Double) -> String {
    let rounded = (value * 10).rounded() / 10
    if rounded == rounded.rounded() {
        return "\(Int(rounded))BB"
    }
    return "\(rounded)BB"
}

private func oneDecimal(_ value: Double) -> String {
    let rounded = (value * 10).rounded() / 10
    if rounded == rounded.rounded() {
        return "\(Int(rounded)).0"
    }
    return "\(rounded)"
}
