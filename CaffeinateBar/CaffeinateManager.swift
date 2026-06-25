import Foundation
import Combine
import IOKit.ps
import UserNotifications
import ServiceManagement
import StoreKit

// MARK: - TimeoutPreset

enum TimeoutPreset: Int, CaseIterable, Identifiable {
    case none       = 0
    case fifteen    = 900
    case thirty     = 1800
    case oneHour    = 3600
    case twoHours   = 7200
    case fourHours  = 14400
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

// MARK: - CaffeinateManager

class CaffeinateManager: ObservableObject {

    // MARK: Assertion flags

    @Published var flagDisplay: Bool { didSet { ud.set(flagDisplay, forKey: "flagDisplay") } }
    @Published var flagIdle:    Bool { didSet { ud.set(flagIdle,    forKey: "flagIdle")    } }
    @Published var flagDisk:    Bool { didSet { ud.set(flagDisk,    forKey: "flagDisk")    } }
    @Published var flagSystem:  Bool { didSet { ud.set(flagSystem,  forKey: "flagSystem")  } }
    @Published var timeoutPreset: TimeoutPreset {
        didSet { ud.set(timeoutPreset.rawValue, forKey: "timeoutPreset") }
    }

    // MARK: App settings

    @Published var launchAtLogin: Bool {
        didSet { applyLaunchAtLogin() }     // state of truth is SMAppService, not ud
    }
    @Published var activateOnLaunch: Bool {
        didSet { ud.set(activateOnLaunch, forKey: "activateOnLaunch") }
    }
    @Published var leftClickToToggle: Bool {
        didSet { ud.set(leftClickToToggle, forKey: "leftClickToToggle") }
    }
    @Published var globalHotkeyEnabled: Bool {
        didSet { ud.set(globalHotkeyEnabled, forKey: "globalHotkeyEnabled") }
    }
    /// Inverse alias of flagDisplay — not stored separately; flagDisplay is the source of truth.
    var allowScreenToSleep: Bool {
        get { !flagDisplay }
        set { flagDisplay = !newValue }
    }
    @Published var allowNotifications: Bool {
        didSet {
            ud.set(allowNotifications, forKey: "allowNotifications")
            if allowNotifications { requestNotificationPermission() }
        }
    }
    @Published var colorIcon: Bool {
        didSet { ud.set(colorIcon, forKey: "colorIcon") }
    }
    @Published var activateOnACPower: Bool {
        didSet {
            ud.set(activateOnACPower, forKey: "activateOnACPower")
            updatePowerMonitoring()
        }
    }
    @Published var deactivateOnUnplug: Bool {
        didSet {
            ud.set(deactivateOnUnplug, forKey: "deactivateOnUnplug")
            updatePowerMonitoring()
        }
    }

    // MARK: Runtime state

    @Published var isActive: Bool = false
    @Published var elapsedSeconds: Int = 0

    // MARK: Private

    private let ud = UserDefaults.standard
    private var process: Process?
    private var timer: AnyCancellable?
    private var powerRunLoopSource: CFRunLoopSource?
    private let ratingPrompt = RatingPromptController()

    // MARK: Init

    init() {
        flagDisplay   = ud.object(forKey: "flagDisplay")   as? Bool ?? true
        flagIdle      = ud.object(forKey: "flagIdle")      as? Bool ?? false
        flagDisk      = ud.object(forKey: "flagDisk")      as? Bool ?? false
        flagSystem    = ud.object(forKey: "flagSystem")    as? Bool ?? false
        timeoutPreset = TimeoutPreset(rawValue: ud.object(forKey: "timeoutPreset") as? Int ?? 0) ?? .none

        launchAtLogin       = SMAppService.mainApp.status == .enabled
        activateOnLaunch    = ud.object(forKey: "activateOnLaunch")    as? Bool ?? false
        leftClickToToggle   = ud.object(forKey: "leftClickToToggle")   as? Bool ?? false
        globalHotkeyEnabled = ud.object(forKey: "globalHotkeyEnabled") as? Bool ?? false
        allowNotifications  = ud.object(forKey: "allowNotifications")  as? Bool ?? false
        colorIcon           = ud.object(forKey: "colorIcon")           as? Bool ?? false
        activateOnACPower   = ud.object(forKey: "activateOnACPower")   as? Bool ?? false
        deactivateOnUnplug  = ud.object(forKey: "deactivateOnUnplug")  as? Bool ?? false

        updatePowerMonitoring()
    }

    // MARK: Computed

    var arguments: [String] {
        var args: [String] = []
        if flagDisplay { args.append("-d") }
        if flagIdle    { args.append("-i") }
        if flagDisk    { args.append("-m") }
        if flagSystem  { args.append("-s") }
        if args.isEmpty { args.append("-i") }
        if timeoutPreset != .none { args += ["-t", String(timeoutPreset.rawValue)] }
        return args
    }

    var commandPreview: String { "caffeinate \(arguments.joined(separator: " "))" }

    // MARK: Control

    func enable() {
        guard !isActive else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = arguments
        p.terminationHandler = { [weak self] finishedProcess in
            DispatchQueue.main.async {
                self?.handleCaffeinateProcessEnded(finishedProcess)
            }
        }
        do {
            try p.run()
            process = p
            elapsedSeconds = 0
            isActive = true
            startTimer()
            postNotification(active: true)
        } catch {
            print("caffeinate launch failed: \(error)")
        }
    }

    func disable() {
        let wasActive = isActive
        process?.terminate()
        process = nil
        if wasActive { completeActiveSession() }
        if wasActive { postNotification(active: false) }
    }

    func toggle() { isActive ? disable() : enable() }

    // MARK: Timer

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.elapsedSeconds += 1 }
    }

    private func stopTimer() {
        timer?.cancel(); timer = nil; elapsedSeconds = 0
    }

    private func handleCaffeinateProcessEnded(_ endedProcess: Process) {
        guard process === endedProcess else { return }
        process = nil
        completeActiveSession()
    }

    private func completeActiveSession() {
        guard isActive else { return }
        let sessionDuration = elapsedSeconds
        isActive = false
        stopTimer()
        ratingPrompt.recordCompletedSession(duration: sessionDuration)
    }

    // MARK: Launch at Login

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin { try SMAppService.mainApp.register()   }
            else             { try SMAppService.mainApp.unregister() }
        } catch {
            print("Launch at login: \(error.localizedDescription)")
        }
    }

    // MARK: Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func postNotification(active: Bool) {
        guard allowNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = active ? "Caffeinate Enabled ☕" : "Caffeinate Disabled 😴"
        content.body  = active
            ? "Mac will stay awake — \(arguments.joined(separator: " "))"
            : "Normal sleep behavior restored."
        content.sound = .default
        UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: UUID().uuidString,
                                       content: content, trigger: nil))
    }

    // MARK: Power Source Monitoring

    private func updatePowerMonitoring() {
        if activateOnACPower || deactivateOnUnplug {
            startPowerMonitoring()
        } else {
            stopPowerMonitoring()
        }
    }

    private func startPowerMonitoring() {
        guard powerRunLoopSource == nil else { return }
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        guard let src = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let mgr = Unmanaged<CaffeinateManager>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async { mgr.handlePowerChange() }
        }, ctx)?.takeRetainedValue() else { return }
        powerRunLoopSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
    }

    private func stopPowerMonitoring() {
        guard let src = powerRunLoopSource else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        powerRunLoopSource = nil
    }

    private func isOnACPower() -> Bool {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        guard let ref = IOPSGetProvidingPowerSourceType(info) else { return true }
        return (ref.takeUnretainedValue() as String) == kIOPSACPowerValue
    }

    private func handlePowerChange() {
        let onAC = isOnACPower()
        if activateOnACPower   && onAC  && !isActive { enable()  }
        if deactivateOnUnplug  && !onAC && isActive  { disable() }
    }

    deinit { disable(); stopPowerMonitoring() }
}

// MARK: - RatingPromptController

private final class RatingPromptController {
    private enum Key {
        static let firstLaunchDate = "rating.firstLaunchDate"
        static let meaningfulSessions = "rating.meaningfulSessions"
        static let totalActiveSeconds = "rating.totalActiveSeconds"
        static let lastRequestedVersion = "rating.lastRequestedVersion"
        static let lastRequestDate = "rating.lastRequestDate"
    }

    private let ud = UserDefaults.standard
    private let minimumSessionDuration = 120
    private let minimumMeaningfulSessions = 3
    private let minimumTotalActiveSeconds = 600
    private let minimumDaysSinceFirstLaunch: TimeInterval = 24 * 60 * 60
    private let minimumDaysBetweenRequests: TimeInterval = 90 * 24 * 60 * 60

    init() {
        if ud.object(forKey: Key.firstLaunchDate) == nil {
            ud.set(Date(), forKey: Key.firstLaunchDate)
        }
    }

    func recordCompletedSession(duration: Int) {
        guard duration > 0 else { return }

        let totalActiveSeconds = ud.integer(forKey: Key.totalActiveSeconds) + duration
        ud.set(totalActiveSeconds, forKey: Key.totalActiveSeconds)

        if duration >= minimumSessionDuration {
            let sessions = ud.integer(forKey: Key.meaningfulSessions) + 1
            ud.set(sessions, forKey: Key.meaningfulSessions)
        }

        requestReviewIfAppropriate()
    }

    private func requestReviewIfAppropriate() {
        guard hasEnoughRealUse else { return }
        guard hasNotRequestedThisVersion else { return }
        guard isOutsideCooldown else { return }

        ud.set(currentVersion, forKey: Key.lastRequestedVersion)
        ud.set(Date(), forKey: Key.lastRequestDate)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            SKStoreReviewController.requestReview()
        }
    }

    private var hasEnoughRealUse: Bool {
        let firstLaunchDate = ud.object(forKey: Key.firstLaunchDate) as? Date ?? Date()
        let appAge = Date().timeIntervalSince(firstLaunchDate)
        return appAge >= minimumDaysSinceFirstLaunch
            && ud.integer(forKey: Key.meaningfulSessions) >= minimumMeaningfulSessions
            && ud.integer(forKey: Key.totalActiveSeconds) >= minimumTotalActiveSeconds
    }

    private var hasNotRequestedThisVersion: Bool {
        ud.string(forKey: Key.lastRequestedVersion) != currentVersion
    }

    private var isOutsideCooldown: Bool {
        guard let lastRequestDate = ud.object(forKey: Key.lastRequestDate) as? Date else { return true }
        return Date().timeIntervalSince(lastRequestDate) >= minimumDaysBetweenRequests
    }

    private var currentVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version)-\(build)"
    }
}
