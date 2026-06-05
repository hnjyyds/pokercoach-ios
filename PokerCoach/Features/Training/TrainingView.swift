import SwiftUI

struct TrainingView: View {
    @Environment(AppSession.self) private var session
    @State private var selectedSegment = 0

    var body: some View {
        ZStack {
            PokerGlassBackdrop()
                .ignoresSafeArea()
            PokerAmbientLayer()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 14) {
                PokerPageHeader(
                    eyebrow: "决策训练库",
                    title: "Drills",
                    subtitle: "情景题和牌力判断",
                    icon: "rectangle.stack.fill",
                    tint: PokerTheme.ink
                )
                .padding(.horizontal, 22)
                .padding(.top, 18)

                trainingSwitch
                    .padding(.horizontal, 22)

                TabView(selection: $selectedSegment) {
                    PreflopTrainerView()
                        .tag(0)

                    HandQuizListView()
                        .tag(1)
                }
                .pokerPageTabStyle()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var trainingSwitch: some View {
        HStack(spacing: 22) {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                    selectedSegment = 0
                }
            } label: {
                TrainingSegmentButton(title: "情景题", icon: "target", isSelected: selectedSegment == 0)
            }
            .buttonStyle(TrainingPressButtonStyle())
            .accessibilityLabel("情景题")
            .accessibilityValue(selectedSegment == 0 ? "已选择" : "未选择")

            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                    selectedSegment = 1
                }
            } label: {
                TrainingSegmentButton(title: "牌力", icon: "suit.spade.fill", isSelected: selectedSegment == 1)
            }
            .buttonStyle(TrainingPressButtonStyle())
            .accessibilityLabel("牌力")
            .accessibilityValue(selectedSegment == 1 ? "已选择" : "未选择")

            Spacer(minLength: 0)
        }
    }
}

private struct TrainingSegmentButton: View {
    let title: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
            Text(title)
                .font(.subheadline.weight(.black))
        }
        .foregroundStyle(isSelected ? PokerTheme.ink : PokerTheme.muted)
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(isSelected ? PokerTheme.ink : .clear)
                .frame(height: 3)
                .offset(y: 8)
        }
        .padding(.vertical, 8)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

private struct PreflopTrainerView: View {
    @Environment(AppSession.self) private var session
    @State private var index = 0
    @State private var selectedAction: PokerAction?
    @State private var result: DecisionResult?
    @State private var isSubmitting = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if let scenario = currentScenario {
                    scenarioSpotlight(scenario)
                    choices(for: scenario)
                    resultPanel
                    navigationControls
                } else {
                    EmptyStateView(icon: "rectangle.stack.badge.questionmark", title: "暂无训练题", message: "启动后端或使用 Demo 模式后会显示 mock 题库。")
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 2)
            .padding(.bottom, PokerLayout.floatingTabBarClearance)
        }
        .task {
            if session.scenarios.isEmpty {
                await session.loadHomeData()
            }
        }
    }

    private var currentScenario: PreflopScenario? {
        guard session.scenarios.indices.contains(index) else { return session.scenarios.first }
        return session.scenarios[index]
    }

    private func scenarioSpotlight(_ scenario: PreflopScenario) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Text(scenario.position)
                    .font(.title3.monospacedDigit().weight(.black))
                    .foregroundStyle(PokerTheme.ink)
                Text("\(scenario.stackDepthBb)BB")
                    .font(.subheadline.monospacedDigit().weight(.black))
                    .foregroundStyle(PokerTheme.amber)
                Spacer()
                Text("\(scenario.potBb, specifier: "%.1f")BB")
                    .font(.subheadline.monospacedDigit().weight(.black))
                    .foregroundStyle(PokerTheme.felt)
            }

            ZStack {
                Capsule()
                    .fill(
                        RadialGradient(
                            colors: [
                                PokerTheme.felt.opacity(0.18),
                                PokerTheme.felt.opacity(0.07),
                                .clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 150
                        )
                    )
                    .frame(height: 138)
                    .overlay {
                        Capsule()
                            .stroke(PokerTheme.felt.opacity(0.18), style: StrokeStyle(lineWidth: 1.4, dash: [8, 12]))
                            .padding(.horizontal, 18)
                    }

                VStack(spacing: 10) {
                    PlayingCardsRow(
                        handClass: scenario.hand,
                        width: 58,
                        height: 78,
                        spacing: -10,
                        rotation: 4
                    )

                    Text(scenario.tableState)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(PokerTheme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 18)
            }

            Label(scenario.villainAction, systemImage: "person.2.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PokerTheme.muted)
        }
    }

    private func choices(for scenario: PreflopScenario) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("你的行动")
                .font(.headline.weight(.black))
                .foregroundStyle(PokerTheme.ink)

            HStack(alignment: .top, spacing: 14) {
                ForEach(scenario.choices) { choice in
                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                            selectedAction = choice.action
                            result = nil
                        }
                    } label: {
                        ActionOptionButton(choice: choice, isSelected: selectedAction == choice.action)
                    }
                    .buttonStyle(TrainingPressButtonStyle())
                    .accessibilityLabel(choiceAccessibilityLabel(choice))
                    .accessibilityValue(selectedAction == choice.action ? "已选择" : "未选择")
                    .frame(maxWidth: .infinity)
                }
            }

            Button {
                Task { await submit(scenario) }
            } label: {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 10) {
                        Text("提交")
                        Image(systemName: "paperplane.fill")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selectedAction == nil || isSubmitting)
            .opacity(selectedAction == nil ? 0.55 : 1)
            .accessibilityLabel("提交你的行动")
        }
    }

    @ViewBuilder
    private var resultPanel: some View {
        if let result {
            VStack(alignment: .leading, spacing: 12) {
                Label(result.isCorrect ? "决策正确" : "建议复盘", systemImage: result.isCorrect ? "checkmark.seal.fill" : "exclamationmark.bubble.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(result.isCorrect ? PokerTheme.felt : PokerTheme.amber)

                Text("推荐：\(result.recommendation)")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(PokerTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(result.explanation)
                    .font(.subheadline)
                    .foregroundStyle(PokerTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                FlowLayout(spacing: 8) {
                    ForEach(result.conceptTags, id: \.self) { tag in
                        TagPill(title: tag)
                    }
                }

                Text(result.nextPrompt)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PokerTheme.muted)
            }
            .padding(.top, 4)
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 22) {
            Button {
                move(by: -1)
            } label: {
                Label("上一题", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            .foregroundStyle(PokerTheme.muted)
            .frame(minHeight: 44)
            .accessibilityLabel("上一题")

            Button {
                move(by: 1)
            } label: {
                Label("下一题", systemImage: "chevron.right")
            }
            .buttonStyle(.plain)
            .foregroundStyle(PokerTheme.ink)
            .frame(minHeight: 44)
            .accessibilityLabel("下一题")
        }
        .font(.headline.weight(.black))
        .padding(.top, 2)
    }

    private func submit(_ scenario: PreflopScenario) async {
        guard let selectedAction else { return }
        isSubmitting = true
        result = await session.answerPreflop(scenario, action: selectedAction)
        isSubmitting = false
    }

    private func move(by delta: Int) {
        guard !session.scenarios.isEmpty else { return }
        index = (index + delta + session.scenarios.count) % session.scenarios.count
        selectedAction = nil
        result = nil
    }

    private func choiceAccessibilityLabel(_ choice: Choice) -> String {
        if let sizing = choice.sizing {
            return "\(choice.label)，\(sizing)"
        }
        return choice.label
    }
}

private struct ActionOptionButton: View {
    let choice: Choice
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected ? PokerTheme.ink : PokerTheme.felt.opacity(0.10))
                    .frame(width: 54, height: 54)
                    .shadow(color: PokerTheme.ink.opacity(isSelected ? 0.16 : 0), radius: 16, y: 8)

                Image(systemName: choice.action.systemImage)
                    .font(.title3.weight(.black))
                    .foregroundStyle(isSelected ? .white : PokerTheme.ink)
            }

            Text(choice.label)
                .font(.subheadline.weight(.black))
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let sizing = choice.sizing {
                Text(sizing)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(PokerTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(minHeight: 104, alignment: .top)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(PokerTheme.ink.opacity(isSelected ? 0.06 : 0), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct HandQuizListView: View {
    @Environment(AppSession.self) private var session
    @State private var selectedAnswers: [String: String] = [:]
    @State private var results: [String: DecisionResult] = [:]
    @State private var selectedQuiz: HandQuiz?
    @State private var focus = "牌力识别"
    @State private var difficulty = "新手"
    @State private var street = "river"
    @State private var isGenerating = false

    private let focusOptions = ["牌力识别", "底池赔率", "范围判断"]
    private let difficultyOptions = ["新手", "进阶"]
    private let streetOptions = ["flop", "turn", "river"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                generatorPanel

                if session.handQuizzes.isEmpty {
                    EmptyStateView(icon: "suit.heart", title: "暂无牌力题", message: "mock 题库会在首页数据加载后出现。")
                } else {
                    ForEach(session.handQuizzes) { quiz in
                        AgentQuizCard(
                            quiz: quiz,
                            selectedAnswer: selectedAnswers[quiz.id],
                            result: results[quiz.id],
                            onSelect: { option in
                                Task { await select(option, for: quiz) }
                            },
                            onAskCoach: {
                                selectedQuiz = quiz
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, PokerLayout.floatingTabBarClearance)
        }
        .sheet(item: $selectedQuiz) { quiz in
            QuizCoachSheet(quiz: quiz)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task {
            if session.handQuizzes.isEmpty {
                await session.loadHomeData()
            }
        }
    }

    private var generatorPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(PokerTheme.ink, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Agent 生成题")
                        .font(.headline.weight(.black))
                        .foregroundStyle(PokerTheme.ink)
                    Text("围绕一个论点生成可追问案例")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PokerTheme.muted)
                }

                Spacer(minLength: 0)

                Button {
                    Task { await generateQuiz() }
                } label: {
                    Image(systemName: isGenerating ? "hourglass" : "plus")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(PokerTheme.ink.opacity(isGenerating ? 0.58 : 1), in: Circle())
                }
                .buttonStyle(TrainingPressButtonStyle())
                .disabled(isGenerating)
                .accessibilityLabel("生成 Agent 题目")
            }

            VStack(alignment: .leading, spacing: 10) {
                QuizOptionPicker(title: "重点", options: focusOptions, selection: $focus)
                QuizOptionPicker(title: "难度", options: difficultyOptions, selection: $difficulty)
                QuizOptionPicker(title: "街道", options: streetOptions, selection: $street)
            }
        }
    }

    private func select(_ option: String, for quiz: HandQuiz) async {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
            selectedAnswers[quiz.id] = option
        }
        let result = await session.answerHandQuiz(quiz, answer: option)
        withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
            results[quiz.id] = result
        }
    }

    private func generateQuiz() async {
        guard !isGenerating else { return }
        isGenerating = true
        defer { isGenerating = false }
        _ = await session.generateHandQuiz(focus: focus, difficulty: difficulty, street: street)
    }
}

private struct QuizOptionPicker: View {
    let title: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(PokerTheme.muted)
                .frame(width: 36, alignment: .leading)

            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selection = option
                    }
                } label: {
                    Text(option)
                        .font(.caption.weight(.black))
                        .foregroundStyle(selection == option ? .white : PokerTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selection == option ? PokerTheme.ink : Color.white.opacity(0.52), in: Capsule())
                }
                .buttonStyle(TrainingPressButtonStyle())
                .accessibilityValue(selection == option ? "已选择" : "未选择")
            }
        }
    }
}

private struct AgentQuizCard: View {
    let quiz: HandQuiz
    let selectedAnswer: String?
    let result: DecisionResult?
    let onSelect: (String) -> Void
    let onAskCoach: () -> Void

    private var accent: Color {
        Color(hex: quiz.agentAccent ?? "#8B5CF6")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: quiz.agentIcon ?? "sparkles")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(accent, in: Circle())
                    .shadow(color: accent.opacity(0.14), radius: 12, y: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(quiz.sourceAgent ?? "Agent") 生成")
                        .font(.headline.weight(.black))
                        .foregroundStyle(PokerTheme.ink)
                    Text(quiz.thesis ?? "围绕当前题目建立一个清晰论点。")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PokerTheme.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(action: onAskCoach) {
                    Image(systemName: "message.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(PokerTheme.ink)
                        .frame(width: 42, height: 42)
                        .background(Color.white.opacity(0.60), in: Circle())
                }
                .buttonStyle(TrainingPressButtonStyle())
                .accessibilityLabel("围绕当前题目问导师")
            }

            QuizMetaRail(quiz: quiz, accent: accent)

            QuizCardsScene(quiz: quiz)

            Text(quiz.question)
                .font(.title3.weight(.black))
                .foregroundStyle(PokerTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                ForEach(quiz.options, id: \.self) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        QuizOptionButton(
                            title: option,
                            isSelected: selectedAnswer == option,
                            isCorrect: option == quiz.answer
                        )
                    }
                    .buttonStyle(TrainingPressButtonStyle())
                    .accessibilityLabel(option)
                    .accessibilityValue(selectedAnswer == option ? "已选择" : "未选择")
                    .frame(maxWidth: .infinity)
                }
            }

            if let result {
                QuizResultPanel(result: result, answer: quiz.answer, accent: accent)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct QuizMetaRail: View {
    let quiz: HandQuiz
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            QuizMiniMetric(icon: "location.fill", value: quiz.position ?? "BTN", tint: accent)
            QuizMiniMetric(icon: "suit.spade.fill", value: (quiz.street ?? "river").capitalized, tint: PokerTheme.ink)
            QuizMiniMetric(icon: "circle.grid.3x3.fill", value: quizBb(Double(quiz.stackDepthBb ?? 100)), tint: PokerTheme.amber)
            QuizMiniMetric(icon: "target", value: quiz.difficulty ?? "新手", tint: PokerTheme.felt)
            Spacer(minLength: 0)
        }
    }
}

private struct QuizMiniMetric: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
            Text(value)
                .font(.caption.monospacedDigit().weight(.black))
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
        }
    }
}

private struct QuizCardsScene: View {
    let quiz: HandQuiz

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                HandQuizCardsLine(label: "Hero", cards: quiz.heroHand, tint: PokerTheme.felt)
                HandQuizCardsLine(label: "对手", cards: quiz.villainHand, tint: PokerTheme.coral)
            }

            HandQuizCardsLine(label: "公共牌", cards: quiz.board, tint: PokerTheme.ink, cardWidth: 28, cardHeight: 38)
        }
    }
}

private struct QuizResultPanel: View {
    let result: DecisionResult
    let answer: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: result.isCorrect ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(result.isCorrect ? PokerTheme.felt : PokerTheme.coral)
                Text(result.isCorrect ? "判断正确" : "推荐答案：\(answer)")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(PokerTheme.ink)
            }

            Text(result.explanation)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PokerTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 7) {
                ForEach(result.conceptTags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.10), in: Capsule())
                }
            }
        }
    }
}

private struct QuizCoachSheet: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State var quiz: HandQuiz
    @State private var draft = ""
    @State private var isSending = false

    private var messages: [CoachMessageSnapshot] {
        quiz.coachMessages ?? []
    }

    var body: some View {
        ZStack {
            PokerGlassBackdrop()
                .ignoresSafeArea()
            PokerAmbientLayer()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.black))
                            .foregroundStyle(PokerTheme.ink)
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.62), in: Circle())
                    }
                    .buttonStyle(TrainingPressButtonStyle())
                    .accessibilityLabel("关闭导师对话")

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(quiz.sourceAgent ?? "Agent") 导师")
                            .font(.title3.weight(.black))
                            .foregroundStyle(PokerTheme.ink)
                        Text(quiz.thesis ?? quiz.question)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PokerTheme.muted)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }

                QuizCardsScene(quiz: quiz)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            QuizCoachBubble(message: message)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }

                HStack(spacing: 10) {
                    TextField("围绕这题追问导师", text: $draft, axis: .vertical)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PokerTheme.ink)
                        .lineLimit(1...3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .textFieldStyle(.plain)

                    Button {
                        Task { await send() }
                    } label: {
                        Image(systemName: isSending ? "hourglass" : "arrow.up")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(PokerTheme.ink.opacity(canSend ? 1 : 0.42), in: Circle())
                    }
                    .buttonStyle(TrainingPressButtonStyle())
                    .disabled(!canSend)
                    .accessibilityLabel("发送给导师")
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 18)
        }
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    private func send() async {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isSending else { return }
        draft = ""
        isSending = true
        defer { isSending = false }
        if let updated = await session.coachHandQuiz(id: quiz.id, message: message) {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                quiz = updated
            }
        }
    }
}

private struct QuizCoachBubble: View {
    let message: CoachMessageSnapshot

    private var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack(alignment: .top) {
            if isUser { Spacer(minLength: 44) }

            Text(message.content)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isUser ? .white : PokerTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(isUser ? PokerTheme.ink : Color.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            if !isUser { Spacer(minLength: 44) }
        }
    }
}

private func quizBb(_ value: Double) -> String {
    if abs(value.rounded() - value) < 0.001 {
        return "\(Int(value.rounded()))BB"
    }
    return String(format: "%.1fBB", value)
}

private struct HandQuizCardsLine: View {
    let label: String
    let cards: String
    let tint: Color
    var cardWidth: CGFloat = 34
    var cardHeight: CGFloat = 46

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 48, alignment: .leading)
                .lineLimit(1)

            PlayingCardsRow(
                cardText: cards,
                width: cardWidth,
                height: cardHeight,
                spacing: -6,
                rotation: 2.5
            )

            Spacer(minLength: 0)
        }
    }
}

private struct QuizOptionButton: View {
    let title: String
    let isSelected: Bool
    let isCorrect: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isSelected ? (isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill") : "circle")
                .font(.title3.weight(.black))
                .foregroundStyle(isSelected ? (isCorrect ? PokerTheme.felt : PokerTheme.coral) : PokerTheme.muted)
            Text(title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 10)
        .frame(minHeight: 64)
        .frame(maxWidth: .infinity)
        .background(PokerTheme.ink.opacity(isSelected ? 0.06 : 0), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct TrainingPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.23, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) { content }
            VStack(alignment: .leading, spacing: spacing) { content }
        }
    }
}

struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        let session = AppSession()
        session.startOfflineDemo()
        return NavigationStack {
            TrainingView()
        }
        .environment(session)
    }
}
