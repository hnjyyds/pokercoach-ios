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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                if session.handQuizzes.isEmpty {
                    EmptyStateView(icon: "suit.heart", title: "暂无牌力题", message: "mock 题库会在首页数据加载后出现。")
                } else {
                    ForEach(session.handQuizzes) { quiz in
                        quizView(quiz)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, PokerLayout.floatingTabBarClearance)
        }
    }

    private func quizView(_ quiz: HandQuiz) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Label(quiz.question, systemImage: "suit.spade.fill")
                .font(.title3.weight(.black))
                .foregroundStyle(PokerTheme.ink)

            VStack(alignment: .leading, spacing: 6) {
                HandQuizCardsLine(label: "Hero", cards: quiz.heroHand, tint: PokerTheme.felt)
                HandQuizCardsLine(label: "Villain", cards: quiz.villainHand, tint: PokerTheme.coral)
                HandQuizCardsLine(label: "公共牌", cards: quiz.board, tint: PokerTheme.ink, cardWidth: 30, cardHeight: 40)
            }

            HStack(spacing: 14) {
                ForEach(quiz.options, id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                            selectedAnswers[quiz.id] = option
                        }
                    } label: {
                        QuizOptionButton(
                            title: option,
                            isSelected: selectedAnswers[quiz.id] == option,
                            isCorrect: option == quiz.answer
                        )
                    }
                    .buttonStyle(TrainingPressButtonStyle())
                    .accessibilityLabel(option)
                    .accessibilityValue(selectedAnswers[quiz.id] == option ? "已选择" : "未选择")
                    .frame(maxWidth: .infinity)
                }
            }

            if let selected = selectedAnswers[quiz.id] {
                Text(selected == quiz.answer ? quiz.explanation : "正确答案是 \(quiz.answer)。\(quiz.explanation)")
                    .font(.subheadline)
                    .foregroundStyle(PokerTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
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
