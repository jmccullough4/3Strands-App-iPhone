import SwiftUI

struct LaunchScreenView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOffset: CGFloat = 0
    @State private var phase: AnimationPhase = .growing

    private enum AnimationPhase {
        case growing, slamming, landed
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("Copper")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 188, height: 188)
                    .scaleEffect(logoScale)
                    .offset(y: logoOffset)
                    .shadow(color: .black.opacity(0.3), radius: 15, y: 8)

                Spacer()

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
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Phase 1: Grow from small to huge (off screen)
            withAnimation(.easeIn(duration: 0.8)) {
                logoScale = 3.5
            }

            // Phase 2: Snap off screen, then slam down to center
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // Instantly move above the screen while still huge
                logoScale = 2.0
                logoOffset = -UIScreen.main.bounds.height

                // Slam down into place
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)) {
                    logoScale = 1.0
                    logoOffset = 0
                }
            }
        }
    }
}
