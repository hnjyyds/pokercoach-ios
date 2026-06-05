import SwiftUI

struct PokerGlassBackdrop: View {
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

                var coolBand = Path()
                coolBand.move(to: CGPoint(x: -60, y: size.height * 0.18))
                coolBand.addCurve(
                    to: CGPoint(x: size.width + 60, y: size.height * 0.26),
                    control1: CGPoint(x: size.width * 0.26, y: size.height * 0.10),
                    control2: CGPoint(x: size.width * 0.68, y: size.height * 0.34)
                )
                coolBand.addLine(to: CGPoint(x: size.width + 60, y: size.height * 0.43))
                coolBand.addCurve(
                    to: CGPoint(x: -60, y: size.height * 0.36),
                    control1: CGPoint(x: size.width * 0.72, y: size.height * 0.37),
                    control2: CGPoint(x: size.width * 0.20, y: size.height * 0.49)
                )
                coolBand.closeSubpath()
                context.fill(
                    coolBand,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: "#EAF2FF").opacity(0.10),
                            Color(hex: "#DCE9FF").opacity(0.25),
                            Color.clear
                        ]),
                        startPoint: CGPoint(x: 0, y: size.height * 0.12),
                        endPoint: CGPoint(x: size.width, y: size.height * 0.46)
                    )
                )

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

                let clusterOrigin = CGPoint(x: size.width * 0.72, y: size.height * 0.34)
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

struct PokerPageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    var tint: Color = PokerTheme.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.black))
                Text(eyebrow)
                    .font(.caption.weight(.black))
            }
            .foregroundStyle(PokerTheme.ink)
            .padding(.horizontal, 2)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(tint)
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(PokerTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text(subtitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PokerTheme.muted)
                }
            }
        }
        .padding(.top, 4)
    }
}

struct CoachCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.title3)
                .frame(width: 28, height: 28)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption)
                .foregroundStyle(PokerTheme.muted)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TagPill: View {
    let title: String
    var tint: Color = PokerTheme.felt

    var body: some View {
        Text(title)
            .font(.caption.weight(.black))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
            .lineLimit(1)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(PokerTheme.felt)
            Text(title)
                .font(.headline)
                .foregroundStyle(PokerTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(PokerTheme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

struct PokerAmbientLayer: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                var table = Path()
                table.addEllipse(in: CGRect(
                    x: -size.width * 0.18,
                    y: size.height * 0.52,
                    width: size.width * 1.36,
                    height: size.height * 0.42
                ))
                context.fill(
                    table,
                    with: .radialGradient(
                        Gradient(colors: [
                            PokerTheme.felt.opacity(0.18),
                            PokerTheme.felt.opacity(0.06),
                            Color.clear
                        ]),
                        center: CGPoint(x: size.width * 0.50, y: size.height * 0.72),
                        startRadius: 16,
                        endRadius: size.width * 0.72
                    )
                )

                var orbit = Path()
                orbit.addEllipse(in: CGRect(
                    x: size.width * 0.05,
                    y: size.height * 0.60,
                    width: size.width * 0.90,
                    height: size.height * 0.23
                ))
                context.stroke(
                    orbit,
                    with: .color(PokerTheme.felt.opacity(0.12)),
                    style: StrokeStyle(lineWidth: 1.4, dash: [8, 14])
                )

                let chipColors = [
                    PokerTheme.violet,
                    PokerTheme.felt,
                    PokerTheme.amber,
                    PokerTheme.coral
                ]
                for index in chipColors.indices {
                    let phase = time * 0.50 + Double(index) * 0.72
                    let center = CGPoint(
                        x: size.width * (0.61 + CGFloat(index) * 0.075),
                        y: size.height * 0.83 + CGFloat(sin(phase)) * 4
                    )
                    let rect = CGRect(x: center.x - 14, y: center.y - 14, width: 28, height: 28)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                chipColors[index].opacity(0.22),
                                chipColors[index].opacity(0.09),
                                chipColors[index].opacity(0.02)
                            ]),
                            center: center,
                            startRadius: 2,
                            endRadius: 18
                        )
                    )
                    context.stroke(
                        Path(ellipseIn: rect.insetBy(dx: 4, dy: 4)),
                        with: .color(.white.opacity(0.22)),
                        lineWidth: 2
                    )
                }

                for index in 0..<3 {
                    var path = Path()
                    let y = size.height * (0.20 + CGFloat(index) * 0.18)
                    let offset = CGFloat(sin(time * 0.25 + Double(index))) * 10
                    path.move(to: CGPoint(x: -40, y: y + offset))
                    path.addCurve(
                        to: CGPoint(x: size.width + 40, y: y + 18 - offset),
                        control1: CGPoint(x: size.width * 0.24, y: y - 22),
                        control2: CGPoint(x: size.width * 0.78, y: y + 32)
                    )
                    context.stroke(path, with: .color(Color(hex: "#D8E4F2").opacity(0.30)), lineWidth: 1)
                }
            }
        }
    }
}

struct PlayingCardsRow: View {
    let cards: [String]
    var width: CGFloat = 42
    var height: CGFloat = 56
    var spacing: CGFloat = -7
    var rotation: Double = 3

    init(
        cardCodes: [String],
        width: CGFloat = 42,
        height: CGFloat = 56,
        spacing: CGFloat = -7,
        rotation: Double = 3
    ) {
        cards = cardCodes
        self.width = width
        self.height = height
        self.spacing = spacing
        self.rotation = rotation
    }

    init(
        cardText: String,
        width: CGFloat = 42,
        height: CGFloat = 56,
        spacing: CGFloat = -7,
        rotation: Double = 3
    ) {
        cards = CardVisualValue.codes(fromCardText: cardText)
        self.width = width
        self.height = height
        self.spacing = spacing
        self.rotation = rotation
    }

    init(
        handClass: String,
        width: CGFloat = 42,
        height: CGFloat = 56,
        spacing: CGFloat = -7,
        rotation: Double = 3
    ) {
        cards = CardVisualValue.codes(fromHandClass: handClass)
        self.width = width
        self.height = height
        self.spacing = spacing
        self.rotation = rotation
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                PlayingCardToken(code: card, width: width, height: height)
                    .rotationEffect(.degrees(rotation(for: index)))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        cards.isEmpty ? "扑克牌图形" : "\(cards.count) 张扑克牌图形"
    }

    private func rotation(for index: Int) -> Double {
        guard rotation != 0 else { return 0 }
        return index.isMultiple(of: 2) ? -rotation : rotation
    }
}

struct PlayingCardToken: View {
    let code: String
    var width: CGFloat = 42
    var height: CGFloat = 56

    init(text: String, width: CGFloat = 42, height: CGFloat = 56) {
        code = text
        self.width = width
        self.height = height
    }

    init(code: String, width: CGFloat = 42, height: CGFloat = 56) {
        self.code = code
        self.width = width
        self.height = height
    }

    var body: some View {
        let card = CardVisualValue(code: code)

        VStack(spacing: max(0, height * 0.02)) {
            Text(card.rank)
                .font(.system(size: max(11, width * 0.36), weight: .black, design: .rounded))
            Text(card.suit)
                .font(.system(size: max(10, width * 0.30), weight: .black, design: .rounded))
        }
        .foregroundStyle(card.tint)
        .frame(width: width, height: height)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: max(8, width * 0.23), style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: max(8, width * 0.23), style: .continuous)
                .stroke(.white.opacity(0.86), lineWidth: 1)
        }
        .shadow(color: Color(hex: "#071226").opacity(0.08), radius: 10, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("扑克牌图形")
    }
}

struct MiniCardFan: View {
    let codes: [String]
    var compact = false

    private var visibleCodes: [String] {
        Array(codes.prefix(compact ? 3 : 5))
    }

    var body: some View {
        HStack(spacing: compact ? -5 : -6) {
            ForEach(Array(visibleCodes.enumerated()), id: \.offset) { index, code in
                MiniPlayingCardToken(code: code, compact: compact)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -3 : 3))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        visibleCodes.isEmpty ? "扑克牌图形" : "\(visibleCodes.count) 张扑克牌图形"
    }
}

private struct MiniPlayingCardToken: View {
    let code: String
    let compact: Bool

    var body: some View {
        let card = CardVisualValue(code: code)
        let width: CGFloat = compact ? 13 : 17
        let height: CGFloat = compact ? 18 : 24

        VStack(spacing: 0) {
            Text(card.rank)
                .font(.system(size: compact ? 7 : 9, weight: .black, design: .rounded))
            Text(card.suit)
                .font(.system(size: compact ? 6 : 8, weight: .black, design: .rounded))
        }
        .foregroundStyle(card.tint)
        .frame(width: width, height: height)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: compact ? 4 : 5, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: compact ? 4 : 5, style: .continuous)
                .stroke(.white.opacity(0.86), lineWidth: 0.7)
        }
        .shadow(color: Color(hex: "#071226").opacity(0.08), radius: compact ? 5 : 7, y: compact ? 2 : 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("扑克牌图形")
    }
}

private struct CardVisualValue {
    let rank: String
    let suit: String
    let tint: Color
    let accessibilityLabel: String

    init(code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.replacingOccurrences(of: "10", with: "T").uppercased()
        let rankCode = String(normalized.dropLast())
        let suitCode = normalized.suffix(1).lowercased()
        let suitName: String

        rank = rankCode == "T" ? "10" : (rankCode.isEmpty ? "?" : rankCode)
        switch suitCode {
        case "h":
            suit = "♥"
            tint = PokerTheme.coral
            suitName = "红桃"
        case "d":
            suit = "♦"
            tint = PokerTheme.coral
            suitName = "方片"
        case "c":
            suit = "♣"
            tint = PokerTheme.ink
            suitName = "梅花"
        default:
            suit = "♠"
            tint = PokerTheme.ink
            suitName = "黑桃"
        }
        accessibilityLabel = "\(rank) \(suitName)"
    }

    static func codes(fromCardText text: String) -> [String] {
        let parsedCodes = explicitCodes(from: normalizedCardText(text))
        if !parsedCodes.isEmpty {
            return parsedCodes
        }
        return codes(fromHandClass: text)
    }

    static func codes(fromHandClass handClass: String) -> [String] {
        let normalized = handClass.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalized.count >= 2 else { return [] }
        let ranks = normalized.filter { "23456789TJQKA".contains($0) }
        guard ranks.count >= 2 else { return [] }
        let first = String(ranks[ranks.startIndex])
        let second = String(ranks[ranks.index(after: ranks.startIndex)])
        if first == second {
            return ["\(first)s", "\(second)h"]
        }
        if normalized.hasSuffix("S") {
            return ["\(first)s", "\(second)s"]
        }
        return ["\(first)s", "\(second)h"]
    }

    private static func normalizedCardText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "10", with: "T")
            .replacingOccurrences(of: "♠", with: "s")
            .replacingOccurrences(of: "♥", with: "h")
            .replacingOccurrences(of: "♦", with: "d")
            .replacingOccurrences(of: "♣", with: "c")
            .uppercased()
    }

    private static func explicitCodes(from text: String) -> [String] {
        var codes: [String] = []
        var pendingRank: Character?

        for character in text {
            if "23456789TJQKA".contains(character) {
                pendingRank = character
                continue
            }

            if "SHDC".contains(character), let rank = pendingRank {
                codes.append("\(rank)\(String(character).lowercased())")
            }

            pendingRank = nil
        }

        return codes
    }
}
