import CoreBluetooth
import AVFoundation
import UIKit

enum PX8Error: LocalizedError {
    case timeout, bluetoothUnavailable, notFound, characteristicMissing
    var errorDescription: String? {
        switch self {
        case .timeout: return "헤드폰이 응답하지 않아요. 잠시 뒤 다시 시도해 주세요."
        case .bluetoothUnavailable: return "블루투스가 꺼져 있거나 권한이 없어요. 설정에서 블루투스와 이 앱의 블루투스 권한을 확인해 주세요."
        case .notFound: return "헤드폰을 찾지 못했어요. 헤드폰 전원과 블루투스 연결을 확인하고, B&W 앱이 켜져 있으면 종료한 뒤 다시 시도해 주세요."
        case .characteristicMissing: return "이 헤드폰과는 통신 방식이 달라요. Px8 S2에서만 확인된 앱이에요."
        }
    }
}

@MainActor
final class PX8Controller: NSObject {
    static let shared = PX8Controller()

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeChar: CBCharacteristic?

    private var awaitingModeRead = false
    private var awaitingSlotRead = false
    private var slotEntry: (name: String, flag: UInt8)?
    private var awaitingConnectEvent = false
    private var connectEventSeen = false
    private var readMode: ANCMode?

    // 순차 단계 하나만 대기하므로 continuation 한 개로 충분
    private var pending: CheckedContinuation<Void, Error>?
    private var step = 0

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main,
                                   options: [CBCentralManagerOptionRestoreIdentifierKey: "px8.central"])
    }

    // MARK: - Public

    func set(_ mode: ANCMode) async throws {
        try await waitPoweredOn()
        let p = try await resolvePeripheral()
        try await connect(p)
        try await discover(p)
        guard let ch = writeChar else { throw PX8Error.characteristicMissing }

        if PX8Config.writeType == .withResponse {
            try await wait(5) { p.writeValue(mode.payload, for: ch, type: .withResponse) }
        } else {
            p.writeValue(mode.payload, for: ch, type: .withoutResponse)
        }
        PX8Config.defaults.set(mode.rawValue, forKey: PX8Config.lastModeKey)
    }

    enum ToggleOutcome { case connected(confirmed: Bool), switched(ANCMode) }

    /// 단축어용: 이 아이폰에 연결돼 있지 않으면 연결만, 연결돼 있으면 노이즈캔슬링 <-> 주변음 허용 전환.
    func connectOrToggle(modes: [ANCMode]) async throws -> ToggleOutcome {
        try await waitPoweredOn()
        let p = try await resolvePeripheral()
        p.delegate = self
        try await connect(p)
        try await discover(p)

        // 연결 여부: 기기 목록 슬롯 표시(끝 바이트 LSB) 또는 오디오 경로. 슬롯을 못 읽으면 연결된 것으로 보고 전환(기존 동작).
        await ensureSlot(p)
        let flag = await readPhoneSlotFlag(p)
        let connected = flag.map { $0 & 1 == 1 || audioRouteHasHeadphone() } ?? true
        if !connected {
            return .connected(confirmed: await requestConnect(p))
        }

        let current = await readCurrentMode(p)
        // 선택한 모드를 순서대로 순환. 현재 모드가 목록에 없으면 첫 번째로.
        let next: ANCMode
        if let i = modes.firstIndex(of: current) { next = modes[(i + 1) % modes.count] } else { next = modes[0] }
        try await set(next)
        return .switched(next)
    }

    enum ConnectResult { case already, connected, requested }

    /// 이 기기에 연결돼 있지 않으면 연결 명령을 보낸다. 연결 완료 이벤트까지 오면 .connected, 안 오면 .requested.
    func connectHeadphone() async throws -> ConnectResult {
        try await waitPoweredOn()
        let p = try await resolvePeripheral()
        p.delegate = self
        try await connect(p)
        try await discover(p)
        await ensureSlot(p)
        let flag = await readPhoneSlotFlag(p)
        let connected = flag.map { $0 & 1 == 1 || audioRouteHasHeadphone() } ?? true
        if connected { return .already }
        return await requestConnect(p) ? .connected : .requested
    }

    private func audioRouteHasHeadphone() -> Bool {
        let bt: [AVAudioSession.Port] = [.bluetoothA2DP, .bluetoothHFP, .bluetoothLE]
        return AVAudioSession.sharedInstance().currentRoute.outputs.contains {
            bt.contains($0.portType) && $0.portName.localizedCaseInsensitiveContains(PX8Config.nameHint)
        }
    }

    struct SlotInfo: Identifiable { let index: Int; let name: String; let connected: Bool; var id: Int { index } }

    /// 기기 목록 슬롯 조회 (캡처 확인): 07 0b 92 04 05 01 00 <slot> -> 응답 끝 바이트가 상태 표시 (c2 -> 연결 후 c3)
    private func readSlotEntry(_ p: CBPeripheral, _ index: UInt8) async -> (name: String, flag: UInt8)? {
        guard let ch = writeChar else { return nil }
        awaitingSlotRead = true
        slotEntry = nil
        let cmd = Data([0x07, 0x0b, 0x92, 0x04, 0x05, 0x01, 0x00, index])
        try? await wait(3) { p.writeValue(cmd, for: ch, type: .withResponse) }
        if slotEntry == nil { try? await wait(1.5) {} }
        awaitingSlotRead = false
        return slotEntry
    }

    private func readPhoneSlotFlag(_ p: CBPeripheral) async -> UInt8? {
        await readSlotEntry(p, PX8Config.phoneSlot)?.flag
    }

    /// 응답 페이로드 끝이 "<태그 a0|길이> <이름> 03 <상태>" 형태 (캡처 기준)
    private func parseSlot(_ b: [UInt8]) -> (name: String, flag: UInt8)? {
        guard b.count >= 11 else { return nil }
        let payload = Array(b[8...])
        let flag = payload[payload.count - 1]
        let body = Array(payload.dropLast(2))
        var name = ""
        for i in stride(from: body.count - 1, through: 0, by: -1) {
            let tag = body[i]
            let len = Int(tag & 0x0f)
            if tag & 0xf0 == 0xa0, len > 0, i + 1 + len == body.count,
               let s = String(bytes: body[(i + 1)...], encoding: .utf8) { name = s; break }
        }
        return (name, flag)
    }

    func listSlots() async throws -> [SlotInfo] {
        try await waitPoweredOn()
        let p = try await resolvePeripheral()
        p.delegate = self
        try await connect(p)
        try await discover(p)
        let slots = await readAllSlots(p)
        applyGuess(slots)           // 목록을 읽을 때도 추정값을 저장해 화면에 바로 반영
        return slots
    }

    private func readAllSlots(_ p: CBPeripheral) async -> [SlotInfo] {
        var out: [SlotInfo] = []
        for i in 0..<4 {
            guard let e = await readSlotEntry(p, UInt8(i)), !e.name.isEmpty else { continue }
            out.append(SlotInfo(index: i, name: e.name, connected: e.flag & 1 == 1))
        }
        return out
    }

    /// 수동 선택이 없으면 기기 종류(iPhone/iPad)와 이름이 맞는 슬롯으로 추정해 저장. iOS는 기기 이름을 숨겨서 이름 일치는 못 쓴다.
    private func ensureSlot(_ p: CBPeripheral) async {
        if PX8Config.defaults.object(forKey: PX8Config.slotKey) != nil { return }
        applyGuess(await readAllSlots(p))
    }

    private func applyGuess(_ slots: [SlotInfo]) {
        if PX8Config.defaults.object(forKey: PX8Config.slotKey) != nil { return }
        let prefix = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        let hits = slots.filter { $0.name.lowercased().hasPrefix(prefix) }
        if let g = hits.first(where: { $0.connected }) ?? hits.first {
            PX8Config.defaults.set(g.index, forKey: PX8Config.slotKey)
        }
    }

    func chooseSlot(_ index: Int?) {
        if let index {
            PX8Config.defaults.set(index, forKey: PX8Config.slotKey)
            PX8Config.defaults.set(true, forKey: PX8Config.slotManualKey)
        } else {
            PX8Config.defaults.removeObject(forKey: PX8Config.slotKey)
            PX8Config.defaults.removeObject(forKey: PX8Config.slotManualKey)
        }
    }

    /// 연결 명령 (캡처 확인): 07 0b 92 05 05 01 00 <slot>. 성공하면 헤드폰이 클래식 연결을 걸고 이벤트 0d 12 0a 05 를 보낸다.
    private func requestConnect(_ p: CBPeripheral) async -> Bool {
        guard let ch = writeChar else { return false }
        awaitingConnectEvent = true
        connectEventSeen = false
        let cmd = Data([0x07, 0x0b, 0x92, 0x05, 0x05, 0x01, 0x00, PX8Config.phoneSlot])
        do { try await wait(3) { p.writeValue(cmd, for: ch, type: .withResponse) } } catch { awaitingConnectEvent = false; return false }
        if !connectEventSeen { try? await wait(8) {} }
        awaitingConnectEvent = false
        return connectEventSeen
    }

    /// 현재 모드 조회. 조회 요청(0b 12 01 03)은 캡처에 없는 추정이라 응답이 없으면 마지막으로 보낸 모드로 대체.
    private func readCurrentMode(_ p: CBPeripheral) async -> ANCMode {
        if let ch = writeChar {
            awaitingModeRead = true
            readMode = nil
            try? await wait(3) { p.writeValue(Data([0x04, 0x0b, 0x12, 0x01, 0x03]), for: ch, type: .withResponse) }
            if readMode == nil { try? await wait(1.5) {} }
            awaitingModeRead = false
        }
        if let m = readMode { return m }
        return PX8Config.defaults.string(forKey: PX8Config.lastModeKey).flatMap(ANCMode.init(rawValue:)) ?? .noiseCancelling
    }

    private func handleNotify(_ v: Data) {
        let b = [UInt8](v)
        var value: UInt8?
        if b.count == 7, b[0] == 0x0d, b[1] == 0x92, b[2] == 0x01, b[3] == 0x03 {          // 상태 이벤트 (캡처로 확인)
            value = b[6]
        } else if b.count >= 9, b[0] == 0x0c, b[1] == 0x92, b[2] == 0x01, b[3] == 0x03, b[4] == 0, b[5] == 0 {  // 조회 응답 (추정)
            value = b[8]
        }
        // 기기 목록 슬롯 응답: 0c 92 04 05 00 00 <len16> ... <상태>
        if awaitingSlotRead, b.count >= 9, b[0] == 0x0c, b[1] == 0x92, b[2] == 0x04, b[3] == 0x05, b[4] == 0, b[5] == 0 {
            slotEntry = parseSlot(b)
            awaitingSlotRead = false
            finish(.success(()))
            return
        }
        // 연결 완료 이벤트: 0d 12 0a 05
        if b == [0x0d, 0x12, 0x0a, 0x05], awaitingConnectEvent {
            connectEventSeen = true
            awaitingConnectEvent = false
            finish(.success(()))
            return
        }
        guard let value, let m = ANCMode(wire: value) else { return }
        PX8Config.defaults.set(m.rawValue, forKey: PX8Config.lastModeKey)
        if awaitingModeRead {
            readMode = m
            awaitingModeRead = false
            finish(.success(()))
        }
    }

    // MARK: - Steps

    private func waitPoweredOn() async throws {
        if central.state == .poweredOn { return }
        try await wait(5) {}
        guard central.state == .poweredOn else { throw PX8Error.bluetoothUnavailable }
    }

    private func resolvePeripheral() async throws -> CBPeripheral {
        if let p = peripheral { return p }
        if let s = PX8Config.defaults.string(forKey: PX8Config.peripheralIDKey),
           let id = UUID(uuidString: s),
           let p = central.retrievePeripherals(withIdentifiers: [id]).first {
            peripheral = p; return p
        }
        if let p = central.retrieveConnectedPeripherals(withServices: [PX8Config.serviceUUID]).first {
            peripheral = p; return p
        }
        // 서비스 UUID를 모르는 단계에서도 동작: 시스템에 이미 연결된 LE 기기 중 이름으로 찾기 (GAP 0x1800)
        if let p = central.retrieveConnectedPeripherals(withServices: [CBUUID(string: "1800")])
            .first(where: { ($0.name ?? "").localizedCaseInsensitiveContains(PX8Config.nameHint) }) {
            peripheral = p
            PX8Config.defaults.set(p.identifier.uuidString, forKey: PX8Config.peripheralIDKey)
            return p
        }
        // 마지막 수단: 스캔
        try await wait(8) { central.scanForPeripherals(withServices: nil) }
        central.stopScan()
        guard let p = peripheral else { throw PX8Error.notFound }
        return p
    }

    private func connect(_ p: CBPeripheral) async throws {
        p.delegate = self
        if p.state == .connected { return }
        do { try await wait(8) { central.connect(p) } }
        catch { central.cancelPeripheralConnection(p); throw error }
    }

    private func discover(_ p: CBPeripheral) async throws {
        if writeChar != nil { return }
        try await wait(5) { p.discoverServices([PX8Config.serviceUUID]) }
        guard let svc = p.services?.first(where: { $0.uuid == PX8Config.serviceUUID }) else {
            throw PX8Error.characteristicMissing
        }
        try await wait(5) { p.discoverCharacteristics(nil, for: svc) }
        writeChar = svc.characteristics?.first(where: { $0.uuid == PX8Config.writeCharUUID })
        // 캡처상 알림 핸들이 2개(0x0095 응답, 0x009b 이벤트)라 notify 가능한 건 전부 구독
        for c in svc.characteristics ?? [] where c.properties.contains(.notify) {
            p.setNotifyValue(true, for: c)
        }
    }

    // MARK: - Async plumbing

    private func wait(_ timeout: TimeInterval, start: () -> Void) async throws {
        step += 1
        let id = step
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            pending = c
            start()
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                guard let self, self.step == id else { return }
                self.finish(.failure(PX8Error.timeout))
            }
        }
    }

    private func finish(_ r: Result<Void, Error>) {
        guard let c = pending else { return }
        pending = nil
        c.resume(with: r)
    }
}

// MARK: - Delegates (queue: .main 이므로 MainActor 가정)

extension PX8Controller: CBCentralManagerDelegate, CBPeripheralDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        MainActor.assumeIsolated { finish(.success(())) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        MainActor.assumeIsolated {
            if let p = (dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral])?.first {
                peripheral = p; p.delegate = self
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover p: CBPeripheral,
                                    advertisementData: [String: Any], rssi: NSNumber) {
        MainActor.assumeIsolated {
            let name = p.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
            guard name.localizedCaseInsensitiveContains(PX8Config.nameHint) else { return }
            peripheral = p
            PX8Config.defaults.set(p.identifier.uuidString, forKey: PX8Config.peripheralIDKey)
            finish(.success(()))
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect p: CBPeripheral) {
        MainActor.assumeIsolated { finish(.success(())) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        MainActor.assumeIsolated { finish(.failure(error ?? PX8Error.timeout)) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        MainActor.assumeIsolated { writeChar = nil }
    }

    nonisolated func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        MainActor.assumeIsolated { finish(error.map { .failure($0) } ?? .success(())) }
    }

    nonisolated func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        MainActor.assumeIsolated { finish(error.map { .failure($0) } ?? .success(())) }
    }

    nonisolated func peripheral(_ p: CBPeripheral, didUpdateValueFor c: CBCharacteristic, error: Error?) {
        guard let v = c.value else { return }
        MainActor.assumeIsolated { handleNotify(v) }
    }

    nonisolated func peripheral(_ p: CBPeripheral, didWriteValueFor c: CBCharacteristic, error: Error?) {
        MainActor.assumeIsolated { finish(error.map { .failure($0) } ?? .success(())) }
    }
}
