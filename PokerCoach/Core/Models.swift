import Foundation

enum PokerAction: String, Codable, CaseIterable, Identifiable {
    case fold
    case call
    case raise
    case check
    case bet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fold: "弃牌"
        case .call: "跟注"
        case .raise: "加注"
        case .check: "过牌"
        case .bet: "下注"
        }
    }

    var systemImage: String {
        switch self {
        case .fold: "xmark.circle"
        case .call: "hand.tap"
        case .raise: "arrow.up.circle"
        case .check: "checkmark.circle"
        case .bet: "plus.circle"
        }
    }
}

struct AppUser: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
    let level: String
    let streakDays: Int
    let skillScore: Int
}

struct AuthPayload: Codable {
    let token: String
    let user: AppUser
}

struct AuthRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
}

struct ModuleCard: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let progress: Double
    let icon: String
    let accent: String
}

struct DailyPlan: Codable, Hashable {
    let title: String
    let targetMinutes: Int
    let completedMinutes: Int
    let focus: String
    let modules: [ModuleCard]

    var progress: Double {
        guard targetMinutes > 0 else { return 0 }
        return min(Double(completedMinutes) / Double(targetMinutes), 1)
    }
}

struct DashboardResponse: Codable, Hashable {
    let user: AppUser
    let dailyPlan: DailyPlan
    let recentMistakes: [String]
    let nextDrillId: String
}

struct Choice: Codable, Identifiable, Hashable {
    var id: String { "\(action.rawValue)-\(sizing ?? "base")" }
    let action: PokerAction
    let label: String
    let sizing: String?
}

struct PreflopScenario: Codable, Identifiable, Hashable {
    let id: String
    let position: String
    let hand: String
    let tableState: String
    let villainAction: String
    let stackDepthBb: Int
    let potBb: Double
    let choices: [Choice]
    let recommendedAction: PokerAction
    let recommendedSizing: String
    let conceptTags: [String]
    let explanation: String
}

struct AnswerRequest: Encodable {
    let action: PokerAction
}

struct HandQuiz: Codable, Identifiable, Hashable {
    let id: String
    let heroHand: String
    let villainHand: String
    let board: String
    let question: String
    let options: [String]
    let answer: String
    let explanation: String
}

struct DecisionResult: Codable, Hashable {
    let isCorrect: Bool
    let recommendation: String
    let explanation: String
    let conceptTags: [String]
    let nextPrompt: String
}

struct OddsRequest: Encodable {
    let heroHand: String
    let board: String
    let outs: Int
}

struct OddsResponse: Codable, Hashable {
    let heroHand: String
    let board: String
    let outs: Int
    let turnOrRiverProbability: Double
    let byRiverProbability: Double
    let coachingNote: String
    let isMock: Bool
}

struct BattleMistakeSummary: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let street: String
    let position: String
    let heroCards: [String]
    let board: [String]
    let userActionLabel: String
    let recommendedActionLabel: String
    let evDeltaBb: Double
    let icon: String
    let accent: String
    let createdAt: String
}

struct BattleMistakeDetail: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let street: String
    let position: String
    let heroCards: [String]
    let board: [String]
    let userActionLabel: String
    let recommendedActionLabel: String
    let evDeltaBb: Double
    let icon: String
    let accent: String
    let createdAt: String
    let ownerId: String
    let sessionId: String
    let handNumber: Int
    let actionId: String?
    let userAction: String
    let recommendedAction: String
    let userTotalBb: Double
    let recommendedTotalBb: Double
    let scenario: BattleMistakeScenario
    let candidates: [BattleMistakeCandidate]
    let whyWrong: String
    let correctPlay: String
    let coachMessages: [CoachMessageSnapshot]
}

struct BattleMistakeCandidate: Codable, Identifiable, Hashable {
    var id: String { "\(action)-\(targetTotalBb)-\(evBb)" }
    let action: String
    let label: String
    let targetTotalBb: Double
    let evBb: Double
    let weight: Double
    let isRecommended: Bool
    let reason: String
}

struct BattleMistakeScenario: Codable, Hashable {
    let sessionId: String
    let handNumber: Int
    let tableSize: Int
    let street: String
    let position: String
    let heroName: String
    let heroCards: [String]
    let board: [String]
    let potBb: Double
    let currentBetBb: Double
    let stackBb: Double
    let committedBb: Double
    let spr: Double
    let tableSeats: [BattleMistakeTableSeat]
    let tags: [String]
}

struct BattleMistakeTableSeat: Codable, Identifiable, Hashable {
    var id: Int { seatIndex }
    let seatIndex: Int
    let position: String
    let name: String
    let stackBb: Double
    let committedBb: Double
    let status: String
    let isHero: Bool
}

struct CoachMessageSnapshot: Codable, Identifiable, Hashable {
    let id: String
    let role: String
    let content: String
    let createdAt: String
}

struct CoachMessageRequestBody: Encodable {
    let message: String
}

enum BattleStreet: String, Codable, Hashable {
    case preflop
    case flop
    case turn
    case river
    case showdown
    case complete
}

enum BattleActionKind: String, Codable, Hashable {
    case blind
    case fold
    case check
    case call
    case bet
    case raise
    case allIn = "all_in"
}

enum BattleTableEventKind: String, Codable, Hashable {
    case handStart = "hand_start"
    case blindPosted = "blind_posted"
    case burn
    case dealFlop = "deal_flop"
    case dealTurn = "deal_turn"
    case dealRiver = "deal_river"
    case showdown
    case uncontested
    case handComplete = "hand_complete"
}

enum BattleReplayEventKind: String, Codable, Hashable {
    case table
    case action
}

struct BattleSessionCreateRequest: Encodable {
    let tableSize: Int
    let observerSeat: Int
    let startingStackBb: Double
    let mode: String
    let playerSeat: Int?
}

struct BattleAdvanceRequestBody: Encodable {
    let observerSeat: Int
    let steps: Int
}

struct BattleNextHandRequestBody: Encodable {
    let observerSeat: Int
}

struct BattlePlayerActionRequestBody: Encodable {
    let observerSeat: Int
    let action: String
    let targetTotalBb: Double?
}

struct BattleAgentProfile: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let style: String
    let avatarSeed: String
    let accent: String
    let bio: String
    let archetype: String
    let masteryLabel: String
    let gtoScore: Int
    let exploitScore: Int
    let postflopScore: Int
    let riskProfile: String
    let strategyTags: [String]
}

struct BattleDecisionSnapshot: Codable, Hashable {
    let candidates: [BattleDecisionCandidateSnapshot]
    let source: String
    let engine: String
    let equitySamples: Int
    let policyProfile: String
    let chosenAction: BattleActionKind?
    let chosenLabel: String?
    let chosenEvBb: Double?
    let bestAlternativeAction: BattleActionKind?
    let bestAlternativeLabel: String?
    let bestAlternativeEvBb: Double?
    let evDeltaBb: Double?
    let handClass: String
    let rangeBucket: String
    let rangeRole: String
    let rangeFrequency: Double
    let boardTexture: String
    let equity: Double?
    let potOdds: Double
    let spr: Double
    let pressure: Double
    let confidence: Double
    let recommendedTotalBb: Double
    let tags: [String]
    let summary: String
}

struct BattleDecisionCandidateSnapshot: Codable, Hashable {
    let action: BattleActionKind
    let label: String
    let targetTotalBb: Double
    let evBb: Double
    let weight: Double
    let isChosen: Bool
    let reason: String
}

struct BattleActionSnapshot: Codable, Hashable, Identifiable {
    let id: String
    let seatIndex: Int
    let position: String
    let agentId: String
    let agentName: String
    let street: BattleStreet
    let action: BattleActionKind
    let label: String
    let amountBb: Double
    let totalBetBb: Double
    let potBb: Double
    let equity: Double?
    let potOdds: Double?
    let note: String
    let decision: BattleDecisionSnapshot?
    let createdAt: String
}

struct BattleActionStreetSnapshot: Codable, Hashable, Identifiable {
    var id: BattleStreet { street }

    let street: BattleStreet
    let label: String
    let actions: [BattleActionSnapshot]
}

struct BattleSeatSnapshot: Codable, Hashable, Identifiable {
    var id: Int { index }

    let index: Int
    let agent: BattleAgentProfile
    let position: String
    let stackBb: Double
    let streetBetBb: Double
    let totalCommittedBb: Double
    let status: String
    let isDealer: Bool
    let isSmallBlind: Bool
    let isBigBlind: Bool
    let isObserver: Bool
    let isActive: Bool
    let isHuman: Bool
    let holeCards: [String]?
    let lastAction: BattleActionSnapshot?
}

struct BattleTaskSnapshot: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let accent: String
    let state: String
}

struct BattleSidePotSnapshot: Codable, Hashable {
    let amountBb: Double
    let eligibleSeats: [Int]
    let winners: [Int]
}

struct BattleResultSnapshot: Codable, Hashable {
    let winners: [Int]
    let summary: String
    let showdown: [String]
    let showdownDetails: [BattleShowdownHandSnapshot]
    let sidePots: [BattleSidePotSnapshot]
}

struct BattleShowdownHandSnapshot: Codable, Hashable, Identifiable {
    var id: Int { seatIndex }

    let seatIndex: Int
    let position: String
    let agentId: String
    let agentName: String
    let holeCards: [String]
    let madeHand: String
    let handRank: Int
    let isWinner: Bool
    let wonBb: Double
}

struct BattleTableEventSnapshot: Codable, Hashable, Identifiable {
    let id: String
    let event: BattleTableEventKind
    let street: BattleStreet
    let label: String
    let seatIndex: Int?
    let cards: [String]
    let burnCard: String?
    let potBb: Double
    let createdAt: String
}

struct BattleReplayEventSnapshot: Codable, Hashable, Identifiable {
    let id: String
    let sequence: Int
    let kind: BattleReplayEventKind
    let street: BattleStreet
    let label: String
    let createdAt: String
    let seatIndex: Int?
    let position: String?
    let agentId: String?
    let agentName: String?
    let actionId: String?
    let tableEventId: String?
    let action: BattleActionKind?
    let tableEvent: BattleTableEventKind?
    let cards: [String]
    let burnCard: String?
    let amountBb: Double
    let totalBetBb: Double
    let potBb: Double
    let equity: Double?
    let potOdds: Double?
    let note: String?
    let decision: BattleDecisionSnapshot?
}

struct BattleReviewInsightSnapshot: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let accent: String
    let seatIndex: Int?
    let actionId: String?
}

struct BattleHandSummarySnapshot: Codable, Hashable, Identifiable {
    let id: String
    let sessionId: String
    let handNumber: Int
    let board: [String]
    let winners: [Int]
    let summary: String
    let actionCount: Int
    let decisionCount: Int
    let replayCount: Int
    let completedAt: String
}

struct BattleSessionSummarySnapshot: Codable, Hashable, Identifiable {
    let id: String
    let tableSize: Int
    let handNumber: Int
    let street: BattleStreet
    let stageLabel: String
    let potBb: Double
    let activeSeat: Int?
    let completedHandCount: Int
    let isComplete: Bool
    let isSessionComplete: Bool
    let lastEventLabel: String
    let createdAt: String
    let updatedAt: String
}

struct BattleHandHistorySnapshot: Codable, Hashable, Identifiable {
    let id: String
    let sessionId: String
    let handNumber: Int
    let tableSize: Int
    let seed: String
    let street: BattleStreet
    let stageLabel: String
    let board: [String]
    let burnedCards: [String]
    let observerSeat: Int
    let seats: [BattleSeatSnapshot]
    let actionTimeline: [BattleActionStreetSnapshot]
    let tableEvents: [BattleTableEventSnapshot]
    let replayEvents: [BattleReplayEventSnapshot]
    let result: BattleResultSnapshot?
    let reviewInsights: [BattleReviewInsightSnapshot]
    let actionCount: Int
    let decisionCount: Int
    let isComplete: Bool
}

struct BattleSessionSnapshot: Codable, Hashable, Identifiable {
    let id: String
    let mode: String
    let playerSeat: Int?
    let tableSize: Int
    let handNumber: Int
    let street: BattleStreet
    let stageLabel: String
    let potBb: Double
    let currentBetBb: Double
    let minRaiseBb: Double
    let board: [String]
    let burnedCards: [String]
    let observerSeat: Int
    let activeSeat: Int?
    let seats: [BattleSeatSnapshot]
    let recentActions: [BattleActionSnapshot]
    let actionTimeline: [BattleActionStreetSnapshot]
    let tableEvents: [BattleTableEventSnapshot]
    let replayEvents: [BattleReplayEventSnapshot]
    let tasks: [BattleTaskSnapshot]
    let result: BattleResultSnapshot?
    let isComplete: Bool
    let isSessionComplete: Bool
}
