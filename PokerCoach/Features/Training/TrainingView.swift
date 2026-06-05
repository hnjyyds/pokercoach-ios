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
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                    selectedSegment = 1
                }
            } label: {
                TrainingSegmentButton(title: "牌力", icon: "suit.spade.fill", isSelected: selectedSegment == 1)
            }
            .buttonStyle(.plain)

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
                    Text(scenario.hand)
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .foregroundStyle(PokerTheme.ink)
                        .lineLimit(1)

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
                    .buttonStyle(.plain)
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

            Button {
                move(by: 1)
            } label: {
                Label("下一题", systemImage: "chevron.right")
            }
            .buttonStyle(.plain)
            .foregroundStyle(PokerTheme.ink)
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
                Text("Hero \(quiz.heroHand)")
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(PokerTheme.ink)
                Text("vs \(quiz.villainHand)  ·  Board \(quiz.board)")
                    .font(.subheadline.monospaced())
                    .foregroundStyle(PokerTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
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
                    .buttonStyle(.plain)
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
