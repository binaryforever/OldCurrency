//
//  VortexSplashView.swift
//  OldCurrency
//

import SwiftUI

private struct CurrencyParticle: Identifiable {
    let id: Int
    let code: String
    let symbol: String
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
            symbol: currencySymbols[code] ?? code,
            initialAngle: Double(i) / Double(supportedCurrencies.count) * .pi * 2,
            // How far out the symbols come in from
            radius: 300 + Double(i % 7) * 14,
            // Spin speed
            orbitSpeed: 0.2 + Double(i % 5) * 0.04,
            // Text font size
            fontSize: 60 + Double(i % 4) * 2,
            color: particleColors[i % particleColors.count],
            phaseOffset: Double(i) / Double(supportedCurrencies.count)
        )
    }

    var body: some View {
        ZStack {
            // Screen background colour
            Color(red: 1.0, green: 0.98, blue: 0.85).ignoresSafeArea()

            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    let cx = size.width / 2
                    let cy = size.height / 2
 
                    for p in particles {
                        let cycleLength: Double = 3.0
                        // Speed of travel to centre, and so time on screen
                        let phase = (elapsed * 0.25 + p.phaseOffset).truncatingRemainder(dividingBy: 1.0)
                        let angle = p.initialAngle + elapsed * p.orbitSpeed
                        let shrink = 1.0 - phase * 0.92
                        let r = p.radius * shrink
                        let alpha = (1.0 - phase * phase) * 0.9
 
                        let x = cx + cos(angle) * r
                        let y = cy + sin(angle) * r * 0.5
 
                        var text = Text(p.symbol)
                            .font(.system(size: p.fontSize * shrink, weight: .semibold, design: .monospaced))
                            .foregroundColor(p.color.opacity(alpha))
 
                        context.draw(text, at: CGPoint(x: x, y: y))
                    }
 
                }
            }
 
            VStack(spacing: 0) {
                Text("Historical Currency")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                Text("Conversion")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                Spacer()
                Text(Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "")
                    .font(.caption2)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
            }
            .padding(.top, 60)
        }
    }
}
 
#Preview {
    VortexSplashView()
}
