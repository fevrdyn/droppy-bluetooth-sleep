import AppKit
import Combine
import DroppyKit
import SwiftUI

// MARK: - Entry point

@objc(BluetoothSleepPrincipal)
public final class BluetoothSleepPrincipal: NSObject, DropletPrincipal {
    public override init() { super.init() }
    @MainActor public func makeDroplet() -> AnyObject { BluetoothSleepDroplet() }
}

// MARK: - Bluetooth power (private IOBluetooth symbols, the same ones Bluesnooze relies on)

/// IOBluetoothPreference{Get,Set}ControllerPowerState are not public API.
/// They are resolved at runtime so a missing symbol degrades to "do nothing"
/// instead of a launch failure inside Droppy's process.
enum BluetoothPower {
    private typealias GetFn = @convention(c) () -> Int32
    private typealias SetFn = @convention(c) (Int32) -> Void

    private static func symbol(_ name: String) -> UnsafeMutableRawPointer? {
        guard let handle = dlopen("/System/Library/Frameworks/IOBluetooth.framework/IOBluetooth", RTLD_LAZY) else {
            return nil
        }
        return dlsym(handle, name)
    }

    /// nil means "could not read it", which callers must treat as "leave it alone".
    static var isOn: Bool? {
        guard let sym = symbol("IOBluetoothPreferenceGetControllerPowerState") else { return nil }
        return unsafeBitCast(sym, to: GetFn.self)() != 0
    }

    @discardableResult
    static func set(_ on: Bool) -> Bool {
        guard let sym = symbol("IOBluetoothPreferenceSetControllerPowerState") else { return false }
        unsafeBitCast(sym, to: SetFn.self)(on ? 1 : 0)
        return true
    }
}

// MARK: - Droplet

@MainActor
public final class BluetoothSleepDroplet: NSObject, ObservableObject, Droplet {
    public nonisolated static let id: DropletID = "bluetoothsleep"

    private enum Key {
        static let offOnSleep = "turnOffOnSleep"
        static let onOnWake = "turnOnOnWake"
        /// Persisted so a Droppy relaunch between sleep and wake still knows
        /// that *we* were the ones who switched Bluetooth off.
        static let switchedOffByUs = "switchedOffByUs"
    }

    private var host: DropletHost?
    private var observers: [NSObjectProtocol] = []

    @Published var turnOffOnSleep = true {
        didSet { host?.preferences.setValue(turnOffOnSleep, forKey: Key.offOnSleep) }
    }
    @Published var turnOnOnWake = true {
        didSet { host?.preferences.setValue(turnOnOnWake, forKey: Key.onOnWake) }
    }

    private var switchedOffByUs: Bool {
        get { host?.preferences.value(forKey: Key.switchedOffByUs, default: false) ?? false }
        set { host?.preferences.setValue(newValue, forKey: Key.switchedOffByUs) }
    }

    public func activate(host: DropletHost) throws {
        self.host = host
        turnOffOnSleep = host.preferences.value(forKey: Key.offOnSleep, default: true)
        turnOnOnWake = host.preferences.value(forKey: Key.onOnWake, default: true)

        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleSleep() }
        })
        observers.append(center.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleWake() }
        })

        // Droppy was relaunched while we still owed Bluetooth a "back on".
        if switchedOffByUs { handleWake() }
        host.log.info("bluetoothsleep activated")
    }

    public func deactivate() {
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach { center.removeObserver($0) }
        observers.removeAll()
        host = nil
    }

    // MARK: Sleep / wake

    private func handleSleep() {
        guard turnOffOnSleep else { return }
        // "Bluetooth already off before sleep is left alone and stays off on wake."
        guard BluetoothPower.isOn == true else { return }
        if BluetoothPower.set(false) {
            switchedOffByUs = true
            host?.log.info("bluetooth switched off for sleep")
        }
    }

    private func handleWake() {
        // "Only when Droppy was the one that switched it off."
        guard switchedOffByUs else { return }
        defer { switchedOffByUs = false }
        guard turnOnOnWake else { return }
        if BluetoothPower.isOn == false, BluetoothPower.set(true) {
            host?.log.info("bluetooth restored after wake")
        }
    }
}

// MARK: - Settings

extension BluetoothSleepDroplet: SettingsPaneProviding {
    public func makeSettingsPane(context: SettingsPaneContext) -> AnyView {
        AnyView(BluetoothSleepSettings(droplet: self))
    }

    public var settingsSearchEntries: [SettingsSearchEntry] {
        [
            SettingsSearchEntry(title: "Turn Bluetooth off when the Mac sleeps", keywords: ["bluetooth", "sleep", "headphones"]),
            SettingsSearchEntry(title: "Turn Bluetooth back on when the Mac wakes", keywords: ["bluetooth", "wake"]),
        ]
    }
}

struct BluetoothSleepSettings: View {
    @ObservedObject var droplet: BluetoothSleepDroplet

    var body: some View {
        DropletSettingsPane {
            DropletSettingsSection {
                VStack(alignment: .leading, spacing: 2) {
                    settingsSectionHeader("Settings")
                }
            } content: {
                DropletSettingsCard {
                    DropletToggleRow(
                        title: "Turn Bluetooth off when the Mac sleeps",
                        subtitle: "Bluetooth already off before sleep is left alone and stays off on wake.",
                        isOn: $droplet.turnOffOnSleep
                    )
                    DropletToggleRow(
                        title: "Turn Bluetooth back on when the Mac wakes",
                        subtitle: "Only when Droppy was the one that switched it off.",
                        isOn: $droplet.turnOnOnWake
                    )
                }
            }
        }
    }
}
