import Cocoa
import Carbon

// 화면을 "감마 테이블"로 검게 만든다. 오버레이 창이 아니므로 screencapture, ScreenCaptureKit,
// 브라우저 스크린샷에는 원래 화면이 그대로 찍힌다. 프로세스가 끝나면 감마는 자동 복구된다.
// 사용: BlackScreen [on|off|toggle|quit|status]   단축키: Ctrl+Opt+Cmd+B (토글), Esc 3번 (끄기)

let bundleID = "com.hunkii.blackscreen"
let noteName = Notification.Name("com.hunkii.blackscreen.set")
let stateDir = NSString(string: "~/.local/state").expandingTildeInPath
let stateFile = stateDir + "/blackscreen.state"

func post(_ s: String) {
    DistributedNotificationCenter.default().postNotificationName(noteName, object: nil, userInfo: ["state": s], deliverImmediately: true)
}
func readState() -> String { ((try? String(contentsOfFile: stateFile, encoding: .utf8)) ?? "off").trimmingCharacters(in: .whitespacesAndNewlines) }

let arg = CommandLine.arguments.dropFirst().first
let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).filter { $0.processIdentifier != getpid() }

if arg == "status" { print(others.isEmpty ? "off" : readState()); exit(0) }
if !others.isEmpty {
    if arg == "quit" { others.forEach { $0.terminate() } } else { post(arg ?? "toggle") }
    usleep(300_000); exit(0)
}
if arg == "quit" || arg == "off" { exit(0) }

final class Delegate: NSObject, NSApplicationDelegate {
    var isOn = false
    var timer: Timer?
    var escHotKey: EventHotKeyRef?
    var toggleHotKey: EventHotKeyRef?
    var escTimes: [Date] = []

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.regular)
        DistributedNotificationCenter.default().addObserver(forName: noteName, object: nil, queue: .main) { n in
            self.apply((n.userInfo?["state"] as? String) ?? "toggle")
        }
        CGDisplayRegisterReconfigurationCallback({ _, _, ud in
            guard let ud = ud else { return }
            let d = Unmanaged<Delegate>.fromOpaque(ud).takeUnretainedValue()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { if d.isOn { d.paint() } }
        }, Unmanaged.passUnretained(self).toOpaque())
        let src = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        signal(SIGTERM, SIG_IGN)
        src.setEventHandler { NSApp.terminate(nil) }
        src.resume()
        sigSrc = src
        installHotKeyHandler()
        var t: EventHotKeyRef?
        RegisterEventHotKey(UInt32(kVK_ANSI_B), UInt32(controlKey | optionKey | cmdKey), EventHotKeyID(signature: 0x424C4B53, id: 1), GetApplicationEventTarget(), 0, &t)
        toggleHotKey = t
        apply("on")
    }
    var sigSrc: DispatchSourceSignal?

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { apply("toggle"); return false }
    func applicationWillTerminate(_ n: Notification) { CGDisplayRestoreColorSyncSettings(); try? "off".write(toFile: stateFile, atomically: true, encoding: .utf8) }

    func installHotKeyHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, ev, ud in
            var hk = EventHotKeyID()
            GetEventParameter(ev, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
            let d = Unmanaged<Delegate>.fromOpaque(ud!).takeUnretainedValue()
            if hk.id == 1 { d.apply("toggle") } else if hk.id == 2 { d.escPressed() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }
    func escPressed() {
        let now = Date()
        escTimes = (escTimes + [now]).filter { now.timeIntervalSince($0) < 1.5 }
        if escTimes.count >= 3 { escTimes = []; apply("off") }
    }
    func apply(_ s: String) {
        let want = (s == "toggle") ? !isOn : (s == "on")
        if want != isOn {
            isOn = want
            if isOn {
                paint()
                timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in self.paint() }   // 깨우기 등으로 풀리면 다시 적용
                var t: EventHotKeyRef?
                RegisterEventHotKey(UInt32(kVK_Escape), 0, EventHotKeyID(signature: 0x424C4B53, id: 2), GetApplicationEventTarget(), 0, &t)
                escHotKey = t
            } else {
                timer?.invalidate(); timer = nil
                if let e = escHotKey { UnregisterEventHotKey(e); escHotKey = nil }
                CGDisplayRestoreColorSyncSettings()
            }
        }
        try? FileManager.default.createDirectory(atPath: stateDir, withIntermediateDirectories: true)
        try? (isOn ? "on" : "off").write(toFile: stateFile, atomically: true, encoding: .utf8)
    }
    func paint() {
        var n: UInt32 = 0
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        CGGetActiveDisplayList(16, &ids, &n)
        let zeros = [CGGammaValue](repeating: 0, count: 256)
        for i in 0..<Int(n) { CGSetDisplayTransferByTable(ids[i], 256, zeros, zeros, zeros) }
    }
}
let app = NSApplication.shared
let d = Delegate()
app.delegate = d
app.run()
