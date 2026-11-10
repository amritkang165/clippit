// Purpose: Validate and persistable-model history shortcuts, replacing registrations only on success.
import AppKit
import Carbon

struct HistoryShortcut: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt
    static let `default` = HistoryShortcut(keyCode: 9, modifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue)
    static let keys: [UInt32: String] = [0:"A",1:"S",2:"D",3:"F",4:"H",5:"G",6:"Z",7:"X",8:"C",9:"V",
        11:"B",12:"Q",13:"W",14:"E",15:"R",16:"Y",17:"T",18:"1",19:"2",20:"3",21:"4",22:"6",23:"5",
        25:"9",26:"7",28:"8",29:"0",31:"O",32:"U",34:"I",35:"P",37:"L",38:"J",40:"K",45:"N",46:"M",
        49:"Space",122:"F1",120:"F2",99:"F3",118:"F4",96:"F5",97:"F6",98:"F7",100:"F8",
        101:"F9",109:"F10",103:"F11",111:"F12"]
    var flags: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifiers) }
    var isValid: Bool {
        let allowed: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
        return Self.keys[keyCode] != nil && !flags.intersection([.command, .control]).isEmpty
            && flags.subtracting(allowed).isEmpty
    }
    var display: String {
        (flags.contains(.control) ? "⌃" : "") + (flags.contains(.option) ? "⌥" : "")
        + (flags.contains(.shift) ? "⇧" : "") + (flags.contains(.command) ? "⌘" : "")
        + (Self.keys[keyCode] ?? "?")
    }
    var carbonModifiers: UInt32 {
        UInt32((flags.contains(.command) ? cmdKey : 0) | (flags.contains(.control) ? controlKey : 0)
            | (flags.contains(.option) ? optionKey : 0) | (flags.contains(.shift) ? shiftKey : 0))
    }
}

enum ShortcutError: LocalizedError {
    case invalid, unavailable(OSStatus)
    var errorDescription: String? {
        switch self {
        case .invalid: return "Choose a letter, number, Space or F1–F12 with Command or Control. Escape cancels recording."
        case .unavailable(let code): return "macOS could not register this shortcut (code \(code)). Try another combination. The previous shortcut is unchanged."
        }
    }
}

protocol ShortcutRegistration: AnyObject {}

@MainActor
final class HistoryShortcutController {
    typealias Register = (HistoryShortcut, @escaping () -> Void) throws -> ShortcutRegistration
    private let register: Register
    private let action: () -> Void
    private var registration: ShortcutRegistration?
    private(set) var current: HistoryShortcut?
    init(register: @escaping Register = { try CarbonShortcut($0, action: $1) }, action: @escaping () -> Void) {
        self.register = register
        self.action = action
    }
    func replace(with shortcut: HistoryShortcut) throws {
        guard shortcut.isValid else { throw ShortcutError.invalid }
        guard current != shortcut else { return }
        let newRegistration = try register(shortcut, action)
        registration = newRegistration // Releases/unregisters the old key only after the new key succeeds.
        current = shortcut
    }
}

private final class CarbonShortcut: ShortcutRegistration {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let identifier = EventHotKeyID(signature: 0x434C5054, id: UInt32.random(in: 1...UInt32.max))
    private let action: () -> Void

    init(_ shortcut: HistoryShortcut, action: @escaping () -> Void) throws {
        self.action = action
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<CarbonShortcut>.fromOpaque(context).takeUnretainedValue()
            var identifier = EventHotKeyID()
            guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                    nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier) == noErr,
                  identifier.signature == owner.identifier.signature, identifier.id == owner.identifier.id else {
                return OSStatus(eventNotHandledErr)
            }
            owner.action()
            return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard status == noErr else { throw ShortcutError.unavailable(status) }
        let result = RegisterEventHotKey(shortcut.keyCode, shortcut.carbonModifiers, identifier,
                                         GetApplicationEventTarget(), 0, &hotKey)
        if result != noErr {
            if let handler { RemoveEventHandler(handler) }
            handler = nil
            throw ShortcutError.unavailable(result)
        }
    }
    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }
}
