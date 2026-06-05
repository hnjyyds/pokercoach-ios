import Foundation

struct APIClient {
    var baseURL: URL
    var urlSession: URLSession = .shared

    static let live = APIClient(baseURL: URL(string: "http://127.0.0.1:8000")!)

    func login(email: String, password: String) async throws -> AuthPayload {
        try await post("/auth/login", body: AuthRequest(email: email, password: password))
    }

    func register(name: String, email: String, password: String) async throws -> AuthPayload {
        try await post("/auth/register", body: RegisterRequest(name: name, email: email, password: password))
    }

    func dashboard(token: String) async throws -> DashboardResponse {
        try await get("/dashboard", token: token)
    }

    func preflopScenarios(token: String) async throws -> [PreflopScenario] {
        try await get("/training/preflop", token: token)
    }

    func handQuizzes(token: String) async throws -> [HandQuiz] {
        try await get("/training/hand-quiz", token: token)
    }

    func generateHandQuiz(focus: String, difficulty: String, street: String, token: String) async throws -> HandQuiz {
        try await post(
            "/training/hand-quiz/generate",
            body: HandQuizGenerateRequestBody(focus: focus, difficulty: difficulty, street: street),
            token: token
        )
    }

    func answerHandQuiz(id: String, answer: String, token: String) async throws -> DecisionResult {
        try await post(
            "/training/hand-quiz/\(id)/answer",
            body: HandQuizAnswerRequestBody(answer: answer),
            token: token
        )
    }

    func coachHandQuiz(id: String, message: String, token: String) async throws -> HandQuiz {
        try await post("/training/hand-quiz/\(id)/coach", body: CoachMessageRequestBody(message: message), token: token)
    }

    func mistakes(token: String) async throws -> [BattleMistakeSummary] {
        try await get("/training/mistakes", token: token)
    }

    func mistakeDetail(id: String, token: String) async throws -> BattleMistakeDetail {
        try await get("/training/mistakes/\(id)", token: token)
    }

    func coachMistake(id: String, message: String, token: String) async throws -> BattleMistakeDetail {
        try await post("/training/mistakes/\(id)/coach", body: CoachMessageRequestBody(message: message), token: token)
    }

    func answerPreflop(scenarioId: String, action: PokerAction, token: String) async throws -> DecisionResult {
        try await post("/training/preflop/\(scenarioId)/answer", body: AnswerRequest(action: action), token: token)
    }

    func calculateOdds(heroHand: String, board: String, outs: Int, token: String) async throws -> OddsResponse {
        try await post("/tools/odds", body: OddsRequest(heroHand: heroHand, board: board, outs: outs), token: token)
    }

    func createBattleSession(
        tableSize: Int,
        observerSeat: Int,
        startingStackBb: Double,
        mode: String,
        playerSeat: Int?,
        token: String
    ) async throws -> BattleSessionSnapshot {
        try await post(
            "/battle/sessions",
            body: BattleSessionCreateRequest(
                tableSize: tableSize,
                observerSeat: observerSeat,
                startingStackBb: startingStackBb,
                mode: mode,
                playerSeat: playerSeat
            ),
            token: token
        )
    }

    func battleSnapshot(sessionId: String, observerSeat: Int, token: String) async throws -> BattleSessionSnapshot {
        try await get("/battle/sessions/\(sessionId)?observer_seat=\(observerSeat)", token: token)
    }

    func battleHistory(sessionId: String, observerSeat: Int, token: String) async throws -> BattleHandHistorySnapshot {
        try await get("/battle/sessions/\(sessionId)/history?observer_seat=\(observerSeat)", token: token)
    }

    func battleHandSummaries(sessionId: String, token: String) async throws -> [BattleHandSummarySnapshot] {
        try await get("/battle/sessions/\(sessionId)/hands", token: token)
    }

    func battleSessions(token: String) async throws -> [BattleSessionSummarySnapshot] {
        try await get("/battle/sessions", token: token)
    }

    func advanceBattle(sessionId: String, observerSeat: Int, steps: Int, token: String) async throws -> BattleSessionSnapshot {
        try await post(
            "/battle/sessions/\(sessionId)/advance",
            body: BattleAdvanceRequestBody(observerSeat: observerSeat, steps: steps),
            token: token
        )
    }

    func nextBattleHand(sessionId: String, observerSeat: Int, token: String) async throws -> BattleSessionSnapshot {
        try await post(
            "/battle/sessions/\(sessionId)/next-hand",
            body: BattleNextHandRequestBody(observerSeat: observerSeat),
            token: token
        )
    }

    func playerBattleAction(
        sessionId: String,
        observerSeat: Int,
        action: String,
        targetTotalBb: Double?,
        token: String
    ) async throws -> BattleSessionSnapshot {
        try await post(
            "/battle/sessions/\(sessionId)/player-action",
            body: BattlePlayerActionRequestBody(
                observerSeat: observerSeat,
                action: action,
                targetTotalBb: targetTotalBb
            ),
            token: token
        )
    }

    private func get<T: Decodable>(_ path: String, token: String? = nil) async throws -> T {
        try await request(path, method: "GET", token: token, body: Optional<Data>.none)
    }

    private func post<T: Decodable, Body: Encodable>(_ path: String, body: Body, token: String? = nil) async throws -> T {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(body)
        return try await request(path, method: "POST", token: token, body: data)
    }

    private func request<T: Decodable>(_ path: String, method: String, token: String?, body: Data?) async throws -> T {
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        guard let url = URL(string: normalizedPath, relativeTo: baseURL)?.absoluteURL else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.server(status: httpResponse.statusCode, detail: Self.errorDetail(from: data))
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    private static func errorDetail(from data: Data) -> String? {
        guard !data.isEmpty,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let detail = object["detail"] else {
            return nil
        }

        if let message = detail as? String {
            return message
        }

        if let items = detail as? [[String: Any]] {
            return items.compactMap { item in
                if let message = item["msg"] as? String {
                    return message
                }
                if let message = item["message"] as? String {
                    return message
                }
                return nil
            }
            .joined(separator: "；")
            .nilIfEmpty
        }

        return nil
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(status: Int, detail: String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "服务地址格式异常"
        case .invalidResponse:
            "服务响应格式异常"
        case .server(let status, let detail):
            if let detail, !detail.isEmpty {
                "服务暂时不可用：\(detail)"
            } else {
                "服务暂时不可用，状态码 \(status)"
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
