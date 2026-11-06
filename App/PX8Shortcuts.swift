import AppIntents

struct PX8Shortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ToggleANCIntent(),
                    phrases: ["\(.applicationName) 전환", "\(.applicationName) ANC 전환"],
                    shortTitle: "연결 / ANC 전환", systemImageName: "arrow.left.arrow.right")
        AppShortcut(intent: SetANCModeIntent(mode: .noiseCancelling),
                    phrases: ["\(.applicationName) 노이즈캔슬링"],
                    shortTitle: "노이즈캔슬링", systemImageName: "ear.badge.waveform")
        AppShortcut(intent: SetANCModeIntent(mode: .off),
                    phrases: ["\(.applicationName) 끄기"],
                    shortTitle: "ANC 끄기", systemImageName: "circle.slash")
        AppShortcut(intent: SetANCModeIntent(mode: .passthrough),
                    phrases: ["\(.applicationName) 주변음 허용"],
                    shortTitle: "주변음 허용", systemImageName: "ear")
    }
}
