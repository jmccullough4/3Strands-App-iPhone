import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Theme.forestGreen
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                Image("Appicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .shadow(color: .black.opacity(0.3), radius: 15, y: 8)

                Text("3 Strands Cattle Co.")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.white)

                Spacer()

                VStack(spacing: 8) {
                    Text("\"A cord of three strands is\nnot quickly broken.\"")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(Theme.gold)
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
