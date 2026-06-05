import Carbon.HIToolbox
import Foundation

/// Registers a global keyboard shortcut using the Carbon event system.
/// Default binding: ⌥⌘K — works system-wide without Accessibility permission.
final class HotkeyManager {

    var onHotkey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    /// Registers the default global shortcut ⌥⌘K.
    func register(virtualKey: Int = kVK_ANSI_K,
                  modifiers: UInt32 = UInt32(cmdKey | optionKey)) {

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  UInt32(kEventHotKeyPressed)
        )

        let selfPtr = UnsafeMutableRawPointer(
            Unmanaged.passUnretained(self).toOpaque()
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let userData else { return noErr }
                let hk = Unmanaged<HotkeyManager>.fromOpaque(userData)
                    .takeUnretainedValue()
                DispatchQueue.main.async { hk.onHotkey?() }
                return noErr
            },
            1, &eventSpec, selfPtr, &eventHandlerRef
        )

        var hotKeyID = EventHotKeyID(signature: 0x43414645, id: 1) // 'CAFE'
        RegisterEventHotKey(
            UInt32(virtualKey), modifiers,
            hotKeyID, GetApplicationEventTarget(),
            0, &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef   { UnregisterEventHotKey(ref);   hotKeyRef = nil }
        if let ref = eventHandlerRef { RemoveEventHandler(ref); eventHandlerRef = nil }
    }

    deinit { unregister() }
}
