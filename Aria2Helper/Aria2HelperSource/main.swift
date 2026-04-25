import Foundation
import AppKit
import Aria2CoreLocal

class Aria2Launcher: NSObject, NSApplicationDelegate {
    // 现在直接使用顶级类名，无需命名空间
    private var core = aria2_manager.Aria2Core()
    private let groupName = "group.cn.saltpi.app.AriaX"
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        updateLanguage()
        startAria2()
        updateStatusItem()
        
        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("cn.saltpi.app.AriaX.SettingsChanged"), object: nil, queue: .main) { [weak self] _ in
            self?.updateLanguage()
            self?.updateStatusItem()
        }
    }

    private func updateLanguage() {
        guard let defaults = UserDefaults(suiteName: "group.cn.saltpi.app.AriaX"),
              let lang = defaults.string(forKey: "ariaNg_language") else { return }
        UserDefaults.standard.set([lang], forKey: "AppleLanguages")
    }

    func startAria2() {
        guard let defaults = UserDefaults(suiteName: groupName) else { return }
        defaults.synchronize()
        let port = Int32(defaults.integer(forKey: "internal_rpc_port"))
        let secret = defaults.string(forKey: "internal_rpc_secret") ?? ""
        let downloadDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0].path
        
        let sessionFilePath = (downloadDir as NSString).appendingPathComponent("aria2.session")
        if !FileManager.default.fileExists(atPath: sessionFilePath) {
            FileManager.default.createFile(atPath: sessionFilePath, contents: nil)
        }
        
        core.start(port, std.string(secret), std.string(downloadDir))
    }

    func updateStatusItem() {
        guard let defaults = UserDefaults(suiteName: groupName) else { return }
        defaults.synchronize()
        
        let showIcon = defaults.bool(forKey: "show_helper_status_bar_icon")
        
        if showIcon {
            if statusItem == nil {
                statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                if let button = statusItem?.button {
                    if let customImage = NSImage(named: "StatusBarIcon") {
                        customImage.isTemplate = true
                        button.image = customImage
                    } else {
                        button.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "AriaX Engine")
                    }
                }
            }
            setupMenu()
        } else {
            statusItem = nil
        }
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: localizedString("Open AriaX"), action: #selector(openMainApp), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: localizedString("AriaX Engine Running"), action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: localizedString("Quit Engine"), action: #selector(quitEngine), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc func quitEngine() {
        core.stop()
        NSApplication.shared.terminate(nil)
    }
    
    private func localizedString(_ key: String) -> String {
        guard let defaults = UserDefaults(suiteName: "group.cn.saltpi.app.AriaX"),
              let lang = defaults.string(forKey: "ariaNg_language") else {
            return NSLocalizedString(key, comment: "")
        }
        
        // Try exact match, then general language (e.g. zh-Hans -> zh-Hans, then zh)
        let languages = [lang, String(lang.prefix(2)), "en"]
        
        for l in languages {
            if let path = Bundle.main.path(forResource: l, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                let localized = bundle.localizedString(forKey: key, value: "~~NOT_FOUND~~", table: nil)
                if localized != "~~NOT_FOUND~~" {
                    return localized
                }
            }
        }
        
        return NSLocalizedString(key, comment: "")
    }

    @objc func openMainApp() {
        if let url = URL(string: "ariax://") {
            NSWorkspace.shared.open(url)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        core.stop()
    }
}

let app = NSApplication.shared
let delegate = Aria2Launcher()
app.delegate = delegate
app.run()
