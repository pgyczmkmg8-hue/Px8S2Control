import AppIntents
import WidgetKit

/// 단축어 / 위젯 버튼이 공유하는 인텐트: 지정한 ANC 모드로 바꾼다.
///
/// 실기기에서 확인한 제약:
/// - 위젯 익스텐션 안에서는 CBCentralManager 를 만드는 순간 멈추므로 BLE는 앱 프로세스에서만 돌려야 한다.
/// - AudioPlaybackIntent 로 선언하면 위젯 버튼을 눌러도 앱 프로세스에서 실행된다.
///   (LiveActivityIntent 는 위젯에서 앱 프로세스로 가지 않았다. 제어 센터 컨트롤은 어느 방식도 안 돼서 단축어 컨트롤을 쓴다.)
struct SetANCModeIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "ANC 모드 변경"
    static var description = IntentDescription("Px8 S2 헤드폰의 노이즈캔슬링 모드를 바꿉니다.")
    static var openAppWhenRun = false

    @Parameter(title: "모드")
    var mode: ANCMode

    init() { self.mode = .noiseCancelling }
    init(mode: ANCMode) { self.mode = mode }

    static var parameterSummary: some ParameterSummary {
        Summary("ANC 모드를 \(\.$mode)(으)로 변경")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        defer { WidgetCenter.shared.reloadAllTimelines() }   // 위젯의 현재 모드 강조 갱신
        try await PX8Controller.shared.set(mode)
        return .result()
    }
}
