import AppIntents
import WidgetKit

/// 단축어용: 헤드폰이 이 기기에 연결돼 있지 않으면 연결만 하고,
/// 연결돼 있으면 고른 모드들을 순서대로 순환한다.
struct ToggleANCIntent: AudioPlaybackIntent {   // 앱 프로세스에서 실행 (SetANCModeIntent 주석 참고)
    static var title: LocalizedStringResource = "헤드폰 연결 / ANC 순환"
    static var description = IntentDescription("연결돼 있지 않으면 연결만 하고, 연결돼 있으면 고른 모드들을 순서대로 전환합니다.")
    static var openAppWhenRun = false

    @Parameter(title: "순환할 모드", default: [ANCMode.noiseCancelling, ANCMode.passthrough])
    var modes: [ANCMode]

    init() {}
    init(modes: [ANCMode]) { self.modes = modes }

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$modes) 순환")
    }

    struct NeedTwoModes: Error, CustomLocalizedStringResourceConvertible {
        var localizedStringResource: LocalizedStringResource { "순환할 모드를 서로 다른 2개 이상 선택해 주세요." }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        var list: [ANCMode] = []
        for m in modes where !list.contains(m) { list.append(m) }
        guard list.count >= 2 else { throw NeedTwoModes() }

        defer { WidgetCenter.shared.reloadAllTimelines() }
        let message: String
        switch try await PX8Controller.shared.connectOrToggle(modes: list) {
        case .connected(let ok): message = ok ? "헤드폰을 연결했어요" : "헤드폰에 연결을 요청했어요"
        case .switched(let m):   message = "\(m.title)(으)로 전환했어요"
        }
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
