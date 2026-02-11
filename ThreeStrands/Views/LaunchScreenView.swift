import SwiftUI

struct LaunchScreenView: View {
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
    }
}
