import Foundation
import Observation

@MainActor
@Observable
final class AppSession {
    private let apiClient: APIClient

    var token: String?
    var user: AppUser?
    var dashboard: DashboardResponse?
    var scenarios: [PreflopScenario] = []
    var handQuizzes: [HandQuiz] = []
    var isLoading = false
    var errorMessage: String?
    var usesOfflineMock = false

    var isAuthenticated: Bool {
        token != nil && user != nil
    }

    init(apiClient: APIClient = .live) {
        self.apiClient = apiClient
    }

    func signIn(email: String, password: String) async {
        await runAuthTask(fallbackToOfflineDemo: true) {
            let payload = try await apiClient.login(email: email, password: password)
            applyAuth(payload)
            await loadHomeData()
        }
    }

    func register(name: String, email: String, password: String) async {
        await runAuthTask(fallbackToOfflineDemo: true) {
            let payload = try await apiClient.register(name: name, email: email, password: password)
            applyAuth(payload)
            await loadHomeData()
        }
    }

    func startOfflineDemo() {
        token = "offline-demo-token"
        user = MockFixtures.user
        dashboard = MockFixtures.dashboard
        scenarios = MockFixtures.scenarios
        handQuizzes = MockFixtures.handQuizzes
        usesOfflineMock = true
        errorMessage = nil
    }

    func signOut() {
        token = nil
        user = nil
        dashboard = nil
        scenarios = []
        handQuizzes = []
        usesOfflineMock = false
        errorMessage = nil
    }

    func loadHomeData() async {
        guard let token else { return }
        if usesOfflineMock {
            dashboard = MockFixtures.dashboard
            scenarios = MockFixtures.scenarios
            handQuizzes = MockFixtures.handQuizzes
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            dashboard = try await apiClient.dashboard(token: token)
            scenarios = try await apiClient.preflopScenarios(token: token)
            handQuizzes = try await apiClient.handQuizzes(token: token)
        } catch {
            errorMessage = error.localizedDescription
            dashboard = MockFixtures.dashboard
            scenarios = MockFixtures.scenarios
            handQuizzes = MockFixtures.handQuizzes
            usesOfflineMock = true
        }
    }

    func answerPreflop(_ scenario: PreflopScenario, action: PokerAction) async -> DecisionResult {
        guard let token, !usesOfflineMock else {
            return MockFixtures.result(for: scenario, action: action)
        }

        do {
            return try await apiClient.answerPreflop(scenarioId: scenario.id, action: action, token: token)
        } catch {
            return MockFixtures.result(for: scenario, action: action)
        }
    }

    func calculateOdds(heroHand: String, board: String, outs: Int) async -> OddsResponse {
        guard let token, !usesOfflineMock else {
            return MockFixtures.odds(heroHand: heroHand, board: board, outs: outs)
        }

        do {
            return try await apiClient.calculateOdds(heroHand: heroHand, board: board, outs: outs, token: token)
        } catch {
            return MockFixtures.odds(heroHand: heroHand, board: board, outs: outs)
        }
    }

    func createBattleSession(
        tableSize: Int,
        observerSeat: Int,
        startingStackBb: Double,
        mode: String,
        playerSeat: Int?
    ) async -> BattleSessionSnapshot? {
        guard let token, !usesOfflineMock else { return nil }

        do {
            let snapshot = try await apiClient.createBattleSession(
                tableSize: tableSize,
                observerSeat: observerSeat,
                startingStackBb: startingStackBb,
                mode: mode,
                playerSeat: playerSeat,
                token: token
            )
            return snapshot
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func battleSnapshot(sessionId: String, observerSeat: Int) async -> BattleSessionSnapshot? {
        guard let token, !usesOfflineMock else { return nil }

        do {
            return try await apiClient.battleSnapshot(sessionId: sessionId, observerSeat: observerSeat, token: token)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func battleHistory(sessionId: String, observerSeat: Int) async -> BattleHandHistorySnapshot? {
        guard let token, !usesOfflineMock else { return nil }

        do {
            return try await apiClient.battleHistory(sessionId: sessionId, observerSeat: observerSeat, token: token)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func battleHandSummaries(sessionId: String) async -> [BattleHandSummarySnapshot] {
        guard let token, !usesOfflineMock else { return [] }

        do {
            return try await apiClient.battleHandSummaries(sessionId: sessionId, token: token)
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    func advanceBattle(sessionId: String, observerSeat: Int, steps: Int = 1) async -> BattleSessionSnapshot? {
        guard let token, !usesOfflineMock else { return nil }

        do {
            return try await apiClient.advanceBattle(sessionId: sessionId, observerSeat: observerSeat, steps: steps, token: token)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func nextBattleHand(sessionId: String, observerSeat: Int) async -> BattleSessionSnapshot? {
        guard let token, !usesOfflineMock else { return nil }

        do {
            return try await apiClient.nextBattleHand(sessionId: sessionId, observerSeat: observerSeat, token: token)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func playerBattleAction(
        sessionId: String,
        observerSeat: Int,
        action: String,
        targetTotalBb: Double?
    ) async -> BattleSessionSnapshot? {
        guard let token, !usesOfflineMock else { return nil }

        do {
            return try await apiClient.playerBattleAction(
                sessionId: sessionId,
                observerSeat: observerSeat,
                action: action,
                targetTotalBb: targetTotalBb,
                token: token
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func applyAuth(_ payload: AuthPayload) {
        token = payload.token
        user = payload.user
        usesOfflineMock = false
    }

    private func runAuthTask(fallbackToOfflineDemo: Bool = false, _ operation: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await operation()
        } catch {
            if fallbackToOfflineDemo {
                startOfflineDemo()
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
}
