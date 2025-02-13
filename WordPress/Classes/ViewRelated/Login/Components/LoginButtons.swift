import SwiftUI

struct LoginButtonText: View {
    let text: String

    var body: some View {
        Spacer()
        Text(text)
            .font(.body)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        Spacer()
    }
}

struct LoginButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LoginButtonText(text: text)
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle)
        .padding(.horizontal)
    }
}

struct SecondaryLoginButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LoginButtonText(text: text)
        }
        .controlSize(.large)
        .buttonStyle(.bordered)
        .padding(.horizontal)
    }
}
