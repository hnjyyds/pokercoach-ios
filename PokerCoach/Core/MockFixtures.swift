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

    static var mistakes: [BattleMistakeSummary] {
        mistakeDetails.map(summary)
    }

    static let mistakeDetails: [BattleMistakeDetail] = [
        BattleMistakeDetail(
            id: "seed_usr_demo_utg_kqo",
            title: "KQo 面对 UTG 加注",
            subtitle: "CO · Preflop · 反向隐含赔率",
            street: "preflop",
            position: "CO",
            heroCards: ["Kc", "Qd"],
            board: [],
            userActionLabel: "跟注",
            recommendedActionLabel: "弃牌",
            evDeltaBb: 1.1,
            icon: "suit.club.fill",
            accent: "#F59E0B",
            createdAt: "2026-06-05T00:00:00+00:00",
            ownerId: "usr_demo",
            sessionId: "seed_session",
            handNumber: 1,
            actionId: nil,
            userAction: "call",
            recommendedAction: "fold",
            userTotalBb: 2.5,
            recommendedTotalBb: 0,
            scenario: BattleMistakeScenario(
                sessionId: "seed_session",
                handNumber: 1,
                tableSize: 6,
                street: "preflop",
                position: "CO",
                heroName: "Alex",
                heroCards: ["Kc", "Qd"],
                board: [],
                potBb: 4,
                currentBetBb: 2.5,
                stackBb: 100,
                committedBb: 0,
                spr: 25,
                tableSeats: [
                    BattleMistakeTableSeat(seatIndex: 3, position: "UTG", name: "River", stackBb: 98, committedBb: 2.5, status: "active", isHero: false),
                    BattleMistakeTableSeat(seatIndex: 5, position: "CO", name: "Alex", stackBb: 100, committedBb: 0, status: "active", isHero: true)
                ],
                tags: ["CO", "KQo", "被主导", "高SPR"]
            ),
            candidates: [
                BattleMistakeCandidate(action: "fold", label: "弃牌", targetTotalBb: 0, evBb: 0.2, weight: 0.55, isRecommended: true, reason: "UTG 范围强，KQo 容易被 AQ/AK/KQs 主导。"),
                BattleMistakeCandidate(action: "call", label: "跟注", targetTotalBb: 2.5, evBb: -0.9, weight: 0.30, isRecommended: false, reason: "高 SPR 下反向隐含赔率变大，翻后容易支付强牌。"),
                BattleMistakeCandidate(action: "raise", label: "3-bet", targetTotalBb: 8, evBb: -0.3, weight: 0.15, isRecommended: false, reason: "阻断不足，面对 4-bet 难继续。")
            ],
            whyWrong: "KQo 看起来像高张强牌，但面对 UTG 紧范围，经常被 AK、AQ、QQ+ 主导；深筹码时跟注会把自己带进难打的大底池。",
            correctPlay: "新手阶段直接弃牌，保留筹码进入位置更好、范围更清晰的 spot。",
            coachMessages: [
                CoachMessageSnapshot(
                    id: "seed_msg_utg_1",
                    role: "agent",
                    content: "这手重点不是 KQ 漂亮，而是 UTG 范围太强。先把被主导风险排除，会少输很多大底池。",
                    createdAt: "2026-06-05T00:00:00+00:00"
                )
            ]
        ),
        BattleMistakeDetail(
            id: "seed_usr_demo_sb_defense",
            title: "小盲位宽跟注",
            subtitle: "SB · Preflop · 位置劣势",
            street: "preflop",
            position: "SB",
            heroCards: ["Qh", "8h"],
            board: [],
            userActionLabel: "跟注",
            recommendedActionLabel: "弃牌",
            evDeltaBb: 0.8,
            icon: "location.fill",
            accent: "#EF4444",
            createdAt: "2026-06-04T00:00:00+00:00",
            ownerId: "usr_demo",
            sessionId: "seed_session",
            handNumber: 2,
            actionId: nil,
            userAction: "call",
            recommendedAction: "fold",
            userTotalBb: 2.5,
            recommendedTotalBb: 0.5,
            scenario: BattleMistakeScenario(
                sessionId: "seed_session",
                handNumber: 2,
                tableSize: 6,
                street: "preflop",
                position: "SB",
                heroName: "Alex",
                heroCards: ["Qh", "8h"],
                board: [],
                potBb: 4,
                currentBetBb: 2.5,
                stackBb: 99.5,
                committedBb: 0.5,
                spr: 24.9,
                tableSeats: [
                    BattleMistakeTableSeat(seatIndex: 0, position: "BTN", name: "Nova", stackBb: 97.5, committedBb: 2.5, status: "active", isHero: false),
                    BattleMistakeTableSeat(seatIndex: 1, position: "SB", name: "Alex", stackBb: 99.5, committedBb: 0.5, status: "active", isHero: true),
                    BattleMistakeTableSeat(seatIndex: 2, position: "BB", name: "Ivy", stackBb: 99, committedBb: 1, status: "active", isHero: false)
                ],
                tags: ["SB", "Q8s", "位置劣势", "高SPR"]
            ),
            candidates: [
                BattleMistakeCandidate(action: "fold", label: "弃牌", targetTotalBb: 0.5, evBb: 0.1, weight: 0.50, isRecommended: true, reason: "小盲位翻后全程失位，边缘同花牌实现权益困难。"),
                BattleMistakeCandidate(action: "call", label: "跟注", targetTotalBb: 2.5, evBb: -0.7, weight: 0.34, isRecommended: false, reason: "容易形成被动多人池，翻后难以控池。"),
                BattleMistakeCandidate(action: "raise", label: "3-bet", targetTotalBb: 9, evBb: -0.2, weight: 0.16, isRecommended: false, reason: "阻断牌不足，面对继续范围权益不够。")
            ],
            whyWrong: "小盲位没有位置，Q8s 的同花潜力不足以弥补翻后实现权益差；跟注还会给大盲好价格进入底池。",
            correctPlay: "直接弃牌或只在明确 exploit 对手过度开池时低频 3-bet，不要默认平跟。",
            coachMessages: [
                CoachMessageSnapshot(
                    id: "seed_msg_sb_1",
                    role: "agent",
                    content: "小盲位先默认更紧。你要用更高质量的牌进入底池，因为翻后没有位置，错误会被放大。",
                    createdAt: "2026-06-04T00:00:00+00:00"
                )
            ]
        )
    ]

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

    static func reply(to id: String, message: String) -> BattleMistakeDetail? {
        guard let detail = mistakeDetails.first(where: { $0.id == id }) ?? mistakeDetails.first else {
            return nil
        }
        let userMessage = CoachMessageSnapshot(
            id: "mock_user_msg",
            role: "user",
            content: message,
            createdAt: "2026-06-05T00:00:00+00:00"
        )
        let agentMessage = CoachMessageSnapshot(
            id: "mock_agent_msg",
            role: "agent",
            content: "先看位置、底池和 SPR：这里推荐 \(detail.recommendedActionLabel)，不是因为两张牌一定差，而是你的动作让后续街道更难盈利。",
            createdAt: "2026-06-05T00:00:00+00:00"
        )
        return copy(detail, messages: detail.coachMessages + [userMessage, agentMessage])
    }

    private static func summary(_ detail: BattleMistakeDetail) -> BattleMistakeSummary {
        BattleMistakeSummary(
            id: detail.id,
            title: detail.title,
            subtitle: detail.subtitle,
            street: detail.street,
            position: detail.position,
            heroCards: detail.heroCards,
            board: detail.board,
            userActionLabel: detail.userActionLabel,
            recommendedActionLabel: detail.recommendedActionLabel,
            evDeltaBb: detail.evDeltaBb,
            icon: detail.icon,
            accent: detail.accent,
            createdAt: detail.createdAt
        )
    }

    private static func copy(_ detail: BattleMistakeDetail, messages: [CoachMessageSnapshot]) -> BattleMistakeDetail {
        BattleMistakeDetail(
            id: detail.id,
            title: detail.title,
            subtitle: detail.subtitle,
            street: detail.street,
            position: detail.position,
            heroCards: detail.heroCards,
            board: detail.board,
            userActionLabel: detail.userActionLabel,
            recommendedActionLabel: detail.recommendedActionLabel,
            evDeltaBb: detail.evDeltaBb,
            icon: detail.icon,
            accent: detail.accent,
            createdAt: detail.createdAt,
            ownerId: detail.ownerId,
            sessionId: detail.sessionId,
            handNumber: detail.handNumber,
            actionId: detail.actionId,
            userAction: detail.userAction,
            recommendedAction: detail.recommendedAction,
            userTotalBb: detail.userTotalBb,
            recommendedTotalBb: detail.recommendedTotalBb,
            scenario: detail.scenario,
            candidates: detail.candidates,
            whyWrong: detail.whyWrong,
            correctPlay: detail.correctPlay,
            coachMessages: messages
        )
    }
}
