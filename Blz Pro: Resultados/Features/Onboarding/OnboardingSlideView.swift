import SwiftUI

struct OnboardingSlide {
    let imageName: String
    let accentGradient: LinearGradient
    let title: String
    let subtitle: String
}

struct OnboardingSlideView: View {
    let slide: OnboardingSlide

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Gradient background — always visible; acts as fallback before images are added
                slide.accentGradient
                    .frame(width: geo.size.width, height: geo.size.height)

                // Full-screen image — silently empty until asset is added to the catalog
                Image(slide.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                // Readability gradient over the image
                LinearGradient(
                    colors: [.clear, .black.opacity(0.45), .black.opacity(0.88)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: geo.size.height)

                // Text block at the bottom
                VStack(alignment: .leading, spacing: 10) {
                    Text(slide.title)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(slide.subtitle)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.bottom, 164)
            }
        }
        .ignoresSafeArea()
    }
}
