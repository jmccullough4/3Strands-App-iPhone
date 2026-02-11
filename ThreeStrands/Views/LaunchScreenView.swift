import SwiftUI

struct LaunchScreenView: View {
    // Logo animation states
    @State private var logoOffset: CGFloat = -600
    @State private var logoScale: CGFloat = 1.8
    @State private var logoLanded = false

    // Ripple ring states (5 concentric rings)
    @State private var ripple1Scale: CGFloat = 0.1
    @State private var ripple1Opacity: Double = 0
    @State private var ripple2Scale: CGFloat = 0.1
    @State private var ripple2Opacity: Double = 0
    @State private var ripple3Scale: CGFloat = 0.1
    @State private var ripple3Opacity: Double = 0
    @State private var ripple4Scale: CGFloat = 0.1
    @State private var ripple4Opacity: Double = 0
    @State private var ripple5Scale: CGFloat = 0.1
    @State private var ripple5Opacity: Double = 0

    // Splash droplets
    @State private var dropletsVisible = false

    // Screen flash on impact
    @State private var flashOpacity: Double = 0

    // Text reveal
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            // Base background
            Color.black.ignoresSafeArea()

            // Ripple rings (behind the logo)
            rippleRings

            // Impact flash
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()

            // Splash droplets
            if dropletsVisible {
                splashDroplets
            }

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Logo
                Image("Copper")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 188, height: 188)
                    .scaleEffect(logoScale)
                    .offset(y: logoOffset)
                    .shadow(color: logoLanded ? Theme.primary.opacity(0.6) : .clear, radius: logoLanded ? 30 : 0, y: 0)

                Spacer()

                // Scripture quote
                VStack(spacing: 8) {
                    Text("\"A cord of three strands is\nnot quickly broken.\"")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(Theme.bronzeGold)
                        .multilineTextAlignment(.center)

                    Text("Ecclesiastes 4:12")
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(textOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startWaterSlamAnimation()
        }
    }

    // MARK: - Ripple Rings

    private var rippleRings: some View {
        let center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - 40)

        return ZStack {
            // Ring 1 - innermost, fastest
            Circle()
                .stroke(Theme.primary.opacity(0.5), lineWidth: 2.5)
                .scaleEffect(ripple1Scale)
                .opacity(ripple1Opacity)
                .frame(width: 200, height: 200)
                .position(center)

            // Ring 2
            Circle()
                .stroke(Theme.bronze.opacity(0.4), lineWidth: 2.0)
                .scaleEffect(ripple2Scale)
                .opacity(ripple2Opacity)
                .frame(width: 200, height: 200)
                .position(center)

            // Ring 3
            Circle()
                .stroke(Theme.bronzeGold.opacity(0.35), lineWidth: 1.5)
                .scaleEffect(ripple3Scale)
                .opacity(ripple3Opacity)
                .frame(width: 200, height: 200)
                .position(center)

            // Ring 4
            Circle()
                .stroke(Theme.primary.opacity(0.25), lineWidth: 1.2)
                .scaleEffect(ripple4Scale)
                .opacity(ripple4Opacity)
                .frame(width: 200, height: 200)
                .position(center)

            // Ring 5 - outermost, slowest
            Circle()
                .stroke(Theme.bronze.opacity(0.15), lineWidth: 1.0)
                .scaleEffect(ripple5Scale)
                .opacity(ripple5Opacity)
                .frame(width: 200, height: 200)
                .position(center)
        }
        .ignoresSafeArea()
    }

    // MARK: - Splash Droplets

    private var splashDroplets: some View {
        let center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - 40)

        return ZStack {
            ForEach(0..<12, id: \.self) { i in
                SplashDroplet(
                    index: i,
                    center: center,
                    color: i % 2 == 0 ? Theme.primary : Theme.bronzeGold
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Animation Sequence

    private func startWaterSlamAnimation() {
        // Phase 1: Logo slams down from above (fast, heavy impact)
        withAnimation(.easeIn(duration: 0.35)) {
            logoOffset = 0
            logoScale = 1.0
        }

        // Phase 2: Impact effects at 0.35s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            logoLanded = true

            // Brief white flash on impact
            withAnimation(.easeOut(duration: 0.08)) {
                flashOpacity = 0.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.2)) {
                    flashOpacity = 0
                }
            }

            // Trigger splash droplets
            dropletsVisible = true

            // Logo bounce on impact
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                logoScale = 1.05
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7, blendDuration: 0)) {
                    logoScale = 1.0
                }
            }

            // Ripple 1 - immediate
            withAnimation(.easeOut(duration: 1.2)) {
                ripple1Scale = 4.0
            }
            withAnimation(Animation.easeOut(duration: 1.2)) {
                ripple1Opacity = 0.7
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.9)) {
                    ripple1Opacity = 0
                }
            }

            // Ripple 2 - 0.1s delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 1.3)) {
                    ripple2Scale = 4.5
                }
                withAnimation(Animation.easeOut(duration: 0.3)) {
                    ripple2Opacity = 0.6
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        ripple2Opacity = 0
                    }
                }
            }

            // Ripple 3 - 0.2s delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 1.4)) {
                    ripple3Scale = 5.0
                }
                withAnimation(Animation.easeOut(duration: 0.3)) {
                    ripple3Opacity = 0.5
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        ripple3Opacity = 0
                    }
                }
            }

            // Ripple 4 - 0.35s delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 1.5)) {
                    ripple4Scale = 5.5
                }
                withAnimation(Animation.easeOut(duration: 0.3)) {
                    ripple4Opacity = 0.4
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        ripple4Opacity = 0
                    }
                }
            }

            // Ripple 5 - 0.5s delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 1.6)) {
                    ripple5Scale = 6.0
                }
                withAnimation(Animation.easeOut(duration: 0.3)) {
                    ripple5Opacity = 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 1.1)) {
                        ripple5Opacity = 0
                    }
                }
            }
        }

        // Phase 3: Fade in the scripture text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.6)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Splash Droplet

struct SplashDroplet: View {
    let index: Int
    let center: CGPoint
    let color: Color
    let size: CGFloat
    let distance: CGFloat
    let burstDuration: Double
    let fallDelay: Double
    let fallDuration: Double
    let fallDistance: CGFloat

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1.0

    private var angle: Double {
        Double(index) * (360.0 / 12.0) * .pi / 180.0
    }

    init(index: Int, center: CGPoint, color: Color) {
        self.index = index
        self.center = center
        self.color = color
        self.size = CGFloat.random(in: 3...7)
        self.distance = CGFloat.random(in: 80...180)
        self.burstDuration = Double.random(in: 0.4...0.7)
        self.fallDelay = Double.random(in: 0.3...0.5)
        self.fallDuration = Double.random(in: 0.3...0.5)
        self.fallDistance = CGFloat.random(in: 30...60)
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(center)
            .offset(offset)
            .onAppear {
                // Burst outward
                withAnimation(.easeOut(duration: burstDuration)) {
                    offset = CGSize(
                        width: cos(angle) * distance,
                        height: sin(angle) * distance - 40
                    )
                    opacity = 0.8
                }

                // Fall and fade
                DispatchQueue.main.asyncAfter(deadline: .now() + fallDelay) {
                    withAnimation(.easeIn(duration: fallDuration)) {
                        offset.height += fallDistance
                        opacity = 0
                        scale = 0.3
                    }
                }
            }
    }
}
