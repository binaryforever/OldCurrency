//
//  VortexSplashView.swift
//  OldCurrency
//

import SwiftUI

private struct CurrencyParticle: Identifiable {
    let id: Int
    let code: String
    let initialAngle: Double
    let radius: Double
    let orbitSpeed: Double
    let fontSize: Double
    let color: Color
    let phaseOffset: Double
}

private let particleColors: [Color] = [
    .yellow, .orange, .mint, .cyan, .teal,
    .green, .pink, .purple, .indigo, .blue
]

struct VortexSplashView: View {
    private let particles: [CurrencyParticle] = supportedCurrencies.enumerated().map { i, code in
        CurrencyParticle(
            id: i,
            code: code,
            initialAngle: Double(i) / Double(supportedCurrencies.count) * .pi * 2,
            radius: 80 + Double(i % 7) * 14,
            orbitSpeed: 0.4 + Double(i % 5) * 0.08,
            fontSize: 11 + Double(i % 4) * 2,
            color: particleColors[i % particleColors.count],
            phaseOffset: Double(i) / Double(supportedCurrencies.count)
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    let cx = size.width / 2
                    let cy = size.height / 2

                    for p in particles {
                        let cycleLength: Double = 3.0
                        let phase = (elapsed * 0.25 + p.phaseOffset).truncatingRemainder(dividingBy: 1.0)
                        let angle = p.initialAngle + elapsed * p.orbitSpeed
                        let shrink = 1.0 - phase * 0.92
                        let r = p.radius * shrink
                        let alpha = (1.0 - phase * phase) * 0.9

                        let x = cx + cos(angle) * r
                        let y = cy + sin(angle) * r * 0.5

                        var text = Text(p.code)
                            .font(.system(size: p.fontSize * shrink, weight: .semibold, design: .monospaced))
                            .foregroundColor(p.color.opacity(alpha))

                        context.draw(text, at: CGPoint(x: x, y: y))
                    }

                    let glowSize = 28.0
                    let glowRect = CGRect(x: cx - glowSize, y: cy - glowSize, width: glowSize * 2, height: glowSize * 2)
                    context.fill(Path(ellipseIn: glowRect), with: .color(.yellow.opacity(0.25)))
                    let innerRect = CGRect(x: cx - 10, y: cy - 10, width: 20, height: 20)
                    context.fill(Path(ellipseIn: innerRect), with: .color(.white.opacity(0.6)))
                }
            }

            VStack(spacing: 0) {
                Spacer()
                Text("Historical Currency")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text("Conversion")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 60)
        }
    }
}

#Preview {
    VortexSplashView()
}
