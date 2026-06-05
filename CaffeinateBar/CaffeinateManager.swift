import Foundation
import Combine

class CaffeinateManager: ObservableObject {
    @Published var isActive: Bool = false
    @Published var elapsedSeconds: Int = 0

    private var process: Process?
    private var timer: AnyCancellable?

    func enable() {
        guard !isActive else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = ["-d"]
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isActive = false
                self?.stopTimer()
            }
        }
        do {
            try p.run()
            process = p
            elapsedSeconds = 0
            isActive = true
            startTimer()
        } catch {
            print("Failed to start caffeinate: \(error)")
        }
    }

    func disable() {
        process?.terminate()
        process = nil
        isActive = false
        stopTimer()
    }

    func toggle() {
        isActive ? disable() : enable()
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedSeconds += 1
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
        elapsedSeconds = 0
    }

    deinit { disable() }
}
