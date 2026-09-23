import SwiftUI

extension Notification.Name {
    static let showOnboardingRequested = Notification.Name("CaffeinateBar.showOnboardingRequested")
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let tint: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(symbol: "cup.and.saucer.fill", tint: .orange,
        title: "Welcome to CaffeinateBar",
        message: "Keep your Mac awake, right from the menu bar — no windows, no clutter."),
    OnboardingPage(symbol: "moon.zzz.fill", tint: .yellow,
        title: "Choose What Stays Awake",
        message: "Open ASSERTIONS to pick exactly what Caffeinate prevents from sleeping: display, system idle, disk, or the whole system."),
    OnboardingPage(symbol: "clock.fill", tint: .blue,
        title: "Set an Auto-Stop Timer",
        message: "Open TIMEOUT to make Caffeinate turn itself off after a set time — no need to remember to disable it."),
    OnboardingPage(symbol: "square.grid.2x2.fill", tint: .green,
        title: "Check Status From Your Desktop",
        message: "Add the CaffeinateBar widget to see your status at a glance, and toggle Caffeinate on or off right from it."),
    OnboardingPage(symbol: "heart.fill", tint: .pink,
        title: "Enjoying CaffeinateBar?",
        message: "Find the SUPPORT section any time to leave the developer a tip.")
]

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var pageIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            OnboardingPageView(page: onboardingPages[pageIndex])
                .id(pageIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))
                .frame(height: 300)

            pageIndicator
                .padding(.bottom, 16)

            controls
                .padding(.horizontal, 28)
                .padding(.bottom, 22)
        }
        .frame(width: 480)
        .animation(.easeInOut(duration: 0.25), value: pageIndex)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(onboardingPages.indices, id: \.self) { index in
                Circle()
                    .fill(index == pageIndex ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var controls: some View {
        HStack {
            if pageIndex < onboardingPages.count - 1 {
                Button("Skip") { onFinish() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Next") { pageIndex += 1 }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            } else {
                Spacer()
                Button("Get Started") { onFinish() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            ZStack {
                Circle().fill(page.tint.opacity(0.15)).frame(width: 84, height: 84)
                Image(systemName: page.symbol)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(page.tint)
            }
            Text(page.title)
                .font(.title2).fontWeight(.semibold)
                .multilineTextAlignment(.center)
            Text(page.message)
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer(minLength: 0)
        }
        .padding(.top, 28)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
