import WidgetKit
import SwiftUI
import AppIntents

@main
struct PX8WidgetBundle: WidgetBundle {
    var body: some Widget {
        PX8FixedWidget()
        PX8HomeWidget()
    }
}

// MARK: - 공통

struct ModeEntry: TimelineEntry {
    let date: Date
    let last: ANCMode?
    let modes: [ANCMode]
}

private func lastMode() -> ANCMode? {
    PX8Config.defaults.string(forKey: PX8Config.lastModeKey).flatMap(ANCMode.init(rawValue:))
}

/// 진단 위젯(실기기에서 동작 확인됨)과 같은 형태의 버튼 줄
struct ModeButtons: View {
    let modes: [ANCMode]
    let last: ANCMode?
    var body: some View {
        HStack(spacing: 6) {
            ForEach(modes, id: \.self) { m in
                Button(intent: SetANCModeIntent(mode: m)) {
                    VStack(spacing: 2) {
                        Image(systemName: m.symbol)
                        Text(m.title).font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(last == m ? Color.accentColor : Color.gray)
            }
        }
    }
}

// MARK: - 고정 위젯 (끄기 / 노이즈캔슬링 / 주변음 허용)

struct FixedProvider: TimelineProvider {
    func placeholder(in context: Context) -> ModeEntry { ModeEntry(date: .now, last: .noiseCancelling, modes: ANCMode.allCases) }
    func getSnapshot(in context: Context, completion: @escaping (ModeEntry) -> Void) {
        completion(ModeEntry(date: .now, last: lastMode(), modes: ANCMode.allCases))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ModeEntry>) -> Void) {
        completion(Timeline(entries: [ModeEntry(date: .now, last: lastMode(), modes: ANCMode.allCases)], policy: .never))
    }
}

struct PX8FixedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PX8FixedWidget", provider: FixedProvider()) { e in
            ModeButtons(modes: e.modes, last: e.last)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("PX8 ANC (고정)")
        .description("끄기 / 노이즈캔슬링 / 주변음 허용")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - 설정 가능 위젯 (보여줄 모드 선택)

struct HomeModesIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "표시할 모드"
    static var description = IntentDescription("위젯에 버튼으로 보여줄 모드를 고릅니다.")

    @Parameter(title: "표시할 모드", default: [ANCMode.off, ANCMode.noiseCancelling, ANCMode.passthrough])
    var modes: [ANCMode]

    init() {}
}

struct ModeProvider: AppIntentTimelineProvider {
    private func shown(_ c: HomeModesIntent) -> [ANCMode] {
        var out: [ANCMode] = []
        for m in c.modes where !out.contains(m) { out.append(m) }
        return out.isEmpty ? ANCMode.allCases : out
    }
    func placeholder(in context: Context) -> ModeEntry { ModeEntry(date: .now, last: .noiseCancelling, modes: ANCMode.allCases) }
    func snapshot(for configuration: HomeModesIntent, in context: Context) async -> ModeEntry {
        ModeEntry(date: .now, last: lastMode(), modes: shown(configuration))
    }
    func timeline(for configuration: HomeModesIntent, in context: Context) async -> Timeline<ModeEntry> {
        Timeline(entries: [ModeEntry(date: .now, last: lastMode(), modes: shown(configuration))], policy: .never)
    }
}

struct PX8HomeWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "PX8HomeConfigurable", intent: HomeModesIntent.self, provider: ModeProvider()) { e in
            ModeButtons(modes: e.modes, last: e.last)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("PX8 ANC (모드 선택)")
        .description("위젯을 길게 눌러 '위젯 편집'에서 보여줄 모드를 고르세요")
        .supportedFamilies([.systemMedium])
    }
}
