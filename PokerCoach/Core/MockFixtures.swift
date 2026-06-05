import Foundation

enum MockFixtures {
    static let user = AppUser(
        id: "usr_demo",
        name: "Alex",
        email: "alex@example.com",
        level: "新手进阶",
        streakDays: 6,
        skillScore: 684
    )

    static let dashboard = DashboardResponse(
        user: user,
        dailyPlan: DailyPlan(
            title: "今日 10 分钟训练",
            targetMinutes: 10,
            completedMinutes: 4,
            focus: "按钮位开放范围 + 大盲防守",
            modules: [
                ModuleCard(id: "preflop", title: "翻前范围", subtitle: "12 题情景决策", progress: 0.36, icon: "scope", accent: "#0F766E"),
                ModuleCard(id: "hand_quiz", title: "牌力识别", subtitle: "快速判断摊牌结果", progress: 0.62, icon: "suit.club.fill", accent: "#D97706"),
                ModuleCard(id: "odds", title: "赔率工具", subtitle: "outs 与补牌概率", progress: 0.18, icon: "percent", accent: "#DC2626")
            ]
        ),
        recentMistakes: [
            "面对 UTG 强范围时，高张非同花牌容易被主导。",
            "小盲位缺少位置优势，跟注范围需要更紧。"
        ],
        nextDrillId: "pf_001"
    )

    static let scenarios: [PreflopScenario] = [
        PreflopScenario(
            id: "pf_001",
            position: "BTN",
            hand: "A9s",
            tableState: "前面玩家全部弃牌",
            villainAction: "无人入池",
            stackDepthBb: 100,
            potBb: 1.5,
            choices: [
                Choice(action: .fold, label: "弃牌", sizing: nil),
                Choice(action: .call, label: "跟注", sizing: "1BB"),
                Choice(action: .raise, label: "加注", sizing: "2.5BB")
            ],
            recommendedAction: .raise,
            recommendedSizing: "2.5BB",
            conceptTags: ["位置优势", "偷盲", "同花A"],
            explanation: "按钮位面对无人入池时范围可以明显打开。A9s 有阻断强A、同花潜力和位置优势，标准策略是开放加注而不是 limp。"
        ),
        PreflopScenario(
            id: "pf_002",
            position: "CO",
            hand: "KQo",
            tableState: "UTG 加注到 2.5BB，其余弃牌",
            villainAction: "UTG open raise",
            stackDepthBb: 100,
            potBb: 4,
            choices: [
                Choice(action: .fold, label: "弃牌", sizing: nil),
                Choice(action: .call, label: "跟注", sizing: "2.5BB"),
                Choice(action: .raise, label: "3-bet", sizing: "8BB")
            ],
            recommendedAction: .fold,
            recommendedSizing: "-",
            conceptTags: ["反向隐含赔率", "位置", "范围压制"],
            explanation: "KQo 面对 UTG 强范围容易被 AK、AQ、QQ+ 压制。CO 位置还没有绝对优势，新手阶段建议先弃牌。"
        ),
        PreflopScenario(
            id: "pf_003",
            position: "BB",
            hand: "77",
            tableState: "BTN 加注到 2.5BB，SB 弃牌",
            villainAction: "BTN open raise",
            stackDepthBb: 80,
            potBb: 4,
            choices: [
                Choice(action: .fold, label: "弃牌", sizing: nil),
                Choice(action: .call, label: "防守跟注", sizing: "补 1.5BB"),
                Choice(action: .raise, label: "3-bet", sizing: "9BB")
            ],
            recommendedAction: .call,
            recommendedSizing: "补 1.5BB",
            conceptTags: ["盲注防守", "口袋对子", "成套价值"],
            explanation: "中小口袋对子在大盲面对按钮位宽范围时有足够权益防守。跟注能保留对手宽范围，击中暗三条时有很好的隐含赔率。"
        )
    ]

    static let handQuizzes: [HandQuiz] = [
        HandQuiz(
            id: "hq_001",
            heroHand: "Ah Kh",
            villainHand: "Qs Qd",
            board: "Th Jh 2c 3h 9s",
            question: "河牌摊牌谁赢？",
            options: ["Hero", "Villain", "平局"],
            answer: "Hero",
            explanation: "Hero 用 Ah Kh 和公共牌 Th Jh 3h 组成 A 高同花，击败 Villain 的一对 Q。"
        )
    ]

    static func result(for scenario: PreflopScenario, action: PokerAction) -> DecisionResult {
        DecisionResult(
            isCorrect: action == scenario.recommendedAction,
            recommendation: "\(scenario.recommendedAction.rawValue.uppercased()) \(scenario.recommendedSizing)",
            explanation: scenario.explanation,
            conceptTags: scenario.conceptTags,
            nextPrompt: action == scenario.recommendedAction ? "保持这个节奏，下一题会提高一点难度。" : "下一题会继续强化同一个概念。"
        )
    }

    static func odds(heroHand: String, board: String, outs: Int) -> OddsResponse {
        OddsResponse(
            heroHand: heroHand,
            board: board,
            outs: outs,
            turnOrRiverProbability: min(Double(outs) * 0.0217, 0.95),
            byRiverProbability: min(Double(outs) * 0.04, 0.95),
            coachingNote: "教学近似值：一张牌看 outs x 2%，两张牌看 outs x 4%。",
            isMock: true
        )
    }
}
