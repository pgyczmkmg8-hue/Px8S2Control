import CoreBluetooth
import AppIntents

/// 패킷 캡처 결과로 채워야 하는 값은 전부 TODO 표시.
enum PX8Config {
    static let appGroup = "group.com.MACHU.Px8S2Control"
    static let peripheralIDKey = "px8.peripheralID"
    static let lastModeKey = "px8.lastMode"

    // GATT 덤프 + 캡처 핸들 대조로 확정 (서비스 내 순서: notify 0x95, 0x98, 0x9b, write 0x9e, 0xa1)
    //   CB909093… = 0x0095 (응답 알림)   DF55D475… = 0x009b (상태 이벤트 알림)   ADA50CE9… = 0x009e (명령 쓰기)
    static let serviceUUID = CBUUID(string: "85BA93A5-09AC-439A-8CC4-1C3F0CB4F29F")
    static let writeCharUUID = CBUUID(string: "ADA50CE9-67B8-4A97-9D8E-37E1D083156C")

    // 캡처가 ATT Write Request, 특성 속성도 [write] 뿐이라 응답 있는 쓰기
    static let writeType: CBCharacteristicWriteType = .withResponse

    // 헤드폰 페어링 기기 목록에서 이 기기의 슬롯 번호. 수동 선택 또는 자동 추정값을 저장, 없으면 0.
    static let slotKey = "px8.slot"
    static let slotManualKey = "px8.slotManual"   // 직접 고른 값이면 true
    static var phoneSlot: UInt8 { UInt8(defaults.object(forKey: slotKey) as? Int ?? 0) }

    // 스캔 시 이름으로 후보를 거를 때 사용
    static let nameHint = "Px8"

    static var defaults: UserDefaults { UserDefaults(suiteName: appGroup) ?? .standard }
}

enum ANCMode: String, AppEnum, CaseIterable {
    case off, noiseCancelling, passthrough

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "ANC 모드"
    static var caseDisplayRepresentations: [ANCMode: DisplayRepresentation] = [
        .off: "끄기",
        .noiseCancelling: "노이즈캔슬링",
        .passthrough: "주변음 허용",
    ]

    /// 캡처로 확정: 핸들 0x009e 에 Write Request.
    /// 프레임 = 07 0b 92 02 03 01 00 XX  (XX: 00 = 끄기, 01 = 노이즈캔슬링, 02 = 주변음 허용 — 캡처로 확정)
    /// 성공하면 핸들 0x0095 로 `0c 12 02 03 00 00` 응답, 약 0.8초 뒤 핸들 0x009b 로 `0d 92 01 03 01 00 XX` 이벤트가 옴.
    var payload: Data {
        let value: UInt8
        switch self {
        case .off: value = 0x00
        case .noiseCancelling: value = 0x01
        case .passthrough: value = 0x02
        }
        return Data([0x07, 0x0b, 0x92, 0x02, 0x03, 0x01, 0x00, value])
    }

    /// 프레임 마지막 바이트 / 상태 이벤트의 값
    init?(wire: UInt8) {
        switch wire {
        case 0x00: self = .off
        case 0x01: self = .noiseCancelling
        case 0x02: self = .passthrough
        default: return nil
        }
    }

    var symbol: String {
        switch self {
        case .off:             return "circle.slash"
        case .noiseCancelling: return "ear.badge.waveform"
        case .passthrough:     return "ear"
        }
    }

    var title: String { Self.caseDisplayRepresentations[self].map { String(localized: $0.title) } ?? rawValue }
}
