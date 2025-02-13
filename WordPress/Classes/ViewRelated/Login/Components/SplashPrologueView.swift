import SwiftUI

struct SplashPrologueView: View {

    @ScaledMetric(relativeTo: .largeTitle)
    var logoSize: CGFloat = 50

    var body: some View {
        ZStack {
            Color(SplashPrologueStyleGuide.backgroundColor)
            GeometryReader { proxy in
                Image("splashBrushStroke")
                    .resizable()
                    .scaledToFill()
                    .frame(width: Constants.splashBrushWidth)
                    .offset(x: (proxy.size.width - Constants.splashBrushWidth)/2)
                    .offset(x: Constants.splashBrushOffset.x, y: Constants.splashBrushOffset.y)
                    .foregroundColor(Color(SplashPrologueStyleGuide.BrushStroke.color))
                    .accessibility(hidden: true)
            }
            VStack {
                Spacer()
                Image("splashLogo")
                    .resizable()
                    .frame(width: logoSize, height: logoSize)
                    .padding(10)
                    .accessibility(hidden: true)
                Text(Self.caption)
                    .multilineTextAlignment(.center)
                    .font(SplashPrologueStyleGuide.Title.font)
                    .foregroundColor(Color(SplashPrologueStyleGuide.Title.textColor))
                    .padding(.horizontal)
                Spacer()
                Image("darkgrey-shadow")
                    .resizable(resizingMode: .tile)
                    .frame(height: 10)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    private struct Constants {
        static let splashBrushWidth: CGFloat = 179.3
        static let splashBrushOffset: CGPoint = .init(x: 98, y: -71)
    }
}

private extension SplashPrologueView {
    static let caption = NSLocalizedString(
        "wordpress.prologue.splash.caption",
        value: """
        Write, edit, and publish
        from anywhere.
        """,
        comment: "Caption displayed during the login flow."
    )
}

#Preview {
    SplashPrologueView()
}
