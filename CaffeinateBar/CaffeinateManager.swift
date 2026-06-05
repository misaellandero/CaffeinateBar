import Foundation
import Combine

/// Timeout presets shown in the UI.
enum TimeoutPreset: Int, CaseIterable, Identifiable {
    case none     = 0
    case fifteen  = 900
    case thirty   = 1800
    case oneHour  = 3600
    case twoHours = 7200
    case fourHours = 14400
    case eightHours = 28800

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .none:       return "No timeout"
        case .fifteen:    return "15 minutes"
        case .thirty:     return "30 minutes"
        case .oneHour:    return "1 hour"
        case .twoHours:   return "2 hours"
        case .fourHours:  return "4 hours"
        case .eightHours: return "8 hours"
        }
    }
}

class CaffeinateManager: ObservableObject {

    // MARK: - Assertion flags (persisted)
    @Published var flagDisplay: Bool {
        didSet { UserDefaults.standard.set(flagDisplay, forKey: "flagDisplay") }
    }
    /// -i  Prevent idle sleep
    @Published var flagIdle: Bool {
        didSet { UserDefaults.standard.set(flagIdle, forKey: "flagIdle") }
    }
    /// -m  Prevent disk idle sleep
    @Published var flagDisk: Bool {
        didSet { UserDefaults.standard.set(flagDisk, forKey: "flagDisk") }
    }
    /// -s  Prevent system sleep (AC power only)
    @Published var flagSystem: Bool {
        didSet { UserDefaults.standard.set(flagSystem, forKey: "flagSystem") }
    }
    /// -t  Timeout preset
    @Published var timeoutPreset: TimeoutPreset {
        didSet { UserDefaults.standard.set(timeoutPreset.rawValue, forKey: "timeoutPreset") }
    }

    // MARK: - Runtime state
    @Published var isActive: Bool = false
    @Published var elapsedSeconds: Int = 0

    private var process: Process?
    private var timer: AnyCancellable?

    // MARK: - Init

    init() {
        let d = UserDefaults.standard
        flagDisplay = d.object(forKey: "flagDisplay") as? Bool ?? true
        flagIdle    = d.object(forKey: "flagIdle")    as? Bool ?? false
        flagDisk    = d.object(forKey: "flagDisk")    as? Bool ?? false
        flagSystem  = d.object(forKey: "flagSystem")  as? Bool ?? false
        let raw = d.object(forKey: "timeoutPreset") as? Int ?? 0
        timeoutPreset = TimeoutPreset(rawValue: raw) ?? .none
    }

    // MARK: - Computed

    /// The arguments that will be (or are being) passed to caffeinate.
    var arguments: [String] {
        var args: [String] = []
        if flagDisplay { args.append("-d") }
        if flagIdle    { args.append("-i") }
        if flagDisk    { args.append("-m") }
        if flagSystem  { args.append("-s") }
        // Fall back to -i if no assertion is selected
        if args.isEmpty { args.append("-i") }
        if timeoutPreset != .none {
            args += ["-t", String(timeoutPreset.rawValue)]
        }
        return args
    }

    /// Human-readable command preview.
    var commandPreview: String {
        "caffeinate \(arguments.joined(separator: " "))"
    }

    var hasAnyFlag: Bool {
        flagDisplay || flagIdle || flagDisk || flagSystem
    }

    // MARK: - Control

    func enable() {
        guard !isActive else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = arguments
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

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.elapsedSeconds += 1 }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
        elapsedSeconds = 0
    }

    deinit { disable() }
}
