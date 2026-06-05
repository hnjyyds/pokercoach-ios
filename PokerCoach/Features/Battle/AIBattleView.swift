import SwiftUI

struct AIBattleView: View {
    @Environment(AppSession.self) private var session

    @State private var selectedTableSize = 6
    @State private var selectedSeat = 2
    @State private var selectedStartingStackBb = 100
    @State private var selectedBattleMode = "spectate"
    @State private var isReady = false
    @State private var isWatchingLiveBattle = false
    @State private var initialBattleSnapshot: BattleSessionSnapshot?
    @State private var isStartingBattle = false
    @State private var startErrorMessage: String?

    private let tableSizes = [2, 6, 9]
    private let stackDepths = [40, 100, 200]
    private let battleModes = [("spectate", "观战", "eye.fill"), ("play", "入座", "person.fill.badge.plus")]

    private var agents: [BattleAgent] {
        Array(BattleAgent.mock.prefix(selectedTableSize))
    }

    private var selectedAgent: BattleAgent {
        agents.indices.contains(selectedSeat) ? agents[selectedSeat] : agents[0]
    }

    var body: some View {
        ZStack {
            BattleBackdrop()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    tableSizePicker
                    stackDepthPicker
                    battleModePicker

                    BattleTableView(
                        agents: agents,
                        tableSize: selectedTableSize,
                        selectedSeat: selectedSeat
                    ) { index in
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                            selectedSeat = index
                        }
                    }

                    SpectatorPanel(
                        agent: selectedAgent,
                        position: seatPosition(for: selectedTableSize, index: selectedSeat),
                        mode: selectedBattleMode,
                        isStarting: isStartingBattle,
                        errorMessage: startErrorMessage,
                        onStart: {
                            startBattle()
                        }
                    )
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, PokerLayout.floatingTabBarClearance)
                .opacity(isReady ? 1 : 0)
                .offset(y: isReady ? 0 : 14)
            }
        }
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isWatchingLiveBattle) {
            LiveBattleView(
                agents: agents,
                tableSize: selectedTableSize,
                selectedSeat: selectedSeat,
                initialSnapshot: initialBattleSnapshot
            )
        }
        .task {
            withAnimation(.spring(response: 0.68, dampingFraction: 0.86)) {
                isReady = true
            }
        }
        .onChange(of: selectedTableSize) { _, newValue in
            selectedSeat = min(selectedSeat, newValue - 1)
            startErrorMessage = nil
        }
        .onChange(of: selectedSeat) { _, _ in
            startErrorMessage = nil
        }
    }

    private func startBattle() {
        guard !isStartingBattle else { return }

        Task {
            isStartingBattle = true
            startErrorMessage = nil
            let snapshot = await session.createBattleSession(
                tableSize: selectedTableSize,
                observerSeat: selectedSeat,
                startingStackBb: Double(selectedStartingStackBb),
                mode: selectedBattleMode,
                playerSeat: selectedBattleMode == "play" ? selectedSeat : nil
            )
            if let snapshot {
                initialBattleSnapshot = snapshot
                isWatchingLiveBattle = true
            } else {
                initialBattleSnapshot = nil
                if session.usesOfflineMock {
                    startErrorMessage = "需要连接后端"
                } else {
                    startErrorMessage = session.errorMessage ?? "创建失败"
                }
            }
            isStartingBattle = false
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.black))
                Text("AI 对战实验室")
                    .font(.caption.weight(.black))
            }
            .foregroundStyle(Color(hex: "#071226"))
            .padding(.horizontal, 2)

            HStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(Color(hex: "#071226"))
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Battle")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#050812"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text("选择桌型、筹码与参与方式")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: "#697386"))
                }
            }
        }
        .padding(.top, 4)
    }

    private var tableSizePicker: some View {
        HStack(spacing: 22) {
            ForEach(tableSizes, id: \.self) { size in
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedTableSize = size
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: size == 2 ? "person.2.fill" : "person.3.fill")
                            .font(.headline.weight(.black))
                        Text("\(size) 人桌")
                            .font(.subheadline.weight(.black))
                    }
                    .foregroundStyle(selectedTableSize == size ? Color(hex: "#071226") : Color(hex: "#697386"))
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(selectedTableSize == size ? Color(hex: "#071226") : .clear)
                            .frame(height: 3)
                            .offset(y: 8)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(BattlePressButtonStyle())
                .accessibilityLabel("\(size) 人桌")
            }
            Spacer(minLength: 0)
        }
    }

    private var stackDepthPicker: some View {
        HStack(spacing: 22) {
            ForEach(stackDepths, id: \.self) { depth in
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedStartingStackBb = depth
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "circle.grid.3x3.fill")
                            .font(.headline.weight(.black))
                        Text("\(depth)BB")
                            .font(.subheadline.weight(.black))
                            .monospacedDigit()
                    }
                    .foregroundStyle(selectedStartingStackBb == depth ? Color(hex: "#071226") : Color(hex: "#697386"))
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(selectedStartingStackBb == depth ? Color(hex: "#071226") : .clear)
                            .frame(height: 3)
                            .offset(y: 8)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(BattlePressButtonStyle())
                .accessibilityLabel("初始筹码 \(depth) BB")
            }
            Spacer(minLength: 0)
        }
    }

    private var battleModePicker: some View {
        HStack(spacing: 22) {
            ForEach(battleModes, id: \.0) { mode in
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedBattleMode = mode.0
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: mode.2)
                            .font(.headline.weight(.black))
                        Text(mode.1)
                            .font(.subheadline.weight(.black))
                    }
                    .foregroundStyle(selectedBattleMode == mode.0 ? Color(hex: "#071226") : Color(hex: "#697386"))
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(selectedBattleMode == mode.0 ? Color(hex: "#071226") : .clear)
                            .frame(height: 3)
                            .offset(y: 8)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(BattlePressButtonStyle())
                .accessibilityLabel(mode.1)
            }
            Spacer(minLength: 0)
        }
    }
}

private func seatPosition(for tableSize: Int, index: Int) -> String {
    let layouts: [Int: [String]] = [
        2: ["SB", "BB"],
        3: ["BTN", "SB", "BB"],
        4: ["BTN", "SB", "BB", "CO"],
        5: ["BTN", "SB", "BB", "UTG", "CO"],
        6: ["BTN", "SB", "BB", "UTG", "HJ", "CO"],
        7: ["BTN", "SB", "BB", "UTG", "LJ", "HJ", "CO"],
        8: ["BTN", "SB", "BB", "UTG", "UTG+1", "LJ", "HJ", "CO"],
        9: ["BTN", "SB", "BB", "UTG", "UTG+1", "MP", "LJ", "HJ", "CO"]
    ]
    guard let positions = layouts[tableSize], !positions.isEmpty else {
        return "BTN"
    }
    return positions[index % positions.count]
}

private struct BattleAgent: Identifiable, Hashable {
    let id: Int
    let name: String
    let style: String
    let symbol: String
    let color: Color
    let avatarSeed: String
    let archetype: String
    let masteryLabel: String
    let gtoScore: Int
    let exploitScore: Int
    let postflopScore: Int
    let riskProfile: String
    let strategyTags: [String]

    static let mock: [BattleAgent] = [
        BattleAgent(id: 0, name: "River", style: "紧凶", symbol: "bolt.fill", color: Color(hex: "#8B5CF6"), avatarSeed: "river-gto-pro", archetype: "极化进攻", gtoScore: 96, exploitScore: 94, postflopScore: 95, riskProfile: "进攻", strategyTags: ["GTO", "范围", "极化"]),
        BattleAgent(id: 1, name: "Nash", style: "GTO", symbol: "function", color: Color(hex: "#13C8A6"), avatarSeed: "nash-solver", archetype: "Solver 均衡", gtoScore: 98, exploitScore: 90, postflopScore: 96, riskProfile: "纪律", strategyTags: ["GTO", "纪律", "SPR"]),
        BattleAgent(id: 2, name: "Ivy", style: "偷盲", symbol: "eye.fill", color: Color(hex: "#F59E0B"), avatarSeed: "ivy-control", archetype: "控池抓诈", gtoScore: 96, exploitScore: 88, postflopScore: 94, riskProfile: "纪律", strategyTags: ["GTO", "控池", "抓诈"]),
        BattleAgent(id: 3, name: "Mira", style: "控池", symbol: "circle.hexagongrid.fill", color: Color(hex: "#EF4444"), avatarSeed: "mira-aggro", archetype: "极化进攻", gtoScore: 94, exploitScore: 96, postflopScore: 95, riskProfile: "进攻", strategyTags: ["GTO", "红线", "极化"]),
        BattleAgent(id: 4, name: "Leo", style: "松凶", symbol: "flame.fill", color: Color(hex: "#3B82F6"), avatarSeed: "leo-lag", archetype: "极化进攻", gtoScore: 92, exploitScore: 95, postflopScore: 93, riskProfile: "进攻", strategyTags: ["GTO", "红线", "压迫"]),
        BattleAgent(id: 5, name: "Nova", style: "读牌", symbol: "sparkles", color: Color(hex: "#EC4899"), avatarSeed: "nova-reader", archetype: "范围读牌", gtoScore: 96, exploitScore: 91, postflopScore: 95, riskProfile: "均衡", strategyTags: ["GTO", "阻断", "纹理"]),
        BattleAgent(id: 6, name: "Kane", style: "短码", symbol: "shield.fill", color: Color(hex: "#64748B"), avatarSeed: "kane-short", archetype: "短码专家", gtoScore: 97, exploitScore: 92, postflopScore: 94, riskProfile: "纪律", strategyTags: ["GTO", "短码", "ICM"]),
        BattleAgent(id: 7, name: "Echo", style: "跟注", symbol: "waveform.path.ecg", color: Color(hex: "#14B8A6"), avatarSeed: "echo-exploit", archetype: "控池抓诈", gtoScore: 95, exploitScore: 91, postflopScore: 94, riskProfile: "均衡", strategyTags: ["GTO", "控池", "薄价值"]),
        BattleAgent(id: 8, name: "Ace", style: "压迫", symbol: "suit.spade.fill", color: Color(hex: "#0F172A"), avatarSeed: "ace-pressure", archetype: "极化进攻", gtoScore: 94, exploitScore: 96, postflopScore: 95, riskProfile: "进攻", strategyTags: ["GTO", "压迫", "盲注战"])
    ]

    init(
        id: Int,
        name: String,
        style: String,
        symbol: String,
        color: Color,
        avatarSeed: String,
        archetype: String = "Solver 均衡",
        masteryLabel: String = "大师级",
        gtoScore: Int = 94,
        exploitScore: Int = 92,
        postflopScore: Int = 94,
        riskProfile: String = "均衡",
        strategyTags: [String] = ["GTO", "范围", "SPR"]
    ) {
        self.id = id
        self.name = name
        self.style = style
        self.symbol = symbol
        self.color = color
        self.avatarSeed = avatarSeed
        self.archetype = archetype
        self.masteryLabel = masteryLabel
        self.gtoScore = gtoScore
        self.exploitScore = exploitScore
        self.postflopScore = postflopScore
        self.riskProfile = riskProfile
        self.strategyTags = strategyTags
    }

    init(seat: BattleSeatSnapshot) {
        id = seat.index
        name = seat.agent.name
        style = seat.agent.style
        symbol = BattleAgent.symbol(for: seat.agent.style)
        color = Color(hex: seat.agent.accent)
        avatarSeed = seat.agent.avatarSeed
        archetype = seat.agent.archetype
        masteryLabel = seat.agent.masteryLabel
        gtoScore = seat.agent.gtoScore
        exploitScore = seat.agent.exploitScore
        postflopScore = seat.agent.postflopScore
        riskProfile = seat.agent.riskProfile
        strategyTags = seat.agent.strategyTags
    }

    private static func symbol(for style: String) -> String {
        if style.contains("GTO") || style.contains("均衡") { return "function" }
        if style.contains("压迫") || style.contains("进攻") { return "bolt.fill" }
        if style.contains("池控") { return "eye.fill" }
        if style.contains("短码") { return "shield.fill" }
        return "person.crop.circle.fill"
    }
}

private struct BattleBackdrop: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                context.fill(
                    Path(rect),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: "#FCFDFF"),
                            Color(hex: "#F5F9FF"),
                            Color(hex: "#F2FBF7")
                        ]),
                        startPoint: CGPoint(x: rect.minX, y: rect.minY),
                        endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                    )
                )

                for x in stride(from: CGFloat(9), through: size.width, by: 17) {
                    for y in stride(from: CGFloat(12), through: size.height, by: 17) {
                        let pulse = sin(Double(x + y) * 0.017 + time * 0.42)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                            with: .color(Color(hex: "#DDE4F0").opacity(0.15 + pulse * 0.04))
                        )
                    }
                }

                var tableGlow = Path()
                tableGlow.addEllipse(in: CGRect(
                    x: -size.width * 0.16,
                    y: size.height * 0.58,
                    width: size.width * 1.32,
                    height: size.height * 0.50
                ))
                context.fill(
                    tableGlow,
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(hex: "#A8F0DD").opacity(0.23),
                            Color(hex: "#E9F7F3").opacity(0.12),
                            Color.clear
                        ]),
                        center: CGPoint(x: size.width * 0.5, y: size.height * 0.78),
                        startRadius: 20,
                        endRadius: size.width * 0.72
                    )
                )

                let clusterOrigin = CGPoint(x: size.width * 0.70, y: size.height * 0.28)
                for column in 0..<10 {
                    for row in 0..<9 {
                        let distance = hypot(Double(column - 7), Double(row - 4))
                        let wave = 0.5 + 0.5 * sin(time * 1.05 + Double(column) * 0.7 + Double(row) * 0.35)
                        let opacity = max(0.0, 0.56 - distance * 0.08) * (0.68 + wave * 0.32)
                        let radius = CGFloat(2 + wave * 1.3)
                        let point = CGPoint(
                            x: clusterOrigin.x + CGFloat(column) * 14,
                            y: clusterOrigin.y + CGFloat(row) * 14
                        )
                        context.fill(
                            Path(ellipseIn: CGRect(x: point.x, y: point.y, width: radius, height: radius)),
                            with: .color(Color(hex: "#645CFF").opacity(opacity))
                        )
                    }
                }

                for index in 0..<4 {
                    var path = Path()
                    let y = size.height * (0.18 + CGFloat(index) * 0.17)
                    let offset = CGFloat(sin(time * 0.28 + Double(index))) * 12
                    path.move(to: CGPoint(x: -40, y: y + offset))
                    path.addCurve(
                        to: CGPoint(x: size.width + 40, y: y + 16 - offset),
                        control1: CGPoint(x: size.width * 0.25, y: y - 25),
                        control2: CGPoint(x: size.width * 0.72, y: y + 36)
                    )
                    context.stroke(path, with: .color(Color(hex: "#DDE7F5").opacity(0.46)), lineWidth: 1)
                }
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Color(hex: "#F8FAFD").opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
            }
        }
    }
}

private struct BattleTableView: View {
    let agents: [BattleAgent]
    let tableSize: Int
    let selectedSeat: Int
    let onSelectSeat: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                FormalPokerTableSurface(size: size)
                    .position(x: size.width / 2, y: size.height / 2 + 10)

                CenterPotView()
                    .position(x: size.width / 2, y: size.height / 2 + 10)

                ForEach(Array(agents.enumerated()), id: \.element.id) { index, agent in
                    let point = seatPoint(index: index, total: agents.count, size: size)
                    BattleSeatButton(
                        agent: agent,
                        position: seatPosition(for: tableSize, index: index),
                        index: index,
                        isSelected: selectedSeat == index,
                        onSelect: { onSelectSeat(index) }
                    )
                    .position(point)
                    .zIndex(selectedSeat == index ? 2 : 1)
                }
            }
        }
        .frame(height: 310)
        .padding(.top, 4)
    }

    private func seatPoint(index: Int, total: Int, size: CGSize) -> CGPoint {
        let angle = -Double.pi / 2 + (Double(index) / Double(max(total, 1))) * Double.pi * 2
        let radiusX = size.width * 0.39
        let radiusY = size.height * 0.33
        let center = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * radiusX,
            y: center.y + CGFloat(sin(angle)) * radiusY
        )
    }
}

private struct CenterPotView: View {
    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: -10) {
                PlayingCardFace(rank: "A", suit: "♠", tint: Color(hex: "#071226"))
                    .rotationEffect(.degrees(-7))
                PlayingCardFace(rank: "K", suit: "♥", tint: Color(hex: "#EF4444"))
                    .rotationEffect(.degrees(6))
            }

            HStack(spacing: -8) {
                MiniChip(tint: Color(hex: "#8B5CF6"))
                MiniChip(tint: Color(hex: "#13C8A6"))
                MiniChip(tint: Color(hex: "#F59E0B"))
            }
        }
        .offset(y: 2)
    }
}

private struct BattleSeatButton: View {
    let agent: BattleAgent
    let position: String
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 5) {
                ZStack {
                    AgentAvatarView(
                        agent: agent,
                        size: isSelected ? 58 : 50,
                        isSelected: isSelected,
                        isActive: false
                    )
                }

                HStack(spacing: 4) {
                    Text(position)
                        .font(.caption2.weight(.black))
                    if isSelected {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 8, weight: .black))
                    }
                }
                .foregroundStyle(isSelected ? Color(hex: "#071226") : Color(hex: "#697386"))
            }
            .frame(width: 76, height: 84)
        }
        .buttonStyle(BattlePressButtonStyle())
        .accessibilityLabel("观战 \(position) \(agent.name)")
    }
}

private struct SpectatorPanel: View {
    let agent: BattleAgent
    let position: String
    let mode: String
    let isStarting: Bool
    let errorMessage: String?
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                AgentAvatarView(agent: agent, size: 52, isSelected: true, isActive: false)

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(position) · \(agent.name)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color(hex: "#071226"))

                    HStack(spacing: 8) {
                        ModeGlyph(mode: mode)
                        AgentStrategyGlyphRow(agent: agent, compact: true)
                    }
                }

                Spacer(minLength: 0)

                Button(action: onStart) {
                    ZStack {
                        if isStarting {
                            ProgressView()
                                .tint(.white)
                                .controlSize(.small)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 46, height: 46)
                    .background(Color(hex: "#071226").opacity(isStarting ? 0.76 : 1), in: Circle())
                }
                .buttonStyle(BattlePressButtonStyle())
                .disabled(isStarting)
                .accessibilityLabel(isStarting ? "正在创建对战" : (mode == "play" ? "入座牌局" : "开始观战"))
            }

            if let errorMessage {
                HStack(spacing: 7) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(PokerTheme.amber)

                    Text(errorMessage)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(PokerTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 64)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 2)
    }
}

private struct ModeGlyph: View {
    let mode: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: mode == "play" ? "person.fill.badge.plus" : "eye.fill")
                .font(.system(size: 9, weight: .black))
            Text(mode == "play" ? "入座" : "观战")
                .font(.system(size: 10, weight: .black, design: .rounded))
        }
        .foregroundStyle(PokerTheme.ink)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.white.opacity(0.56), in: Capsule())
    }
}

private struct AgentStrategyGlyphRow: View {
    let agent: BattleAgent
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 5 : 7) {
            StrategyGlyph(icon: "function", value: "\(agent.gtoScore)", tint: PokerTheme.violet, compact: compact)
            StrategyGlyph(icon: "scope", value: "\(agent.postflopScore)", tint: PokerTheme.felt, compact: compact)
            StrategyGlyph(icon: "bolt.fill", value: "\(agent.exploitScore)", tint: PokerTheme.amber, compact: compact)
        }
        .accessibilityLabel(
            "\(agent.name) \(agent.masteryLabel)，GTO \(agent.gtoScore)，翻后 \(agent.postflopScore)，剥削 \(agent.exploitScore)"
        )
    }
}

private struct StrategyGlyph: View {
    let icon: String
    let value: String
    let tint: Color
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 3 : 4) {
            Image(systemName: icon)
                .font(.system(size: compact ? 8 : 9, weight: .black))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: compact ? 9 : 10, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, compact ? 5 : 6)
        .padding(.vertical, compact ? 3 : 4)
        .background(tint.opacity(compact ? 0.08 : 0.10), in: Capsule())
    }
}

private struct LiveBattleView: View {
    let agents: [BattleAgent]
    let tableSize: Int
    @State private var selectedSeat: Int
    @State private var activeSeat: Int
    @State private var snapshot: BattleSessionSnapshot?
    @State private var handHistory: BattleHandHistorySnapshot?
    @State private var latestCompletedHistory: BattleHandHistorySnapshot?
    @State private var completedHands: [BattleHandSummarySnapshot] = []
    @State private var isAdvancing = false
    @State private var isAutoPlaying = true
    @State private var isLoadingHistory = false
    @State private var battleErrorMessage: String?
    @State private var replayCursor = 0

    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    init(
        agents: [BattleAgent],
        tableSize: Int,
        selectedSeat: Int,
        initialSnapshot: BattleSessionSnapshot? = nil
    ) {
        self.agents = agents
        self.tableSize = tableSize
        _selectedSeat = State(initialValue: selectedSeat)
        _activeSeat = State(initialValue: initialSnapshot?.activeSeat ?? (agents.isEmpty ? 0 : (selectedSeat + 1) % agents.count))
        _snapshot = State(initialValue: initialSnapshot)
        _replayCursor = State(initialValue: max((initialSnapshot?.replayEvents.count ?? 1) - 1, 0))
    }

    private var observerAgent: BattleAgent {
        if let seat = snapshot?.seats.first(where: { $0.index == selectedSeat }) {
            return BattleAgent(seat: seat)
        }
        return agents.indices.contains(selectedSeat) ? agents[selectedSeat] : agents[0]
    }

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height

            ZStack {
                BattleBackdrop()
                    .ignoresSafeArea()

                if isLandscape {
                    landscapeContent(size: proxy.size, safeArea: proxy.safeAreaInsets)
                } else {
                    portraitContent
                }
            }
        }
        .preferredColorScheme(.light)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            AppOrientationController.lock(.landscapeRight)
        }
        .onChange(of: selectedSeat) { _, newValue in
            switchObservedSeat(to: newValue)
        }
        .task(id: snapshot?.id) {
            await autoplayBattle()
        }
        .onDisappear {
            AppOrientationController.lock(.portrait)
        }
    }

    private var liveTasks: [BattleTask] {
        guard let snapshot else {
            return BattleTask.liveMock(observer: observerAgent)
        }
        return snapshot.tasks.map(BattleTask.init)
    }

    private var replayEvents: [BattleReplayEventSnapshot] {
        snapshot?.replayEvents ?? []
    }

    private var focusedReplayEvent: BattleReplayEventSnapshot? {
        guard !replayEvents.isEmpty else { return nil }
        return replayEvents[min(max(replayCursor, 0), replayEvents.count - 1)]
    }

    private var canStepReplayBackward: Bool {
        replayCursor > 0
    }

    private var canStepReplayForward: Bool {
        replayCursor + 1 < replayEvents.count
    }

    private var isSessionComplete: Bool {
        snapshot?.isSessionComplete ?? false
    }

    private var activeSeatSnapshot: BattleSeatSnapshot? {
        guard let activeSeat = snapshot?.activeSeat else { return nil }
        return snapshot?.seats.first(where: { $0.index == activeSeat })
    }

    private var isWaitingForPlayerAction: Bool {
        guard let snapshot,
              snapshot.mode == "play",
              let activeSeatSnapshot,
              activeSeatSnapshot.isHuman,
              !snapshot.isComplete,
              !snapshot.isSessionComplete else {
            return false
        }
        return true
    }

    private func refreshBattle(observerSeat: Int) async {
        guard let snapshot else { return }
        let next = await session.battleSnapshot(sessionId: snapshot.id, observerSeat: observerSeat)
        guard observerSeat == selectedSeat else { return }
        if let next {
            applySnapshot(next, expectedObserverSeat: observerSeat, preserveReplayCursor: true)
        } else {
            presentBattleError(defaultMessage: "同步失败")
        }
    }

    private func switchObservedSeat(to seat: Int) {
        guard snapshot?.seats.contains(where: { $0.index == seat }) ?? agents.indices.contains(seat) else { return }
        battleErrorMessage = nil
        Task {
            await refreshBattle(observerSeat: seat)
        }
    }

    private func autoplayBattle() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(1350))
            guard let snapshot, !isAdvancing, isAutoPlaying else { continue }
            if snapshot.isSessionComplete {
                isAutoPlaying = false
                continue
            }
            if isWaitingForPlayerAction {
                isAutoPlaying = false
                continue
            }

            isAdvancing = true
            defer { isAdvancing = false }
            if snapshot.isComplete {
                await requestNextHand(from: snapshot)
            } else {
                await requestAdvance(from: snapshot)
            }
        }
    }

    private func stepBattle() async {
        guard let snapshot, !isAdvancing else { return }
        guard !snapshot.isSessionComplete else { return }
        guard !isWaitingForPlayerAction else {
            isAutoPlaying = false
            return
        }
        isAutoPlaying = false
        isAdvancing = true
        defer { isAdvancing = false }
        if snapshot.isComplete {
            await requestNextHand(from: snapshot)
        } else {
            await requestAdvance(from: snapshot)
        }
    }

    private func goToNextHand() async {
        guard let snapshot, !isAdvancing, snapshot.isComplete, !snapshot.isSessionComplete else { return }
        isAutoPlaying = false
        isAdvancing = true
        defer { isAdvancing = false }
        await requestNextHand(from: snapshot)
    }

    private func requestAdvance(from snapshot: BattleSessionSnapshot) async {
        let observerSeat = selectedSeat
        if let next = await session.advanceBattle(
            sessionId: snapshot.id,
            observerSeat: observerSeat,
            steps: 1
        ) {
            guard observerSeat == selectedSeat else { return }
            applySnapshot(next, expectedObserverSeat: observerSeat)
        } else {
            guard observerSeat == selectedSeat else { return }
            presentBattleError(defaultMessage: "推进失败")
        }
    }

    private func requestNextHand(from snapshot: BattleSessionSnapshot) async {
        let observerSeat = selectedSeat
        if let next = await session.nextBattleHand(sessionId: snapshot.id, observerSeat: observerSeat) {
            guard observerSeat == selectedSeat else { return }
            applySnapshot(next, expectedObserverSeat: observerSeat)
        } else {
            guard observerSeat == selectedSeat else { return }
            presentBattleError(defaultMessage: "下一手失败")
        }
    }

    private func submitPlayerAction(_ action: String, targetTotalBb: Double? = nil) async {
        guard let snapshot, !isAdvancing, isWaitingForPlayerAction else { return }
        let observerSeat = selectedSeat
        isAdvancing = true
        defer { isAdvancing = false }
        if let next = await session.playerBattleAction(
            sessionId: snapshot.id,
            observerSeat: observerSeat,
            action: action,
            targetTotalBb: targetTotalBb
        ) {
            guard observerSeat == selectedSeat else { return }
            isAutoPlaying = !next.isSessionComplete
            applySnapshot(next, expectedObserverSeat: observerSeat)
        } else {
            guard observerSeat == selectedSeat else { return }
            presentBattleError(defaultMessage: "操作失败")
        }
    }

    private func applySnapshot(
        _ next: BattleSessionSnapshot,
        expectedObserverSeat: Int? = nil,
        preserveReplayCursor: Bool = false
    ) {
        if let expectedObserverSeat, expectedObserverSeat != selectedSeat {
            return
        }

        let previousCursor = replayCursor
        let sameHand = snapshot?.id == next.id && snapshot?.handNumber == next.handNumber
        self.snapshot = next
        battleErrorMessage = nil
        if !next.seats.contains(where: { $0.index == selectedSeat }) {
            selectedSeat = next.observerSeat
        }
        activeSeat = next.activeSeat ?? -1
        if preserveReplayCursor, sameHand, !next.replayEvents.isEmpty {
            replayCursor = min(previousCursor, next.replayEvents.count - 1)
        } else {
            replayCursor = max(next.replayEvents.count - 1, 0)
        }
        if next.isComplete {
            if next.isSessionComplete {
                isAutoPlaying = false
            }
            let observerSeat = selectedSeat
            Task {
                await loadBattleHistory(sessionId: next.id, observerSeat: observerSeat)
            }
        } else {
            handHistory = nil
        }
    }

    private func presentBattleError(defaultMessage: String) {
        battleErrorMessage = session.errorMessage ?? defaultMessage
        isAutoPlaying = false
    }

    private func retryBattleRefresh() async {
        guard let snapshot, !isAdvancing else { return }
        let observerSeat = selectedSeat
        battleErrorMessage = nil
        isAdvancing = true
        defer { isAdvancing = false }
        let next = await session.battleSnapshot(sessionId: snapshot.id, observerSeat: observerSeat)
        guard observerSeat == selectedSeat else { return }
        if let next {
            applySnapshot(next, expectedObserverSeat: observerSeat, preserveReplayCursor: true)
        } else {
            presentBattleError(defaultMessage: "恢复失败")
        }
    }

    private var reviewHistoryForDisplay: BattleHandHistorySnapshot? {
        handHistory ?? latestCompletedHistory
    }

    private func loadBattleHistory(sessionId: String, observerSeat: Int) async {
        guard !isLoadingHistory else { return }
        guard handHistory?.sessionId != sessionId
            || handHistory?.handNumber != snapshot?.handNumber
            || handHistory?.observerSeat != observerSeat else { return }

        isLoadingHistory = true
        defer { isLoadingHistory = false }
        let nextHistory = await session.battleHistory(sessionId: sessionId, observerSeat: observerSeat)
        guard observerSeat == selectedSeat else { return }
        if snapshot?.id == sessionId,
           snapshot?.handNumber == nextHistory?.handNumber,
           snapshot?.isComplete == true {
            handHistory = nextHistory
            latestCompletedHistory = nextHistory
            completedHands = await session.battleHandSummaries(sessionId: sessionId)
        }
    }

    private func toggleAutoplay() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            isAutoPlaying.toggle()
        }
    }

    private func stepReplay(by delta: Int) {
        guard !replayEvents.isEmpty else { return }
        withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
            isAutoPlaying = false
            replayCursor = min(max(replayCursor + delta, 0), replayEvents.count - 1)
        }
    }

    private var isHandComplete: Bool {
        snapshot?.isComplete ?? false
    }

    private var portraitContent: some View {
        GeometryReader { proxy in
            let tableHeight = min(430, max(310, proxy.size.height * 0.46))
            VStack(alignment: .leading, spacing: 18) {
                liveHeader

                LiveBattleTableView(
                    agents: agents,
                    tableSize: tableSize,
                    selectedSeat: $selectedSeat,
                    activeSeat: snapshot?.activeSeat ?? activeSeat,
                    focusedReplayEvent: focusedReplayEvent,
                    replayEvents: replayEvents,
                    replayCursor: replayCursor,
                    tableHeight: tableHeight,
                    snapshot: snapshot
                )

                liveMetrics

                if let battleErrorMessage {
                    BattleConnectionStatusStrip(
                        message: battleErrorMessage,
                        compact: false,
                        isBusy: isAdvancing,
                        onRetry: {
                            Task { await retryBattleRefresh() }
                        }
                    )
                }

                playbackControls(compact: false)

                PlayerActionDockSlot(
                    isVisible: isWaitingForPlayerAction,
                    callAmount: playerCallAmount,
                    raiseAmount: playerRaiseAmount,
                    isBusy: isAdvancing,
                    onAction: { action, target in
                        Task { await submitPlayerAction(action, targetTotalBb: target) }
                    }
                )

                BattleReplayStatusStrip(
                    event: focusedReplayEvent,
                    total: replayEvents.count,
                    compact: true,
                    canPrevious: canStepReplayBackward,
                    canNext: canStepReplayForward,
                    onPrevious: { stepReplay(by: -1) },
                    onNext: { stepReplay(by: 1) }
                )

                HStack(alignment: .top, spacing: 12) {
                    BattleTableEventTicker(events: snapshot?.tableEvents ?? [], compact: true)

                    if let reviewHistoryForDisplay {
                        BattleReviewSummaryStrip(
                            history: reviewHistoryForDisplay,
                            completedCount: completedHands.count,
                            compact: true
                        )
                    }

                    BattleTaskRail(tasks: liveTasks)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, PokerLayout.floatingTabBarClearance)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
        }
    }

    private func landscapeContent(size: CGSize, safeArea: EdgeInsets) -> some View {
        let railWidth = min(84, max(72, size.width * 0.10))
        let verticalPadding = max(safeArea.top, 14) + max(safeArea.bottom, 14) + 18
        let tableHeight = max(270, size.height - verticalPadding)
        let leadingInset = max(safeArea.leading, 18) + 8
        let trailingInset = max(safeArea.trailing, 18) + 8
        let topInset = max(safeArea.top, 14) + 4
        let tableLeading = leadingInset + railWidth + 18
        let tableWidth = max(320, size.width - tableLeading - trailingInset)

        return ZStack(alignment: .topLeading) {
            LiveBattleTableView(
                agents: agents,
                tableSize: tableSize,
                selectedSeat: $selectedSeat,
                activeSeat: snapshot?.activeSeat ?? activeSeat,
                focusedReplayEvent: focusedReplayEvent,
                replayEvents: replayEvents,
                replayCursor: replayCursor,
                tableHeight: tableHeight,
                snapshot: snapshot
            )
            .frame(width: tableWidth, height: tableHeight, alignment: .topLeading)
            .offset(x: tableLeading, y: topInset)

            LandscapeObserverPill(
                agent: observerAgent,
                position: observerPositionLabel,
                isAutoPlaying: isAutoPlaying
            )
            .frame(width: min(260, tableWidth * 0.42))
            .position(x: tableLeading + tableWidth * 0.50, y: topInset + 28)
            .zIndex(18)

            landscapeRail
                .frame(width: railWidth, height: tableHeight, alignment: .top)
                .offset(x: leadingInset, y: topInset)

            if isWaitingForPlayerAction {
                PlayerActionDock(
                    callAmount: playerCallAmount,
                    raiseAmount: playerRaiseAmount,
                    isBusy: isAdvancing,
                    onAction: { action, target in
                        Task { await submitPlayerAction(action, targetTotalBb: target) }
                    }
                )
                .frame(width: min(360, tableWidth * 0.62))
                .position(
                    x: tableLeading + tableWidth * 0.52,
                    y: size.height - max(safeArea.bottom, 10) - 34
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(20)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
    }

    private var landscapeRail: some View {
        VStack(alignment: .center, spacing: 16) {
            landscapeHeader
            landscapeMetrics
            playbackControls(compact: true)
            if let battleErrorMessage {
                BattleConnectionStatusStrip(
                    message: battleErrorMessage,
                    compact: true,
                    isBusy: isAdvancing,
                    onRetry: {
                        Task { await retryBattleRefresh() }
                    }
                )
            }
            BattleReplayStatusStrip(
                event: focusedReplayEvent,
                total: replayEvents.count,
                compact: true,
                canPrevious: canStepReplayBackward,
                canNext: canStepReplayForward,
                onPrevious: { stepReplay(by: -1) },
                onNext: { stepReplay(by: 1) }
            )
            BattleTaskRail(tasks: liveTasks)
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var liveHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.black))
                    .foregroundStyle(PokerTheme.ink)
            }
            .buttonStyle(BattlePressButtonStyle())

            Text("观战 \(observerPositionLabel) · \(observerAgent.name)")
                .font(.subheadline.weight(.black))
                .foregroundStyle(PokerTheme.muted)
                .lineLimit(1)

            Spacer()
        }
        .padding(.top, 4)
    }

    private var landscapeHeader: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.headline.weight(.black))
                .foregroundStyle(PokerTheme.ink)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.52), in: Circle())
        }
        .buttonStyle(BattlePressButtonStyle())
        .accessibilityLabel("返回")
    }

    private func playbackControls(compact: Bool) -> some View {
        BattlePlaybackControls(
            isAutoPlaying: isAutoPlaying,
            isBusy: isAdvancing,
            isHandComplete: isHandComplete,
            isSessionComplete: isSessionComplete,
            compact: compact,
            onToggleAutoplay: toggleAutoplay,
            onStep: {
                Task { await stepBattle() }
            },
            onNextHand: {
                Task { await goToNextHand() }
            }
        )
    }

    private var landscapeMetrics: some View {
        VStack(spacing: 12) {
            LandscapeMetricBadge(icon: "circle.grid.3x3.fill", value: potMetricValue, tint: PokerTheme.amber)
            LandscapeMetricBadge(icon: "suit.spade.fill", value: streetMetricValue, tint: PokerTheme.ink)
            LandscapeMetricBadge(icon: "timer", value: "08s", tint: PokerTheme.felt)
        }
    }

    private var liveMetrics: some View {
        HStack(spacing: 24) {
            LiveMetric(icon: "circle.grid.3x3.fill", title: "Pot", value: "\(potMetricValue)BB", tint: PokerTheme.amber)
            LiveMetric(icon: "suit.spade.fill", title: "Street", value: streetMetricValue, tint: PokerTheme.ink)
            LiveMetric(icon: "timer", title: "Action", value: "08s", tint: PokerTheme.felt)
            Spacer(minLength: 0)
        }
    }

    private var potMetricValue: String {
        snapshot?.potBb.cleanBb ?? "18.5"
    }

    private var streetMetricValue: String {
        snapshot?.stageLabel ?? "Turn"
    }

    private var observerPositionLabel: String {
        if let position = snapshot?.seats.first(where: { $0.index == selectedSeat })?.position {
            return position
        }
        return seatPosition(for: snapshot?.tableSize ?? tableSize, index: selectedSeat)
    }

    private var playerCallAmount: Double {
        guard let snapshot, let activeSeatSnapshot else { return 0 }
        return max(snapshot.currentBetBb - activeSeatSnapshot.streetBetBb, 0)
    }

    private var playerRaiseAmount: Double {
        guard let snapshot, let activeSeatSnapshot else { return 0 }
        let minimum = snapshot.currentBetBb > 0
            ? snapshot.currentBetBb + snapshot.minRaiseBb
            : max(1, snapshot.minRaiseBb)
        return min(minimum, activeSeatSnapshot.stackBb + activeSeatSnapshot.streetBetBb)
    }
}

private struct LandscapeMetricBadge: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(width: 54, height: 54)
        .background(.white.opacity(0.56), in: Circle())
        .shadow(color: PokerTheme.ink.opacity(0.04), radius: 12, y: 6)
    }
}

private struct LandscapeObserverPill: View {
    let agent: BattleAgent
    let position: String
    let isAutoPlaying: Bool

    var body: some View {
        HStack(spacing: 8) {
            AgentAvatarView(agent: agent, size: 30, isSelected: true, isActive: false)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(position) · \(agent.name)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(PokerTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                AgentStrategyGlyphRow(agent: agent, compact: true)
            }

            Spacer(minLength: 0)

            Image(systemName: isAutoPlaying ? "play.fill" : "pause.fill")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(isAutoPlaying ? PokerTheme.felt : PokerTheme.muted, in: Circle())
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.white.opacity(0.66), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.52), lineWidth: 1)
        }
        .shadow(color: agent.color.opacity(0.10), radius: 16, y: 8)
        .accessibilityLabel("正在观战 \(position) \(agent.name)")
    }
}

private struct LiveMetric: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: icon)
                .font(.title3.weight(.black))
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.monospacedDigit().weight(.black))
                .foregroundStyle(PokerTheme.ink)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PokerTheme.muted)
        }
    }
}

private struct PlayerActionDock: View {
    let callAmount: Double
    let raiseAmount: Double
    let isBusy: Bool
    let onAction: (String, Double?) -> Void

    private var canCheck: Bool {
        callAmount <= 0.001
    }

    var body: some View {
        HStack(spacing: 10) {
            PlayerActionButton(
                icon: "xmark",
                title: "弃牌",
                tint: PokerTheme.coral,
                isBusy: isBusy,
                action: { onAction("fold", nil) }
            )

            PlayerActionButton(
                icon: canCheck ? "checkmark" : "arrow.turn.down.right",
                title: canCheck ? "过牌" : "跟注",
                amount: canCheck ? nil : "\(callAmount.cleanBb)BB",
                tint: PokerTheme.felt,
                isBusy: isBusy,
                action: { onAction(canCheck ? "check" : "call", nil) }
            )

            PlayerActionButton(
                icon: "arrow.up.forward",
                title: canCheck ? "下注" : "加注",
                amount: "\(raiseAmount.cleanBb)BB",
                tint: PokerTheme.violet,
                isBusy: isBusy,
                action: { onAction(canCheck ? "bet" : "raise", raiseAmount) }
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.70), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.62), lineWidth: 1)
        }
        .shadow(color: PokerTheme.ink.opacity(0.08), radius: 18, y: 9)
        .accessibilityElement(children: .contain)
    }
}

private struct PlayerActionDockSlot: View {
    let isVisible: Bool
    let callAmount: Double
    let raiseAmount: Double
    let isBusy: Bool
    let onAction: (String, Double?) -> Void

    var body: some View {
        PlayerActionDock(
            callAmount: callAmount,
            raiseAmount: raiseAmount,
            isBusy: isBusy,
            onAction: onAction
        )
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.98)
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 56, alignment: .center)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: isVisible)
    }
}

private struct PlayerActionButton: View {
    let icon: String
    let title: String
    var amount: String?
    let tint: Color
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(tint, in: Circle())

                VStack(alignment: .leading, spacing: -1) {
                    Text(title)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                    if let amount {
                        Text(amount)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
            }
            .frame(minWidth: 78, alignment: .leading)
        }
        .buttonStyle(BattlePressButtonStyle())
        .disabled(isBusy)
        .opacity(isBusy ? 0.48 : 1)
        .accessibilityLabel(amount.map { "\(title) \($0)" } ?? title)
    }
}

private struct BattlePlaybackControls: View {
    let isAutoPlaying: Bool
    let isBusy: Bool
    let isHandComplete: Bool
    let isSessionComplete: Bool
    let compact: Bool
    let onToggleAutoplay: () -> Void
    let onStep: () -> Void
    let onNextHand: () -> Void

    var body: some View {
        Group {
            if compact {
                VStack(spacing: 10) {
                    controls(size: 42)
                }
            } else {
                HStack(spacing: 12) {
                    controls(size: 46)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    @ViewBuilder
    private func controls(size: CGFloat) -> some View {
        PlaybackIconButton(
            icon: isAutoPlaying ? "pause.fill" : "play.fill",
            tint: PokerTheme.ink,
            size: size,
            isActive: isAutoPlaying,
            isDisabled: isSessionComplete,
            action: onToggleAutoplay,
            accessibilityLabel: isAutoPlaying ? "暂停自动对战" : "继续自动对战"
        )

        PlaybackIconButton(
            icon: isHandComplete ? "forward.end.fill" : "forward.frame.fill",
            tint: PokerTheme.violet,
            size: size,
            isActive: false,
            isDisabled: isBusy || isSessionComplete,
            action: onStep,
            accessibilityLabel: isHandComplete ? "进入下一手" : "推进一个动作"
        )

        PlaybackIconButton(
            icon: "arrow.triangle.2.circlepath",
            tint: PokerTheme.felt,
            size: size,
            isActive: false,
            isDisabled: isBusy || !isHandComplete || isSessionComplete,
            action: onNextHand,
            accessibilityLabel: "下一手"
        )
    }
}

private struct PlaybackIconButton: View {
    let icon: String
    let tint: Color
    let size: CGFloat
    let isActive: Bool
    let isDisabled: Bool
    let action: () -> Void
    let accessibilityLabel: String

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.36, weight: .black))
                .foregroundStyle(isActive ? .white : tint)
                .frame(width: size, height: size)
                .background(isActive ? tint : .white.opacity(0.58), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(isActive ? 0.36 : 0.54), lineWidth: 1)
                }
                .shadow(color: tint.opacity(isActive ? 0.20 : 0.08), radius: 12, y: 6)
        }
        .buttonStyle(BattlePressButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.38 : 1)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct BattleConnectionStatusStrip: View {
    let message: String
    let compact: Bool
    let isBusy: Bool
    let onRetry: () -> Void

    var body: some View {
        if compact {
            VStack(spacing: 8) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(PokerTheme.coral, in: Circle())
                    .shadow(color: PokerTheme.coral.opacity(0.16), radius: 10, y: 5)

                retryButton(size: 32)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("对战同步异常，\(message)")
        } else {
            HStack(spacing: 9) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(PokerTheme.coral, in: Circle())

                Text(message)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(PokerTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                Spacer(minLength: 0)

                retryButton(size: 30)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.56), in: Capsule())
            .shadow(color: PokerTheme.ink.opacity(0.05), radius: 12, y: 6)
            .accessibilityLabel("对战同步异常，\(message)")
        }
    }

    private func retryButton(size: CGFloat) -> some View {
        Button(action: onRetry) {
            ZStack {
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .tint(PokerTheme.ink)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: size * 0.38, weight: .black))
                        .foregroundStyle(PokerTheme.ink)
                }
            }
            .frame(width: size, height: size)
            .background(.white.opacity(0.62), in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.54), lineWidth: 1)
            }
        }
        .buttonStyle(BattlePressButtonStyle())
        .disabled(isBusy)
        .accessibilityLabel("重试同步")
    }
}

private struct BattleTableEventTicker: View {
    let events: [BattleTableEventSnapshot]
    let compact: Bool

    private var latestEvents: [BattleTableEventSnapshot] {
        Array(events.suffix(compact ? 4 : 5))
    }

    var body: some View {
        if !latestEvents.isEmpty {
            if compact {
                VStack(spacing: 8) {
                    ForEach(latestEvents) { event in
                        BattleTableEventChip(event: event, compact: true)
                    }
                }
                .padding(.vertical, 2)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(latestEvents) { event in
                            BattleTableEventChip(event: event, compact: false)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(height: 38)
            }
        }
    }
}

private struct BattleTableEventChip: View {
    let event: BattleTableEventSnapshot
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 0 : 5) {
            if compact, !event.cards.isEmpty {
                BattleMiniCardFan(codes: event.cards, compact: true)
                    .frame(width: 32, height: 28)
            } else {
                Image(systemName: event.event.systemImage)
                    .font(.system(size: compact ? 12 : 9, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: compact ? 28 : 22, height: compact ? 28 : 22)
                    .background(event.event.tint, in: Circle())
                    .shadow(color: event.event.tint.opacity(0.16), radius: 9, y: 4)
            }

            if !compact {
                Text(event.event.shortLabel)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(PokerTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if !event.cards.isEmpty {
                    BattleMiniCardFan(codes: event.cards, compact: true)
                }
            }
        }
        .padding(.trailing, compact ? 0 : 6)
        .accessibilityLabel(event.label)
    }
}

private struct BattleReplayStatusStrip: View {
    let event: BattleReplayEventSnapshot?
    let total: Int
    let compact: Bool
    let canPrevious: Bool
    let canNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    private var icon: String {
        guard let event else { return "play.rectangle.fill" }
        if event.kind == .action {
            return event.action?.systemImage ?? "dot.radiowaves.left.and.right"
        }
        return event.tableEvent?.systemImage ?? "play.rectangle.fill"
    }

    private var tint: Color {
        guard let event else { return PokerTheme.violet }
        if event.kind == .action {
            return event.action?.timelineTint ?? PokerTheme.violet
        }
        return event.tableEvent?.tint ?? PokerTheme.violet
    }

    private var label: String {
        guard let event else { return "Replay" }
        if event.kind == .action {
            let amount = event.amountBb > 0 ? " \(event.amountBb.cleanBb)" : ""
            return "\(event.position ?? "") \(event.action?.shortLabel ?? event.label)\(amount)"
        }
        return event.tableEvent?.shortLabel ?? event.label
    }

    var body: some View {
        if compact {
            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    ReplayStepButton(
                        icon: "chevron.left",
                        tint: tint,
                        size: 21,
                        isDisabled: !canPrevious,
                        action: onPrevious,
                        accessibilityLabel: "上一帧回放"
                    )

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(tint, in: Circle())
                        .shadow(color: tint.opacity(0.16), radius: 10, y: 5)

                    ReplayStepButton(
                        icon: "chevron.right",
                        tint: tint,
                        size: 21,
                        isDisabled: !canNext,
                        action: onNext,
                        accessibilityLabel: "下一帧回放"
                    )
                }
                .frame(width: 78)

                Text("\(event?.sequence ?? 0)/\(max(total, 0))")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(PokerTheme.muted)
                    .lineLimit(1)
            }
            .accessibilityLabel(label)
        } else if let event {
            HStack(spacing: 8) {
                ReplayStepButton(
                    icon: "chevron.left",
                    tint: tint,
                    size: 28,
                    isDisabled: !canPrevious,
                    action: onPrevious,
                    accessibilityLabel: "上一帧回放"
                )

                Image(systemName: icon)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(tint, in: Circle())

                Text(label)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(PokerTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                if !event.cards.isEmpty {
                    BattleMiniCardFan(codes: event.cards, compact: true)
                }

                Spacer(minLength: 0)

                Text("\(event.sequence)/\(total)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(PokerTheme.muted)

                ReplayStepButton(
                    icon: "chevron.right",
                    tint: tint,
                    size: 28,
                    isDisabled: !canNext,
                    action: onNext,
                    accessibilityLabel: "下一帧回放"
                )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.50), in: Capsule())
            .shadow(color: PokerTheme.ink.opacity(0.04), radius: 12, y: 6)
            .accessibilityLabel("\(label)，第 \(event.sequence) 步，共 \(total) 步")
        }
    }
}

private struct ReplayStepButton: View {
    let icon: String
    let tint: Color
    let size: CGFloat
    let isDisabled: Bool
    let action: () -> Void
    let accessibilityLabel: String

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .black))
                .foregroundStyle(isDisabled ? PokerTheme.muted.opacity(0.52) : tint)
                .frame(width: size, height: size)
                .background(.white.opacity(isDisabled ? 0.28 : 0.60), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(isDisabled ? 0.24 : 0.54), lineWidth: 1)
                }
        }
        .buttonStyle(BattlePressButtonStyle())
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct BattleReviewSummaryStrip: View {
    let history: BattleHandHistorySnapshot
    let completedCount: Int
    let compact: Bool

    private var primaryInsight: BattleReviewInsightSnapshot? {
        history.reviewInsights.first
    }

    var body: some View {
        if compact {
            VStack(spacing: 8) {
                ForEach(history.reviewInsights.prefix(3)) { insight in
                    Image(systemName: insight.icon)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color(hex: insight.accent), in: Circle())
                        .shadow(color: Color(hex: insight.accent).opacity(0.16), radius: 10, y: 5)
                        .accessibilityLabel(insight.title)
                }
            }
            .padding(.vertical, 2)
        } else if let primaryInsight {
            HStack(spacing: 10) {
                Image(systemName: primaryInsight.icon)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color(hex: primaryInsight.accent), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(primaryInsight.title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(PokerTheme.ink)
                        .lineLimit(1)

                    Text(primaryInsight.detail)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(PokerTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }

                Spacer(minLength: 0)

                HStack(spacing: 5) {
                    Text("#\(history.handNumber)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(PokerTheme.ink)
                    Image(systemName: completedCount > 1 ? "rectangle.stack.fill" : "list.bullet")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(PokerTheme.muted)
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(PokerTheme.violet)
                    Text("\(history.replayEvents.count)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(PokerTheme.muted)
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(.white.opacity(0.54), in: Capsule())
            .shadow(color: PokerTheme.ink.opacity(0.04), radius: 12, y: 6)
            .accessibilityLabel(primaryInsight.detail)
        }
    }
}

private struct BattleActionTimelineStrip: View {
    let groups: [BattleActionStreetSnapshot]
    let compact: Bool

    private var latestActions: [BattleActionSnapshot] {
        Array(groups.flatMap(\.actions).suffix(7))
    }

    var body: some View {
        if !groups.isEmpty {
            if compact {
                VStack(spacing: 8) {
                    ForEach(latestActions) { action in
                        TimelineActionChip(action: action, compact: true)
                    }
                }
                .padding(.vertical, 2)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(groups) { group in
                            HStack(spacing: 6) {
                                Text(group.street.timelineTitle)
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(PokerTheme.muted)
                                    .lineLimit(1)

                                ForEach(group.actions.suffix(5)) { action in
                                    TimelineActionChip(action: action, compact: false)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .background(.white.opacity(0.48), in: Capsule())
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(height: 44)
            }
        }
    }
}

private struct TimelineActionChip: View {
    let action: BattleActionSnapshot
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 0 : 4) {
            Image(systemName: action.action.systemImage)
                .font(.system(size: compact ? 10 : 8, weight: .black))
                .foregroundStyle(.white)
                .frame(width: compact ? 26 : 18, height: compact ? 26 : 18)
                .background(action.action.timelineTint, in: Circle())

            if !compact {
                Text(action.position)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(PokerTheme.ink)

                if action.amountBb > 0 {
                    Text(action.amountBb.cleanBb)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(PokerTheme.muted)
                }
            }
        }
        .accessibilityLabel("\(action.position) \(action.label)")
    }
}

private struct LiveBattleTableView: View {
    let agents: [BattleAgent]
    let tableSize: Int
    @Binding var selectedSeat: Int
    let activeSeat: Int
    var focusedReplayEvent: BattleReplayEventSnapshot?
    var replayEvents: [BattleReplayEventSnapshot] = []
    var replayCursor = 0
    var tableHeight: CGFloat = 430
    var snapshot: BattleSessionSnapshot?

    private var renderAgents: [BattleAgent] {
        snapshot?.seats.map(BattleAgent.init) ?? agents
    }

    private var renderTableSize: Int {
        snapshot?.tableSize ?? tableSize
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let center = tableCenter(size: size)
            let agents = renderAgents

            ZStack {
                FormalPokerTableSurface(size: size)
                    .position(center)

                CommunityBoardView(cards: communityCards)
                    .position(x: center.x, y: center.y - 14)

                TablePotView(amount: potLabel)
                    .position(x: center.x, y: center.y + 58)

                if let focusedReplayEvent, focusedReplayEvent.kind == .table {
                    TableReplayPulseView(event: focusedReplayEvent)
                        .position(x: center.x, y: center.y - 92)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                        .zIndex(10)
                }

                if size.width <= size.height, let result = resultForDisplay {
                    ShowdownResultStrip(
                        result: result,
                        seats: snapshot?.seats ?? []
                    )
                    .frame(maxWidth: min(size.width * 0.42, 286))
                    .position(resultPoint(size: size))
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .zIndex(12)
                }

                if size.width <= size.height,
                   !isReviewingReplayPast,
                   snapshot?.result == nil,
                   let selectedSeatSnapshot,
                   let action = selectedDecisionAction {
                    AgentDecisionInsightStrip(
                        seat: selectedSeatSnapshot,
                        action: action
                    )
                    .frame(maxWidth: min(size.width * 0.46, 318))
                    .position(decisionPoint(size: size))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(11)
                }

                ForEach(agents) { agent in
                    let seatIndex = agent.id
                    let seatPoint = visualSeatPoint(index: seatIndex, total: agents.count, size: size)

                    if shouldShowAction(for: seatIndex),
                       let action = seatAction(for: seatIndex) {
                        let seatSlot = visualSeatIndex(index: seatIndex, total: agents.count)
                        TableActionBubble(
                            action: action,
                            tint: agent.color,
                            isHighlighted: isFocusedAction(action)
                        )
                        .position(actionBubblePoint(
                            seatSlot: seatSlot,
                            seatPoint: seatPoint,
                            size: size
                        ))
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                        .allowsHitTesting(false)
                        .zIndex(4)
                    }
                }

                ForEach(agents) { agent in
                    let seatIndex = agent.id
                    let isObserver = seatIndex == selectedSeat
                    let seatPoint = visualSeatPoint(index: seatIndex, total: agents.count, size: size)

                    if isObserver, !observedCards(for: seatIndex, fallbackAgent: agent).isEmpty {
                        let cardsPoint = observedCardsPoint(seatPoint: seatPoint, size: size)
                        ObservedHoleCardsView(cards: observedCards(for: seatIndex, fallbackAgent: agent))
                            .position(cardsPoint)
                            .allowsHitTesting(false)
                            .zIndex(9)
                    }
                }

                ForEach(agents) { agent in
                    let seatIndex = agent.id
                    let seat = seatSnapshot(for: seatIndex)
                    let position = displayPosition(for: seatIndex)
                    let isObserver = seatIndex == selectedSeat
                    let seatPoint = visualSeatPoint(index: seatIndex, total: agents.count, size: size)

                    Button {
                        withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
                            selectedSeat = seatIndex
                        }
                    } label: {
                        LiveSeatBadge(
                            agent: agent,
                            position: position,
                            stackBb: seat?.stackBb,
                            status: seat?.status ?? "active",
                            isObserver: isObserver,
                            isActive: seatIndex == activeSeat
                        )
                    }
                    .buttonStyle(BattlePressButtonStyle())
                    .accessibilityLabel("切换到 \(position) \(agent.name) 视角")
                    .position(seatPoint)
                    .zIndex(seatIndex == selectedSeat ? 7 : (seatIndex == activeSeat ? 6 : 5))
                }
            }
        }
        .frame(height: tableHeight)
        .padding(.top, 4)
    }

    private var replayEndIndex: Int? {
        guard !replayEvents.isEmpty else { return nil }
        return min(max(replayCursor, 0), replayEvents.count - 1)
    }

    private var replayedEvents: [BattleReplayEventSnapshot] {
        guard let replayEndIndex else { return [] }
        return Array(replayEvents.prefix(replayEndIndex + 1))
    }

    private var isReviewingReplayPast: Bool {
        guard let replayEndIndex else { return false }
        return replayEndIndex + 1 < replayEvents.count
    }

    private var replayHasResultAtCursor: Bool {
        replayedEvents.contains { event in
            switch event.tableEvent {
            case .showdown?, .uncontested?, .handComplete?:
                return true
            default:
                return false
            }
        }
    }

    private var resultForDisplay: BattleResultSnapshot? {
        guard !replayedEvents.isEmpty else { return snapshot?.result }
        return replayHasResultAtCursor ? snapshot?.result : nil
    }

    private var communityCards: [PokerCardValue] {
        if !replayedEvents.isEmpty {
            return replayedEvents.reduce(into: [PokerCardValue]()) { cards, event in
                switch event.tableEvent {
                case .dealFlop?, .dealTurn?, .dealRiver?:
                    cards.append(contentsOf: event.cards.compactMap(PokerCardValue.init(code:)))
                default:
                    break
                }
            }
        }

        guard let board = snapshot?.board, !board.isEmpty else {
            if snapshot != nil {
                return []
            }
            return [
                PokerCardValue(id: "qd", rank: "Q", suit: "♦", tint: PokerTheme.coral),
                PokerCardValue(id: "9c", rank: "9", suit: "♣", tint: PokerTheme.ink),
                PokerCardValue(id: "2h", rank: "2", suit: "♥", tint: PokerTheme.coral),
                PokerCardValue(id: "js", rank: "J", suit: "♠", tint: PokerTheme.ink)
            ]
        }
        return board.compactMap(PokerCardValue.init(code:))
    }

    private var potLabel: String {
        if let replayPot = replayedEvents.last?.potBb {
            return "\(replayPot.cleanBb)BB"
        }

        guard let pot = snapshot?.potBb else { return "18.5BB" }
        return "\(pot.cleanBb)BB"
    }

    private var selectedSeatSnapshot: BattleSeatSnapshot? {
        snapshot?.seats.first(where: { $0.index == selectedSeat })
    }

    private func seatSnapshot(for index: Int) -> BattleSeatSnapshot? {
        snapshot?.seats.first(where: { $0.index == index })
    }

    private var selectedDecisionAction: BattleActionSnapshot? {
        if let action = selectedSeatSnapshot?.lastAction, action.decision != nil {
            return action
        }

        return snapshot?.recentActions.reversed().first { action in
            action.seatIndex == selectedSeat && action.decision != nil
        }
    }

    private func displayPosition(for index: Int) -> String {
        snapshot?.seats.first(where: { $0.index == index })?.position ?? seatPosition(for: renderTableSize, index: index)
    }

    private func seatAction(for index: Int) -> SeatAction? {
        if !replayedEvents.isEmpty {
            guard let event = replayedEvents.reversed().first(where: { replayEvent in
                replayEvent.kind == .action && replayEvent.seatIndex == index && replayEvent.action != nil
            }) else {
                return nil
            }
            return SeatAction(event)
        }

        guard let action = snapshot?.seats.first(where: { $0.index == index })?.lastAction else {
            return snapshot == nil ? fallbackSeatAction(for: index) : nil
        }
        return SeatAction(action)
    }

    private func shouldShowAction(for index: Int) -> Bool {
        if snapshot?.isComplete == true, !isReviewingReplayPast {
            return false
        }
        if isReviewingReplayPast {
            return true
        }
        return index != activeSeat
    }

    private func isFocusedAction(_ action: SeatAction) -> Bool {
        focusedReplayEvent?.kind == .action && focusedReplayEvent?.actionId == action.id
    }

    private func observedCards(for index: Int, fallbackAgent: BattleAgent) -> [PokerCardValue] {
        guard let cards = snapshot?.seats.first(where: { $0.index == index })?.holeCards else {
            return snapshot == nil ? fallbackObservedCards(for: fallbackAgent) : []
        }
        return cards.compactMap(PokerCardValue.init(code:))
    }

    private func tableCenter(size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height * 0.52)
    }

    private func visualSeatPoint(index: Int, total: Int, size: CGSize) -> CGPoint {
        let relativeIndex = visualSeatIndex(index: index, total: total)
        return ellipseSeatPoint(slot: relativeIndex, total: total, size: size)
    }

    private func ellipseSeatPoint(slot: Int, total: Int, size: CGSize) -> CGPoint {
        let normalizedTotal = Double(max(total, 1))
        let angle = Double.pi / 2 + (Double(slot) / normalizedTotal) * Double.pi * 2
        let radiusX = size.width * 0.39
        let radiusY = size.height * 0.34
        let center = tableCenter(size: size)
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * radiusX,
            y: center.y + CGFloat(sin(angle)) * radiusY
        )
    }

    private func visualSeatIndex(index: Int, total: Int) -> Int {
        (index - selectedSeat + total) % max(total, 1)
    }

    private func observedCardsOffset(seatPoint: CGPoint, size: CGSize) -> CGSize {
        clampedOffset(
            desired: CGSize(width: 98, height: -8),
            seatPoint: seatPoint,
            size: size,
            contentSize: CGSize(width: 92, height: 58)
        )
    }

    private func observedCardsPoint(seatPoint: CGPoint, size: CGSize) -> CGPoint {
        let offset = observedCardsOffset(seatPoint: seatPoint, size: size)
        return CGPoint(x: seatPoint.x + offset.width, y: seatPoint.y + offset.height)
    }

    private func actionBubblePoint(
        seatSlot: Int,
        seatPoint: CGPoint,
        size: CGSize
    ) -> CGPoint {
        let contentSize = CGSize(width: 94, height: 38)
        let center = tableCenter(size: size)
        let radial = radialUnit(from: center, to: seatPoint)
        let tangent = CGVector(dx: -radial.dy, dy: radial.dx)
        let seatClearance: CGFloat = seatSlot == 0 ? 86 : 76
        let horizontalBias: CGFloat

        if abs(radial.dy) > 0.74 {
            horizontalBias = radial.dx >= 0 ? -8 : 8
        } else {
            horizontalBias = 0
        }

        let offset = CGSize(
            width: radial.dx * seatClearance + tangent.dx * horizontalBias,
            height: radial.dy * seatClearance + tangent.dy * horizontalBias
        )

        return clampedPoint(
            CGPoint(x: seatPoint.x + offset.width, y: seatPoint.y + offset.height),
            size: size,
            contentSize: contentSize
        )
    }

    private func resultPoint(size: CGSize) -> CGPoint {
        if size.width > size.height {
            return CGPoint(
                x: min(size.width - 150, max(size.width * 0.70, size.width / 2 + 120)),
                y: max(48, size.height * 0.16)
            )
        }

        return CGPoint(
            x: size.width / 2,
            y: min(size.height - 48, tableCenter(size: size).y + size.height * 0.36)
        )
    }

    private func decisionPoint(size: CGSize) -> CGPoint {
        if size.width > size.height {
            return CGPoint(
                x: min(size.width - 170, max(size.width * 0.68, size.width / 2 + 96)),
                y: max(54, size.height * 0.18)
            )
        }

        return CGPoint(
            x: size.width / 2,
            y: max(46, tableCenter(size: size).y - size.height * 0.38)
        )
    }

    private func radialUnit(from center: CGPoint, to point: CGPoint) -> CGVector {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let length = max(sqrt(dx * dx + dy * dy), 1)
        return CGVector(dx: dx / length, dy: dy / length)
    }

    private func clampedPoint(
        _ point: CGPoint,
        size: CGSize,
        contentSize: CGSize
    ) -> CGPoint {
        let halfWidth = contentSize.width / 2
        let halfHeight = contentSize.height / 2
        return CGPoint(
            x: min(max(point.x, halfWidth + 4), size.width - halfWidth - 4),
            y: min(max(point.y, halfHeight + 4), size.height - halfHeight - 4)
        )
    }

    private func clampedOffset(
        desired: CGSize,
        seatPoint: CGPoint,
        size: CGSize,
        contentSize: CGSize
    ) -> CGSize {
        let halfWidth = contentSize.width / 2
        let halfHeight = contentSize.height / 2
        let targetX = min(max(seatPoint.x + desired.width, halfWidth + 4), size.width - halfWidth - 4)
        let targetY = min(max(seatPoint.y + desired.height, halfHeight + 4), size.height - halfHeight - 4)
        return CGSize(width: targetX - seatPoint.x, height: targetY - seatPoint.y)
    }
}

private struct FormalPokerTableSurface: View {
    let size: CGSize

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let float = CGFloat(sin(time * 0.54)) * 2

            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                PokerTheme.ink.opacity(0.12),
                                PokerTheme.ink.opacity(0.04),
                                PokerTheme.felt.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.width * 0.78, height: size.height * 0.42)
                    .blur(radius: 0.3)

                Capsule()
                    .fill(
                        RadialGradient(
                            colors: [
                                PokerTheme.felt.opacity(0.30),
                                Color(hex: "#BFF4E6").opacity(0.22),
                                Color(hex: "#E9F7F3").opacity(0.10)
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 190
                        )
                    )
                    .frame(width: size.width * 0.70, height: size.height * 0.32)
                    .overlay {
                        Capsule()
                            .stroke(.white.opacity(0.46), lineWidth: 1)
                    }

                Capsule()
                    .stroke(PokerTheme.felt.opacity(0.36), style: StrokeStyle(lineWidth: 1.6, dash: [9, 12]))
                    .frame(width: size.width * 0.56, height: size.height * 0.21)
                    .offset(y: float)

                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .stroke(PokerTheme.ink.opacity(0.035), lineWidth: 1)
                        .frame(
                            width: size.width * (0.42 + CGFloat(index) * 0.10),
                            height: size.height * (0.12 + CGFloat(index) * 0.04)
                        )
                        .offset(y: CGFloat(index - 1) * 4)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct SeatAction {
    let id: String?
    let title: String
    let amount: String
    let icon: String
    let confidence: Double?
    let summary: String?
}

private func fallbackSeatAction(for index: Int) -> SeatAction {
    let actions = [
        SeatAction(id: nil, title: "加注", amount: "6.5BB", icon: "arrow.up.forward", confidence: 0.86, summary: nil),
        SeatAction(id: nil, title: "跟注", amount: "2.5BB", icon: "arrow.turn.down.right", confidence: 0.78, summary: nil),
        SeatAction(id: nil, title: "过牌", amount: "", icon: "checkmark", confidence: 0.74, summary: nil),
        SeatAction(id: nil, title: "下注", amount: "4BB", icon: "circle.fill", confidence: 0.82, summary: nil),
        SeatAction(id: nil, title: "弃牌", amount: "", icon: "xmark", confidence: 0.76, summary: nil),
        SeatAction(id: nil, title: "等待", amount: "", icon: "hourglass", confidence: nil, summary: nil)
    ]

    return actions[index % actions.count]
}

private struct PokerCardValue: Identifiable {
    let id: String
    let rank: String
    let suit: String
    let tint: Color

    var fanRotationDegrees: Double {
        let seed = id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return seed.isMultiple(of: 2) ? -5 : 5
    }

    init(id: String, rank: String, suit: String, tint: Color) {
        self.id = id
        self.rank = rank
        self.suit = suit
        self.tint = tint
    }

    init?(code: String) {
        guard code.count >= 2 else { return nil }
        let rankCode = String(code.dropLast()).uppercased()
        let suitCode = code.suffix(1).lowercased()
        let suit: String
        switch suitCode {
        case "s":
            suit = "♠"
        case "h":
            suit = "♥"
        case "d":
            suit = "♦"
        case "c":
            suit = "♣"
        default:
            return nil
        }
        id = code
        rank = rankCode == "T" ? "10" : rankCode
        self.suit = suit
        tint = (suit == "♥" || suit == "♦") ? PokerTheme.coral : PokerTheme.ink
    }
}

private func fallbackObservedCards(for agent: BattleAgent) -> [PokerCardValue] {
    let hands: [[PokerCardValue]] = [
        [
            PokerCardValue(id: "as", rank: "A", suit: "♠", tint: PokerTheme.ink),
            PokerCardValue(id: "kh", rank: "K", suit: "♥", tint: PokerTheme.coral)
        ],
        [
            PokerCardValue(id: "qc", rank: "Q", suit: "♣", tint: PokerTheme.ink),
            PokerCardValue(id: "qd", rank: "Q", suit: "♦", tint: PokerTheme.coral)
        ],
        [
            PokerCardValue(id: "js", rank: "J", suit: "♠", tint: PokerTheme.ink),
            PokerCardValue(id: "ts", rank: "10", suit: "♠", tint: PokerTheme.ink)
        ],
        [
            PokerCardValue(id: "ah", rank: "A", suit: "♥", tint: PokerTheme.coral),
            PokerCardValue(id: "qh", rank: "Q", suit: "♥", tint: PokerTheme.coral)
        ],
        [
            PokerCardValue(id: "9c", rank: "9", suit: "♣", tint: PokerTheme.ink),
            PokerCardValue(id: "9d", rank: "9", suit: "♦", tint: PokerTheme.coral)
        ],
        [
            PokerCardValue(id: "8s", rank: "8", suit: "♠", tint: PokerTheme.ink),
            PokerCardValue(id: "7s", rank: "7", suit: "♠", tint: PokerTheme.ink)
        ]
    ]
    return hands[agent.id % hands.count]
}

private struct TablePotView: View {
    let amount: String

    var body: some View {
        HStack(spacing: -7) {
            MiniChip(tint: PokerTheme.violet)
            MiniChip(tint: PokerTheme.felt)
            MiniChip(tint: PokerTheme.amber)

            Text(amount)
                .font(.caption.monospacedDigit().weight(.black))
                .foregroundStyle(PokerTheme.ink)
                .padding(.leading, 12)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.62), in: Capsule())
        .shadow(color: PokerTheme.ink.opacity(0.05), radius: 12, y: 6)
    }
}

private struct ShowdownResultStrip: View {
    let result: BattleResultSnapshot
    let seats: [BattleSeatSnapshot]

    private var winnerSeats: [BattleSeatSnapshot] {
        result.winners.compactMap { winner in
            seats.first(where: { $0.index == winner })
        }
    }

    private var winnerDetails: [BattleShowdownHandSnapshot] {
        result.showdownDetails.filter(\.isWinner)
    }

    private var title: String {
        if result.winners.count > 1 {
            return "分池"
        }
        if let detail = winnerDetails.first {
            return "\(detail.agentName) · \(detail.madeHand)"
        }
        guard let first = winnerSeats.first else { return "结算" }
        return result.showdown.isEmpty ? "\(first.agent.name) 拿下" : "\(first.agent.name) 摊牌"
    }

    private var awardedAmount: Double {
        let structuredAmount = winnerDetails.reduce(0) { $0 + $1.wonBb }
        if structuredAmount > 0 {
            return structuredAmount
        }
        let winnerSet = Set(result.winners)
        return result.sidePots.reduce(0) { total, pot in
            pot.winners.contains(where: { winnerSet.contains($0) }) ? total + pot.amountBb : total
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: -8) {
                ForEach(winnerSeats.prefix(3)) { seat in
                    AgentAvatarView(
                        agent: BattleAgent(seat: seat),
                        size: 32,
                        isSelected: true,
                        isActive: false
                    )
                }
            }
            .frame(width: 58, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: result.showdown.isEmpty ? "hand.raised.fill" : "sparkles")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(result.showdownDetails.isEmpty ? PokerTheme.amber : PokerTheme.violet)

                    Text(title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(PokerTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                HStack(spacing: 5) {
                    Image(systemName: "circle.grid.3x3.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(PokerTheme.amber)

                    Text("\(awardedAmount.cleanBb)BB")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(PokerTheme.ink)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if result.sidePots.count > 1 {
                VStack(alignment: .trailing, spacing: 3) {
                    ForEach(Array(result.sidePots.prefix(2).enumerated()), id: \.offset) { index, pot in
                        Text(index == 0 ? "主 \(pot.amountBb.cleanBb)" : "边 \(pot.amountBb.cleanBb)")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(index == 0 ? PokerTheme.ink : PokerTheme.violet)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.white.opacity(0.72), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.50), lineWidth: 1)
        }
        .shadow(color: PokerTheme.ink.opacity(0.07), radius: 18, y: 9)
        .accessibilityLabel(result.summary)
    }
}

private struct AgentDecisionInsightStrip: View {
    let seat: BattleSeatSnapshot
    let action: BattleActionSnapshot

    private var agent: BattleAgent {
        BattleAgent(seat: seat)
    }

    private var decision: BattleDecisionSnapshot? {
        action.decision
    }

    var body: some View {
        HStack(spacing: 10) {
            AgentAvatarView(
                agent: agent,
                size: 32,
                isSelected: true,
                isActive: false
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: action.action.systemImage)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(agent.color, in: Circle())

                    Text("\(seat.position) · \(action.label)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(PokerTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Spacer(minLength: 0)
                }

                AgentStrategyGlyphRow(agent: agent, compact: true)

                if let decision {
                    HStack(spacing: 6) {
                        DecisionEnginePill(decision: decision)
                        DecisionEdgePill(decision: decision)
                    }
                }

                HStack(spacing: 7) {
                    DecisionMiniStat(
                        icon: "percent",
                        value: percent(decision?.equity),
                        tint: PokerTheme.felt
                    )
                    DecisionMiniStat(
                        icon: "circle.grid.3x3.fill",
                        value: percent(decision?.potOdds),
                        tint: PokerTheme.amber
                    )
                    DecisionMiniStat(
                        icon: "arrow.left.and.right",
                        value: decision?.spr.cleanBb ?? "--",
                        tint: PokerTheme.violet
                    )
                    DecisionMiniStat(
                        icon: "checkmark.seal.fill",
                        value: percent(decision?.confidence),
                        tint: agent.color
                    )
                }

                if let candidates = decision?.candidates, !candidates.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(Array(candidates.prefix(3).enumerated()), id: \.offset) { _, candidate in
                            DecisionCandidatePill(
                                candidate: candidate,
                                tint: candidate.isChosen ? agent.color : PokerTheme.muted
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.70), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.48), lineWidth: 1)
        }
        .shadow(color: agent.color.opacity(0.10), radius: 16, y: 8)
        .accessibilityLabel(decision?.summary ?? action.note)
    }

    private func percent(_ value: Double?) -> String {
        guard let value else { return "--" }
        return "\(Int((value * 100).rounded()))%"
    }
}

private struct DecisionEnginePill: View {
    let decision: BattleDecisionSnapshot

    private var icon: String {
        decision.engine == "range_chart" ? "tablecells.fill" : "cpu"
    }

    private var label: String {
        if decision.engine == "range_chart" {
            return "范围表"
        }
        if decision.equitySamples > 0 {
            return "Treys MC \(decision.equitySamples)"
        }
        return "Treys"
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(PokerTheme.violet)

            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(PokerTheme.violet.opacity(0.08), in: Capsule())
        .accessibilityLabel("\(decision.policyProfile)，\(decision.source)")
    }
}

private struct DecisionEdgePill: View {
    let decision: BattleDecisionSnapshot

    private var label: String {
        guard let delta = decision.evDeltaBb else {
            return "EV --"
        }
        let prefix = delta >= 0 ? "+" : ""
        if let alternative = decision.bestAlternativeLabel {
            return "EV \(prefix)\(delta.cleanBb) vs \(alternative)"
        }
        return "EV \(prefix)\(delta.cleanBb)"
    }

    private var tint: Color {
        guard let delta = decision.evDeltaBb else { return PokerTheme.muted }
        return delta >= 0 ? PokerTheme.felt : PokerTheme.amber
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(tint)

            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(tint.opacity(0.08), in: Capsule())
        .accessibilityLabel("已选 \(decision.chosenLabel ?? "动作")，EV 差距 \(decision.evDeltaBb?.cleanBb ?? "--")BB")
    }
}

private struct DecisionCandidatePill: View {
    let candidate: BattleDecisionCandidateSnapshot
    let tint: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: candidate.action.systemImage)
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 14, height: 14)
                .background(tint.opacity(candidate.isChosen ? 1 : 0.72), in: Circle())

            Text(candidate.evBb.signedBb)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(candidate.isChosen ? PokerTheme.ink : PokerTheme.muted)
                .lineLimit(1)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(.white.opacity(candidate.isChosen ? 0.74 : 0.42), in: Capsule())
        .accessibilityLabel("\(candidate.label) EV \(candidate.evBb.cleanBb)BB")
    }
}

private struct DecisionMiniStat: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .frame(minWidth: 42, alignment: .leading)
    }
}

private struct TableActionBubble: View {
    let action: SeatAction
    let tint: Color
    var isHighlighted = false

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulse = isHighlighted ? CGFloat(1 + 0.035 * sin(time * 6.2)) : 1

            HStack(spacing: 5) {
                ZStack {
                    if let confidence = action.confidence {
                        ConfidenceRing(progress: confidence, tint: tint)
                            .frame(width: 24, height: 24)
                    }

                    Image(systemName: action.icon)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(tint, in: Circle())
                }
                .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: -1) {
                    Text(action.title)
                        .font(.caption2.weight(.black))
                    if !action.amount.isEmpty {
                        Text(action.amount)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(PokerTheme.ink)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(width: 86, height: 34)
            .background(.white.opacity(isHighlighted ? 0.92 : 0.74), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isHighlighted ? tint.opacity(0.72) : .white.opacity(0.38), lineWidth: isHighlighted ? 1.8 : 1)
            }
            .scaleEffect(pulse)
            .shadow(color: tint.opacity(isHighlighted ? 0.20 : 0.08), radius: isHighlighted ? 16 : 9, y: isHighlighted ? 8 : 4)
        }
        .accessibilityLabel(action.summary ?? "\(action.title) \(action.amount)")
    }
}

private extension SeatAction {
    init(_ snapshot: BattleActionSnapshot) {
        id = snapshot.id
        title = snapshot.label
        amount = snapshot.amountBb > 0 ? "\(snapshot.amountBb.cleanBb)BB" : ""
        icon = snapshot.action.systemImage
        confidence = snapshot.decision?.confidence
        summary = snapshot.decision?.summary
    }

    init(_ event: BattleReplayEventSnapshot) {
        id = event.actionId
        title = event.action?.shortLabel ?? event.label
        amount = event.amountBb > 0 ? "\(event.amountBb.cleanBb)BB" : ""
        icon = event.action?.systemImage ?? "dot.radiowaves.left.and.right"
        confidence = event.decision?.confidence
        summary = event.decision?.summary ?? event.note
    }
}

private struct TableReplayPulseView: View {
    let event: BattleReplayEventSnapshot

    private var icon: String {
        event.tableEvent?.systemImage ?? event.action?.systemImage ?? "sparkles"
    }

    private var tint: Color {
        event.tableEvent?.tint ?? event.action?.timelineTint ?? PokerTheme.violet
    }

    private var label: String {
        event.tableEvent?.shortLabel ?? event.action?.shortLabel ?? event.label
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let scale = CGFloat(1 + 0.045 * sin(time * 5.4))

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(tint, in: Circle())

                Text(label)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(PokerTheme.ink)
                    .lineLimit(1)

                if !event.cards.isEmpty {
                    BattleMiniCardFan(codes: event.cards, compact: true)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(.white.opacity(0.76), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.26), lineWidth: 1)
            }
            .scaleEffect(scale)
            .shadow(color: tint.opacity(0.12), radius: 14, y: 7)
        }
        .accessibilityLabel(event.label)
    }
}

private struct ConfidenceRing: View {
    let progress: Double
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: 2)

            Circle()
                .trim(from: 0, to: max(0.08, min(progress, 1)))
                .stroke(tint.opacity(0.72), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

private extension BattleActionKind {
    var systemImage: String {
        switch self {
        case .blind:
            "circle.grid.3x3.fill"
        case .fold:
            "xmark"
        case .check:
            "checkmark"
        case .call:
            "arrow.turn.down.right"
        case .bet:
            "circle.fill"
        case .raise:
            "arrow.up.forward"
        case .allIn:
            "flame.fill"
        }
    }

    var timelineTint: Color {
        switch self {
        case .blind:
            PokerTheme.amber
        case .fold:
            PokerTheme.muted
        case .check:
            PokerTheme.violet
        case .call:
            PokerTheme.felt
        case .bet, .raise:
            PokerTheme.coral
        case .allIn:
            PokerTheme.ink
        }
    }

    var shortLabel: String {
        switch self {
        case .blind:
            "盲注"
        case .fold:
            "弃牌"
        case .check:
            "过牌"
        case .call:
            "跟注"
        case .bet:
            "下注"
        case .raise:
            "加注"
        case .allIn:
            "全下"
        }
    }
}

private extension BattleTableEventKind {
    var systemImage: String {
        switch self {
        case .handStart:
            "play.fill"
        case .blindPosted:
            "circle.grid.3x3.fill"
        case .burn:
            "flame.fill"
        case .dealFlop, .dealTurn, .dealRiver:
            "suit.spade.fill"
        case .showdown:
            "sparkles"
        case .uncontested:
            "hand.raised.fill"
        case .handComplete:
            "checkmark.seal.fill"
        }
    }

    var shortLabel: String {
        switch self {
        case .handStart:
            "开局"
        case .blindPosted:
            "盲注"
        case .burn:
            "Burn"
        case .dealFlop:
            "Flop"
        case .dealTurn:
            "Turn"
        case .dealRiver:
            "River"
        case .showdown:
            "摊牌"
        case .uncontested:
            "收池"
        case .handComplete:
            "结束"
        }
    }

    var tint: Color {
        switch self {
        case .handStart:
            PokerTheme.violet
        case .blindPosted:
            PokerTheme.amber
        case .burn:
            PokerTheme.coral
        case .dealFlop, .dealTurn, .dealRiver:
            PokerTheme.ink
        case .showdown:
            PokerTheme.violet
        case .uncontested:
            PokerTheme.amber
        case .handComplete:
            PokerTheme.felt
        }
    }
}

private extension BattleStreet {
    var timelineTitle: String {
        switch self {
        case .preflop:
            "PF"
        case .flop:
            "F"
        case .turn:
            "T"
        case .river:
            "R"
        case .showdown:
            "SD"
        case .complete:
            "END"
        }
    }
}

private struct ObservedHoleCardsView: View {
    let cards: [PokerCardValue]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: -9) {
                ForEach(cards) { card in
                    PlayingCardFace(rank: card.rank, suit: card.suit, tint: card.tint, width: 34, height: 45)
                        .rotationEffect(.degrees(card.fanRotationDegrees))
                }
            }

            Image(systemName: "eye.fill")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 17, height: 17)
                .background(PokerTheme.ink, in: Circle())
                .offset(x: 6, y: -6)
        }
        .shadow(color: PokerTheme.ink.opacity(0.12), radius: 12, y: 7)
    }
}

private struct BattleMiniCardFan: View {
    let codes: [String]
    var compact = false

    private var cards: [PokerCardValue] {
        codes.compactMap(PokerCardValue.init(code:))
    }

    var body: some View {
        if !cards.isEmpty {
            HStack(spacing: compact ? -7 : -8) {
                ForEach(Array(cards.prefix(3).enumerated()), id: \.element.id) { index, card in
                    PlayingCardFace(
                        rank: card.rank,
                        suit: card.suit,
                        tint: card.tint,
                        width: compact ? 18 : 24,
                        height: compact ? 24 : 32
                    )
                    .rotationEffect(.degrees(rotation(for: index, card: card)))
                }
            }
            .shadow(color: PokerTheme.ink.opacity(0.08), radius: compact ? 4 : 7, y: compact ? 2 : 4)
            .accessibilityLabel("\(cards.count) 张扑克牌图形")
        }
    }

    private func rotation(for index: Int, card: PokerCardValue) -> Double {
        let base = [-6.0, 0, 6.0][index % 3]
        return compact ? base * 0.72 : base + card.fanRotationDegrees * 0.25
    }
}

private struct CommunityBoardView: View {
    var cards: [PokerCardValue] = [
        PokerCardValue(id: "qd", rank: "Q", suit: "♦", tint: PokerTheme.coral),
        PokerCardValue(id: "9c", rank: "9", suit: "♣", tint: PokerTheme.ink),
        PokerCardValue(id: "2h", rank: "2", suit: "♥", tint: PokerTheme.coral),
        PokerCardValue(id: "js", rank: "J", suit: "♠", tint: PokerTheme.ink)
    ]

    var body: some View {
        HStack(spacing: -7) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                PlayingCardFace(rank: card.rank, suit: card.suit, tint: card.tint, width: 35, height: 47)
                    .rotationEffect(.degrees(rotation(for: index)))
            }
        }
    }

    private func rotation(for index: Int) -> Double {
        [-4, 2, 5, -3, 4][index % 5]
    }
}

private extension Double {
    var cleanBb: String {
        if abs(self.rounded() - self) < 0.001 {
            return "\(Int(self.rounded()))"
        }
        return String(format: "%.1f", self)
    }

    var signedBb: String {
        if self > 0 {
            return "+\(cleanBb)"
        }
        return cleanBb
    }
}

private struct LiveSeatBadge: View {
    let agent: BattleAgent
    let position: String
    let stackBb: Double?
    let status: String
    let isObserver: Bool
    let isActive: Bool

    private var isFolded: Bool {
        status == "folded"
    }

    private var isAllIn: Bool {
        status == "all_in"
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .bottom) {
                AgentAvatarView(
                    agent: agent,
                    size: 50,
                    isSelected: isObserver,
                    isActive: isActive
                )

                SeatStackPill(
                    stackBb: stackBb,
                    isAllIn: isAllIn,
                    isFolded: isFolded,
                    tint: agent.color
                )
                .offset(y: 12)
            }
            .overlay(alignment: .topTrailing) {
                SeatTapAffordance(isObserver: isObserver, tint: agent.color)
                    .offset(x: 8, y: -1)
            }
            .padding(.bottom, 9)

            HStack(spacing: 3) {
                Text(position)
                    .font(.caption2.weight(.black))
                if isObserver {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 8, weight: .black))
                }
            }
            .foregroundStyle(PokerTheme.ink)

            Text(agent.name)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(PokerTheme.muted)
                .lineLimit(1)
        }
        .opacity(isFolded ? 0.52 : 1)
        .frame(width: 84, height: 92)
    }
}

private struct SeatTapAffordance: View {
    let isObserver: Bool
    let tint: Color

    var body: some View {
        Image(systemName: isObserver ? "eye.fill" : "hand.tap")
            .font(.system(size: 8, weight: .black))
            .foregroundStyle(isObserver ? .white : tint)
            .frame(width: 19, height: 19)
            .background(isObserver ? PokerTheme.ink : .white.opacity(0.90), in: Circle())
            .overlay {
                Circle()
                    .stroke(isObserver ? .white.opacity(0.46) : tint.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: tint.opacity(isObserver ? 0.16 : 0.08), radius: 7, y: 4)
            .accessibilityHidden(true)
    }
}

private struct SeatStackPill: View {
    let stackBb: Double?
    let isAllIn: Bool
    let isFolded: Bool
    let tint: Color

    private var label: String {
        if isAllIn { return "ALL" }
        if isFolded { return "FOLD" }
        return stackBb?.cleanBb ?? "--"
    }

    private var icon: String {
        if isAllIn { return "flame.fill" }
        if isFolded { return "xmark" }
        return "circle.grid.3x3.fill"
    }

    private var foreground: Color {
        isFolded ? PokerTheme.muted : PokerTheme.ink
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(isFolded ? PokerTheme.muted : tint)

            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.white.opacity(isFolded ? 0.48 : 0.86), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.54), lineWidth: 1)
        }
        .shadow(color: tint.opacity(isFolded ? 0.03 : 0.12), radius: 8, y: 4)
    }
}

private struct AgentAvatarView: View {
    let agent: BattleAgent
    var size: CGFloat
    var isSelected: Bool
    var isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.96))
                .frame(width: size, height: size)
                .shadow(
                    color: agent.color.opacity(isActive ? 0.22 : 0.10),
                    radius: isActive ? 16 : 9,
                    y: isActive ? 8 : 5
                )

            AsyncImage(url: diceBearAvatarURL(for: agent)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    ProfessionalAvatarFallback(agent: agent)
                }
            }
            .frame(width: size * 0.82, height: size * 0.82)
            .clipShape(Circle())

            Circle()
                .stroke(isSelected ? PokerTheme.ink : agent.color.opacity(0.28), lineWidth: isSelected ? 2.4 : 1.2)
                .frame(width: size, height: size)

            if isActive {
                ActiveSeatDot()
                    .offset(x: size * 0.34, y: -size * 0.34)
            }
        }
        .frame(width: size + 10, height: size + 10)
        .accessibilityHidden(true)
    }

    private func diceBearAvatarURL(for agent: BattleAgent) -> URL? {
        var components = URLComponents(string: "https://api.dicebear.com/10.x/personas/png")
        components?.queryItems = [
            URLQueryItem(name: "seed", value: agent.avatarSeed),
            URLQueryItem(name: "backgroundColor", value: "ffffff"),
            URLQueryItem(name: "radius", value: "50"),
            URLQueryItem(name: "size", value: "128")
        ]
        return components?.url
    }
}

private struct ActiveSeatDot: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let scale = 1 + CGFloat(0.08 * sin(time * 4.2))

            ZStack {
                Circle()
                    .fill(PokerTheme.coral.opacity(0.18))
                    .frame(width: 18, height: 18)
                    .scaleEffect(scale)

                Circle()
                    .fill(PokerTheme.coral)
                    .frame(width: 10, height: 10)
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    }
            }
        }
    }
}

private struct ProfessionalAvatarFallback: View {
    let agent: BattleAgent

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#F8FAFC"))

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(PokerTheme.ink.opacity(0.88))

            Circle()
                .fill(agent.color)
                .frame(width: 8, height: 8)
                .offset(x: 17, y: -17)
        }
    }
}

private struct BattleTask: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let stateIcon: String

    init(id: String, title: String, subtitle: String, icon: String, tint: Color, stateIcon: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.stateIcon = stateIcon
    }

    init(_ snapshot: BattleTaskSnapshot) {
        id = snapshot.id
        title = snapshot.title
        subtitle = snapshot.subtitle
        icon = snapshot.icon
        tint = Color(hex: snapshot.accent)
        switch snapshot.state {
        case "done":
            stateIcon = "checkmark"
        case "running":
            stateIcon = "bolt.fill"
        default:
            stateIcon = "ellipsis"
        }
    }

    static func liveMock(observer: BattleAgent) -> [BattleTask] {
        [
            BattleTask(id: "range", title: "范围推演", subtitle: "\(observer.name) 手牌桶更新", icon: "scope", tint: PokerTheme.violet, stateIcon: "checkmark"),
            BattleTask(id: "odds", title: "赔率刷新", subtitle: "Turn 后权益 31%", icon: "percent", tint: PokerTheme.felt, stateIcon: "checkmark"),
            BattleTask(id: "line", title: "下注线判断", subtitle: "检测 2 条高频线", icon: "chart.line.uptrend.xyaxis", tint: PokerTheme.amber, stateIcon: "bolt.fill"),
            BattleTask(id: "bluff", title: "诈唬频率", subtitle: "River bluff catch 准备中", icon: "eye.fill", tint: PokerTheme.coral, stateIcon: "ellipsis")
        ]
    }
}

private struct BattleTaskDock: View {
    let tasks: [BattleTask]

    var body: some View {
        HStack(spacing: 14) {
            ForEach(tasks) { task in
                VStack(spacing: 6) {
                    Image(systemName: task.icon)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(task.tint, in: Circle())
                        .shadow(color: task.tint.opacity(0.20), radius: 12, y: 7)

                    Text(task.title)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(PokerTheme.ink)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct BattleTaskRail: View {
    let tasks: [BattleTask]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(34), spacing: 8), count: 2), spacing: 10) {
            ForEach(tasks) { task in
                Image(systemName: task.icon)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(task.tint, in: Circle())
                    .shadow(color: task.tint.opacity(0.16), radius: 8, y: 4)
                    .accessibilityLabel(task.title)
            }
        }
    }
}

private struct PlayingCardFace: View {
    let rank: String
    let suit: String
    let tint: Color
    var width: CGFloat = 36
    var height: CGFloat = 46

    private var suitSystemImage: String {
        switch suit {
        case "♠":
            "suit.spade.fill"
        case "♥":
            "suit.heart.fill"
        case "♦":
            "suit.diamond.fill"
        case "♣":
            "suit.club.fill"
        default:
            "suit.spade.fill"
        }
    }

    private var cornerRadius: CGFloat {
        min(width, height) * 0.18
    }

    private var showsCornerMarks: Bool {
        width >= 30
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.white.opacity(0.96))

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 0.8)

            VStack(spacing: width >= 30 ? 1 : -1) {
                Text(rank)
                    .font(.system(size: width >= 30 ? 12 : 7, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.62)
                    .lineLimit(1)

                Image(systemName: suitSystemImage)
                    .font(.system(size: width >= 30 ? 10 : 7, weight: .black))
                    .symbolRenderingMode(.monochrome)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, width >= 30 ? 5 : 2)

            if showsCornerMarks {
                VStack {
                    HStack {
                        CardCornerMark(rank: rank, suitSystemImage: suitSystemImage, tint: tint)
                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 0)

                    HStack {
                        Spacer(minLength: 0)
                        CardCornerMark(rank: rank, suitSystemImage: suitSystemImage, tint: tint)
                            .rotationEffect(.degrees(180))
                    }
                }
                .padding(4)
            }
        }
        .frame(width: width, height: height)
        .shadow(color: Color(hex: "#071226").opacity(0.08), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("扑克牌图形")
    }
}

private struct CardCornerMark: View {
    let rank: String
    let suitSystemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: -1) {
            Text(rank)
                .font(.system(size: 5.5, weight: .black, design: .rounded))
                .minimumScaleFactor(0.58)
                .lineLimit(1)

            Image(systemName: suitSystemImage)
                .font(.system(size: 4.8, weight: .black))
                .symbolRenderingMode(.monochrome)
        }
        .foregroundStyle(tint)
        .frame(width: 9)
    }
}

private struct MiniChip: View {
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.86))
            Circle()
                .stroke(.white.opacity(0.92), lineWidth: 2)
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.74))
                    .frame(width: 3, height: 6)
                    .offset(y: -8)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
        }
        .frame(width: 23, height: 23)
        .shadow(color: tint.opacity(0.20), radius: 8, y: 5)
    }
}

private struct BattlePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct AIBattleView_Previews: PreviewProvider {
    static var previews: some View {
        AIBattleView()
    }
}
