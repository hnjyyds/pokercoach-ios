import SwiftUI

private enum AuthMode: String, CaseIterable, Identifiable {
    case login = "登录"
    case register = "注册"

    var id: String { rawValue }
}

struct AuthView: View {
    @Environment(AppSession.self) private var session
    @State private var mode: AuthMode = .login
    @State private var name = ""
    @State private var email = "alex@example.com"
    @State private var password = "password"
    @State private var isReady = false

    var body: some View {
        ZStack {
            EvoseInspiredBackdrop()
                .ignoresSafeArea()

            BottomTableAccent()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            GeometryReader { proxy in
                let contentWidth = min(max(proxy.size.width - 44, 0), 560)
                let horizontalPadding = max((proxy.size.width - contentWidth) / 2, 22)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        heroCopy
                        TrainingWorkbenchPreview()
                        authPanel
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 18)
                    .opacity(isReady ? 1 : 0)
                    .offset(y: isReady ? 0 : 16)
                }
            }
        }
        .preferredColorScheme(.light)
        .task {
            withAnimation(.spring(response: 0.72, dampingFraction: 0.86)) {
                isReady = true
            }
        }
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.black))
                Text("打造你的德州扑克 AI 训练团队")
                    .font(.caption.weight(.black))
            }
            .foregroundStyle(Color(hex: "#071226"))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white, in: Capsule())
            .shadow(color: Color(hex: "#121A2C").opacity(0.06), radius: 16, y: 8)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "#071226"))
                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)

                Text("PokerCoach")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#050812"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .padding(.top, 6)
    }

    private var authPanel: some View {
        VStack(spacing: 12) {
            AuthModeSwitch(selection: $mode)

            VStack(spacing: 9) {
                if mode == .register {
                    AuthInputField(
                        icon: "person.crop.circle",
                        placeholder: "你的牌桌昵称",
                        text: $name
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                AuthInputField(
                    icon: "envelope",
                    placeholder: "alex@example.com",
                    text: $email,
                    keyboardType: .emailAddress
                )

                AuthInputField(
                    icon: "lock",
                    placeholder: "至少 6 位密码",
                    text: $password,
                    isSecure: true
                )
            }

            if let errorMessage = session.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(errorMessage)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(PokerTheme.coral)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task { await submit() }
            } label: {
                HStack(spacing: 10) {
                    if session.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(mode == .login ? "开始训练" : "创建档案")
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.black))
                            .frame(width: 24, height: 24)
                            .background(.white, in: Circle())
                            .foregroundStyle(Color(hex: "#071226"))
                    }
                }
            }
            .buttonStyle(EvosePrimaryButtonStyle())
            .disabled(session.isLoading || !canSubmit)
            .opacity(canSubmit ? 1 : 0.48)
            .animation(.easeInOut(duration: 0.2), value: canSubmit)

        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: mode)
    }

    private var canSubmit: Bool {
        if mode == .register, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return email.contains("@") && password.count >= 6
    }

    private func submit() async {
        switch mode {
        case .login:
            await session.signIn(email: email, password: password)
        case .register:
            await session.register(name: name, email: email, password: password)
        }
    }
}

private struct EvoseInspiredBackdrop: View {
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
                            Color(hex: "#F4F8FF"),
                            Color(hex: "#F7FBF5")
                        ]),
                        startPoint: CGPoint(x: rect.minX, y: rect.minY),
                        endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                    )
                )

                var coolBand = Path()
                coolBand.move(to: CGPoint(x: -40, y: size.height * 0.08))
                coolBand.addCurve(
                    to: CGPoint(x: size.width + 80, y: size.height * 0.18),
                    control1: CGPoint(x: size.width * 0.26, y: size.height * 0.02),
                    control2: CGPoint(x: size.width * 0.67, y: size.height * 0.24)
                )
                coolBand.addLine(to: CGPoint(x: size.width + 80, y: size.height * 0.36))
                coolBand.addCurve(
                    to: CGPoint(x: -40, y: size.height * 0.28),
                    control1: CGPoint(x: size.width * 0.70, y: size.height * 0.30),
                    control2: CGPoint(x: size.width * 0.22, y: size.height * 0.39)
                )
                coolBand.closeSubpath()
                context.fill(
                    coolBand,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: "#EAF2FF").opacity(0.08),
                            Color(hex: "#DCE9FF").opacity(0.24),
                            Color.clear
                        ]),
                        startPoint: CGPoint(x: 0, y: size.height * 0.1),
                        endPoint: CGPoint(x: size.width, y: size.height * 0.35)
                    )
                )

                var feltBand = Path()
                feltBand.move(to: CGPoint(x: -80, y: size.height * 0.62))
                feltBand.addCurve(
                    to: CGPoint(x: size.width + 40, y: size.height * 0.50),
                    control1: CGPoint(x: size.width * 0.26, y: size.height * 0.54),
                    control2: CGPoint(x: size.width * 0.62, y: size.height * 0.68)
                )
                feltBand.addLine(to: CGPoint(x: size.width + 40, y: size.height * 0.88))
                feltBand.addCurve(
                    to: CGPoint(x: -80, y: size.height * 0.80),
                    control1: CGPoint(x: size.width * 0.68, y: size.height * 0.78),
                    control2: CGPoint(x: size.width * 0.22, y: size.height * 0.94)
                )
                feltBand.closeSubpath()
                context.fill(
                    feltBand,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.clear,
                            Color(hex: "#DDF8EE").opacity(0.28),
                            Color(hex: "#EEF6FF").opacity(0.10)
                        ]),
                        startPoint: CGPoint(x: 0, y: size.height * 0.58),
                        endPoint: CGPoint(x: size.width, y: size.height * 0.86)
                    )
                )

                for x in stride(from: CGFloat(8), through: size.width, by: 17) {
                    for y in stride(from: CGFloat(10), through: size.height, by: 17) {
                        let wave = sin(Double(x + y) * 0.018 + time * 0.45)
                        let opacity = 0.18 + 0.07 * wave
                        let dotRect = CGRect(x: x, y: y, width: 2, height: 2)
                        context.fill(
                            Path(ellipseIn: dotRect),
                            with: .color(Color(hex: "#DDE4F0").opacity(opacity))
                        )
                    }
                }

                let clusterOrigin = CGPoint(x: size.width * 0.72, y: size.height * 0.34)
                for column in 0..<13 {
                    for row in 0..<11 {
                        let dx = CGFloat(column) * 14
                        let dy = CGFloat(row) * 14
                        let distance = hypot(Double(column - 8), Double(row - 5))
                        let pulse = 0.5 + 0.5 * sin(time * 1.15 + Double(column) * 0.6 + Double(row) * 0.42)
                        let opacity = max(0.0, 0.70 - distance * 0.085) * (0.65 + 0.35 * pulse)
                        let radius = CGFloat(2.1 + pulse * 1.4)
                        let point = CGPoint(x: clusterOrigin.x + dx, y: clusterOrigin.y + dy)
                        context.fill(
                            Path(ellipseIn: CGRect(x: point.x, y: point.y, width: radius, height: radius)),
                            with: .color(Color(hex: "#645CFF").opacity(opacity))
                        )
                    }
                }

                for index in 0..<5 {
                    var path = Path()
                    let y = size.height * (0.18 + CGFloat(index) * 0.12)
                    let offset = CGFloat(sin(time * 0.32 + Double(index))) * 12
                    path.move(to: CGPoint(x: -40, y: y + offset))
                    path.addCurve(
                        to: CGPoint(x: size.width + 40, y: y + 18 - offset),
                        control1: CGPoint(x: size.width * 0.25, y: y - 28),
                        control2: CGPoint(x: size.width * 0.68, y: y + 42)
                    )
                    context.stroke(path, with: .color(Color(hex: "#DDE7F5").opacity(0.48)), lineWidth: 1)
                }
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Color(hex: "#F8FAFD").opacity(0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
            }
        }
    }
}

private struct BottomTableAccent: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { proxy in
                let height = max(proxy.size.height * 0.36, 280)
                let chipStyles: [(Color, String)] = [
                    (Color(hex: "#8B5CF6"), "suit.spade.fill"),
                    (Color(hex: "#13C8A6"), "suit.club.fill"),
                    (Color(hex: "#F59E0B"), "suit.diamond.fill"),
                    (Color(hex: "#EF4444"), "suit.heart.fill")
                ]

                ZStack(alignment: .bottom) {
                    Canvas { context, size in
                        let rect = CGRect(origin: .zero, size: size)
                        context.fill(Path(rect), with: .color(.clear))

                        let tableRect = CGRect(
                            x: -size.width * 0.24,
                            y: size.height * 0.24 + CGFloat(sin(time * 0.35)) * 4,
                            width: size.width * 1.48,
                            height: size.height * 0.84
                        )
                        var table = Path()
                        table.addEllipse(in: tableRect)
                        context.fill(
                            table,
                            with: .radialGradient(
                                Gradient(colors: [
                                    Color(hex: "#A8F0DD").opacity(0.24),
                                    Color(hex: "#EAF8F4").opacity(0.18),
                                    Color.clear
                                ]),
                                center: CGPoint(x: size.width * 0.5, y: size.height * 0.72),
                                startRadius: 20,
                                endRadius: size.width * 0.82
                            )
                        )

                        var rim = Path()
                        rim.addEllipse(in: tableRect.insetBy(dx: size.width * 0.10, dy: size.height * 0.10))
                        context.stroke(
                            rim,
                            with: .color(Color(hex: "#76D7C4").opacity(0.16)),
                            style: StrokeStyle(lineWidth: 1.4, dash: [8, 10])
                        )

                        var lowerGlow = Path()
                        lowerGlow.addEllipse(in: CGRect(
                            x: size.width * 0.06,
                            y: size.height * 0.55,
                            width: size.width * 0.88,
                            height: size.height * 0.42
                        ))
                        context.fill(
                            lowerGlow,
                            with: .radialGradient(
                                Gradient(colors: [
                                    Color(hex: "#071226").opacity(0.045),
                                    Color.clear
                                ]),
                                center: CGPoint(x: size.width * 0.52, y: size.height * 0.75),
                                startRadius: 4,
                                endRadius: size.width * 0.62
                            )
                        )
                    }
                    .frame(height: height)

                    HStack(spacing: -11) {
                        DecorativeSuitCard(systemName: "suit.spade.fill", tint: Color(hex: "#071226"))
                            .rotationEffect(.degrees(-8))
                        DecorativeSuitCard(systemName: "suit.heart.fill", tint: PokerTheme.coral)
                            .rotationEffect(.degrees(7))
                    }
                    .opacity(0.16)
                    .offset(x: -92 + CGFloat(sin(time * 0.55)) * 4, y: -34)

                    HStack(spacing: -9) {
                        ForEach(Array(chipStyles.enumerated()), id: \.offset) { index, style in
                            DecorativeChip(tint: style.0, symbol: style.1)
                                .rotationEffect(.degrees(Double(index - 1) * 5))
                                .offset(y: CGFloat(index % 2) * -5 + CGFloat(cos(time * 0.5 + Double(index))) * 2)
                        }
                    }
                    .opacity(0.52)
                    .offset(x: 90 + CGFloat(cos(time * 0.5)) * 4, y: -45)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}

private struct DecorativeSuitCard: View {
    let systemName: String
    let tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
            .fill(.white.opacity(0.92))
            .frame(width: 52, height: 70)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(tint)
            )
            .shadow(color: Color(hex: "#071226").opacity(0.08), radius: 12, y: 7)
    }
}

private struct DecorativeChip: View {
    let tint: Color
    let symbol: String

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.34))
                .offset(x: 2, y: 4)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.92),
                            tint.opacity(0.70)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(.white.opacity(0.92), lineWidth: 2.5)

            Circle()
                .stroke(tint.opacity(0.70), lineWidth: 1.6)
                .frame(width: 27, height: 27)

            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.86))
                    .frame(width: 5, height: 10)
                    .offset(y: -15)
                    .rotationEffect(.degrees(Double(index) * 45))
            }

            Circle()
                .fill(.white.opacity(0.82))
                .frame(width: 17, height: 17)

            Image(systemName: symbol)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(tint.opacity(0.95))
        }
        .frame(width: 39, height: 39)
        .shadow(color: tint.opacity(0.24), radius: 11, y: 7)
    }
}

private enum WorkbenchModule: String, CaseIterable, Identifiable {
    case preflop
    case hand
    case odds

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .preflop: "target"
        case .hand: "rectangle.stack.fill"
        case .odds: "chart.line.uptrend.xyaxis"
        }
    }

    var title: String {
        switch self {
        case .preflop: "翻前"
        case .hand: "牌力"
        case .odds: "赔率"
        }
    }

    var subtitle: String {
        switch self {
        case .preflop: "范围"
        case .hand: "听牌"
        case .odds: "EV"
        }
    }

    var coachTitle: String {
        switch self {
        case .preflop: "Preflop"
        case .hand: "Hand Read"
        case .odds: "Pot Odds"
        }
    }

    var scenarioTitle: String {
        switch self {
        case .preflop: "CO 2.5BB · BTN"
        case .hand: "Turn · 同花听牌"
        case .odds: "Pot Odds · 32%"
        }
    }

    var scenarioHandClass: String? {
        switch self {
        case .preflop: "AKo"
        default: nil
        }
    }

    var advice: String {
        switch self {
        case .preflop: "3-bet 8BB"
        case .hand: "保留后门权益"
        case .odds: "跟注边界清晰"
        }
    }

    var accent: Color {
        switch self {
        case .preflop: Color(hex: "#8B5CF6")
        case .hand: Color(hex: "#F59E0B")
        case .odds: Color(hex: "#13C8A6")
        }
    }

    var metrics: [WorkbenchMetric] {
        switch self {
        case .preflop:
            [
                WorkbenchMetric(title: "范围", value: "88%"),
                WorkbenchMetric(title: "赔率", value: "+EV"),
                WorkbenchMetric(title: "复盘", value: "2")
            ]
        case .hand:
            [
                WorkbenchMetric(title: "权益", value: "72%"),
                WorkbenchMetric(title: "Outs", value: "9"),
                WorkbenchMetric(title: "动作", value: "Call")
            ]
        case .odds:
            [
                WorkbenchMetric(title: "底池", value: "32%"),
                WorkbenchMetric(title: "赔率", value: "4.1"),
                WorkbenchMetric(title: "EV", value: "+0.6")
            ]
        }
    }
}

private enum WorkbenchStatus: String, CaseIterable, Identifiable {
    case range
    case odds

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .range: "checkmark.circle.fill"
        case .odds: "percent"
        }
    }

    var title: String {
        switch self {
        case .range: "范围完成"
        case .odds: "赔率完成"
        }
    }

    var subtitle: String {
        switch self {
        case .range: "12 手牌局"
        case .odds: "3 个任务"
        }
    }

    var tint: Color {
        switch self {
        case .range: Color(hex: "#8B5CF6")
        case .odds: Color(hex: "#13C8A6")
        }
    }

    var targetModule: WorkbenchModule {
        switch self {
        case .range: .preflop
        case .odds: .odds
        }
    }
}

private struct WorkbenchMetric: Identifiable {
    let title: String
    let value: String

    var id: String { title }
}

private struct TrainingWorkbenchPreview: View {
    @State private var selectedModule: WorkbenchModule = .preflop
    @State private var selectedStatus: WorkbenchStatus = .range
    @State private var tapToken = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { proxy in
                let width = proxy.size.width
                let moduleWidth = min(max(width * 0.31, 114), 132)
                let coachWidth = min(max(width * 0.54, 196), 230)
                let statusWidth = min(max(width * 0.36, 132), 148)
                let metricsWidth = min(max(width * 0.47, 176), 210)
                let drift = CGFloat(sin(time * 0.7)) * 4

                ZStack {
                    ModuleDock(
                        selectedModule: selectedModule,
                        width: moduleWidth
                    ) { module in
                        choose(module: module)
                    }
                    .position(x: moduleWidth / 2 + 2, y: 112 + drift)
                    .zIndex(1)

                    CoachPreviewCard(module: selectedModule, tapToken: tapToken)
                        .frame(width: coachWidth)
                        .position(x: width * 0.58, y: 84 - drift * 0.6)
                        .zIndex(2)

                    VStack(spacing: 11) {
                        ForEach(WorkbenchStatus.allCases) { status in
                            StatusPreviewButton(
                                status: status,
                                isActive: selectedStatus == status,
                                width: statusWidth
                            ) {
                                choose(status: status)
                            }
                        }
                    }
                    .position(x: width - statusWidth / 2 + 3, y: 83 + drift * 0.4)
                    .zIndex(3)

                    MetricStrip(module: selectedModule)
                        .frame(width: metricsWidth)
                        .position(x: width * 0.62, y: 178 + CGFloat(cos(time * 0.55)) * 2)
                        .zIndex(4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 220)
        }
        .padding(.top, 2)
    }

    private func choose(module: WorkbenchModule) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            selectedModule = module
            selectedStatus = module == .odds ? .odds : .range
            tapToken += 1
        }
    }

    private func choose(status: WorkbenchStatus) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            selectedStatus = status
            selectedModule = status.targetModule
            tapToken += 1
        }
    }
}

private struct ModuleDock: View {
    let selectedModule: WorkbenchModule
    let width: CGFloat
    let onSelect: (WorkbenchModule) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "suit.spade.fill")
                    .font(.caption.weight(.black))
                Text("Coach")
                    .font(.caption.weight(.black))
            }
            .foregroundStyle(Color(hex: "#071226"))
            .padding(.bottom, 1)

            ForEach(WorkbenchModule.allCases) { module in
                Button {
                    onSelect(module)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: module.symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(selectedModule == module ? .white : Color(hex: "#657085"))
                            .frame(width: 25, height: 25)
                            .background(
                                selectedModule == module ? module.accent : Color(hex: "#F0F4FA"),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )

                        VStack(alignment: .leading, spacing: 1) {
                            Text(module.title)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(Color(hex: "#071226"))
                            Text(module.subtitle)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color(hex: "#8A94A6"))
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 7)
                    .frame(height: 40)
                    .background(
                        (selectedModule == module ? module.accent.opacity(0.10) : .white.opacity(0.76)),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
                }
                .buttonStyle(PreviewPressButtonStyle())
                .accessibilityLabel(module.title)
            }
        }
        .padding(10)
        .frame(width: width, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color(hex: "#071226").opacity(0.07), radius: 24, y: 14)
    }
}

private struct CoachPreviewCard: View {
    let module: WorkbenchModule
    let tapToken: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#071226"))
                    Image(systemName: "suit.spade.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                }
                .frame(width: 34, height: 34)
                .shadow(color: module.accent.opacity(0.20), radius: 12, y: 6)

                VStack(alignment: .leading, spacing: 1) {
                    Text(module.coachTitle)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(hex: "#071226"))
                        .lineLimit(1)
                    Text("实时训练")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(hex: "#697386"))
                }

                Spacer(minLength: 0)

                Image(systemName: "sparkles")
                    .font(.caption.weight(.black))
                    .foregroundStyle(module.accent)
                    .symbolEffect(.bounce, value: tapToken)
            }

            HStack(spacing: 8) {
                Text(module.scenarioTitle)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(Color(hex: "#071226"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                if let handClass = module.scenarioHandClass {
                    PlayingCardsRow(
                        handClass: handClass,
                        width: 24,
                        height: 32,
                        spacing: -5,
                        rotation: 2
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#F8FAFD").opacity(0.92), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            HStack(spacing: 8) {
                Image(systemName: module.symbol)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 25, height: 25)
                    .background(module.accent, in: Circle())

                Text(module.advice)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(hex: "#071226"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(module.accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .padding(12)
        .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "#071226").opacity(0.08), radius: 28, y: 18)
        .transition(.scale(scale: 0.96).combined(with: .opacity))
    }
}

private struct StatusPreviewButton: View {
    let status: WorkbenchStatus
    let isActive: Bool
    let width: CGFloat
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: status.symbol)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(status.tint, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .shadow(color: status.tint.opacity(isActive ? 0.24 : 0.10), radius: 12, y: 7)

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(hex: "#071226"))
                        .lineLimit(1)
                    Text(status.subtitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(hex: "#8A94A6"))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .frame(width: width, alignment: .leading)
            .background(.white.opacity(isActive ? 0.96 : 0.86), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .shadow(color: Color(hex: "#071226").opacity(isActive ? 0.12 : 0.07), radius: isActive ? 22 : 16, y: isActive ? 13 : 9)
            .scaleEffect(isActive ? 1.035 : 1)
        }
        .buttonStyle(PreviewPressButtonStyle())
        .accessibilityLabel(status.title)
    }
}

private struct MetricStrip: View {
    let module: WorkbenchModule

    var body: some View {
        HStack(spacing: 8) {
            ForEach(module.metrics) { metric in
                VStack(alignment: .leading, spacing: 1) {
                    Text(metric.value)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(hex: "#071226"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(metric.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(hex: "#8A94A6"))
                        .lineLimit(1)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .shadow(color: Color(hex: "#071226").opacity(0.05), radius: 12, y: 8)
            }
        }
    }
}

private struct PreviewPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.23, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private struct AuthModeSwitch: View {
    @Binding var selection: AuthMode
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AuthMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                        selection = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(selection == mode ? .white : Color(hex: "#697386"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            if selection == mode {
                                Capsule()
                                    .fill(Color(hex: "#071226"))
                                    .matchedGeometryEffect(id: "selectedMode", in: namespace)
                                    .shadow(color: Color(hex: "#071226").opacity(0.14), radius: 12, y: 8)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(hex: "#F3F6FA"), in: Capsule())
        .overlay(Capsule().stroke(Color(hex: "#E7EBF2"), lineWidth: 1))
        .shadow(color: Color(hex: "#121A2C").opacity(0.05), radius: 14, y: 8)
    }
}

private struct AuthInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color(hex: "#8A94A6"))
                .frame(width: 26)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(Color(hex: "#071226"))
            .textFieldStyle(.plain)
            .pokerNoAutocapitalization()
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color(hex: "#F7F9FC"), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color(hex: "#E7ECF4"), lineWidth: 1)
        )
        .shadow(color: Color(hex: "#121A2C").opacity(0.04), radius: 12, y: 7)
    }
}

private struct EvosePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(hex: "#071226"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: "#071226").opacity(configuration.isPressed ? 0.12 : 0.22), radius: 16, y: 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environment(AppSession())
    }
}
