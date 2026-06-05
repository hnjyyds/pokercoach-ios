import SwiftUI

struct OddsCalculatorView: View {
    @Environment(AppSession.self) private var session
    @State private var heroHand = "Ah Kh"
    @State private var board = "Th Jh 2c"
    @State private var outs = 9
    @State private var result: OddsResponse?
    @State private var isCalculating = false

    var body: some View {
        ZStack {
            PokerGlassBackdrop()
                .ignoresSafeArea()
            PokerAmbientLayer()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    inputSurface
                    resultSurface
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, PokerLayout.floatingTabBarClearance)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        PokerPageHeader(
            eyebrow: "快速计算权益",
            title: "Odds",
            subtitle: "输入牌面和 Outs",
            icon: "percent",
            tint: PokerTheme.ink
        )
    }

    private var inputSurface: some View {
        VStack(alignment: .leading, spacing: 18) {
            FreeformInput(icon: "suit.spade.fill", placeholder: "手牌，例如 Ah Kh", text: $heroHand)
            FreeformInput(icon: "tablecells.fill", placeholder: "公共牌，例如 Th Jh 2c", text: $board)

            HStack(spacing: 18) {
                Image(systemName: "scope")
                    .font(.title3.weight(.black))
                    .foregroundStyle(PokerTheme.felt)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Outs")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PokerTheme.muted)
                    Text("\(outs)")
                        .font(.system(size: 42, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(PokerTheme.ink)
                }

                Spacer()

                HStack(spacing: 14) {
                    Button {
                        outs = max(0, outs - 1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.headline.weight(.black))
                    }
                    .buttonStyle(OddsRoundButtonStyle())

                    Button {
                        outs = min(20, outs + 1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline.weight(.black))
                    }
                    .buttonStyle(OddsRoundButtonStyle(tint: PokerTheme.ink))
                }
            }

            Button {
                Task { await calculate() }
            } label: {
                if isCalculating {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 10) {
                        Text("计算")
                        Image(systemName: "x.squareroot")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    @ViewBuilder
    private var resultSurface: some View {
        if let result {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 26) {
                    OddsStat(title: "下一张", value: percent(result.turnOrRiverProbability), icon: "arrow.down.to.line", tint: PokerTheme.amber)
                    OddsStat(title: "到河牌", value: percent(result.byRiverProbability), icon: "water.waves", tint: PokerTheme.felt)
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(result.heroHand)  |  Board \(result.board)")
                        .font(.subheadline.monospaced().weight(.semibold))
                        .foregroundStyle(PokerTheme.ink)
                    Text(result.coachingNote)
                        .font(.subheadline)
                        .foregroundStyle(PokerTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func calculate() async {
        isCalculating = true
        result = await session.calculateOdds(heroHand: heroHand, board: board, outs: outs)
        isCalculating = false
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }
}

private struct FreeformInput: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(PokerTheme.muted)
                .frame(width: 26)

            TextField(placeholder, text: $text)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PokerTheme.ink)
                .pokerCharactersAutocapitalization()
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: "#D9E2ED").opacity(0.90))
                .frame(height: 1)
        }
    }
}

private struct OddsRoundButtonStyle: ButtonStyle {
    var tint: Color = PokerTheme.muted

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tint)
            .frame(width: 38, height: 38)
            .background(tint.opacity(configuration.isPressed ? 0.16 : 0.09), in: Circle())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private struct OddsStat: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.black))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 32, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(PokerTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PokerTheme.muted)
        }
    }
}

struct OddsCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        let session = AppSession()
        session.startOfflineDemo()
        return NavigationStack {
            OddsCalculatorView()
        }
        .environment(session)
    }
}
