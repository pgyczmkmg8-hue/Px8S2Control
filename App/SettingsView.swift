import SwiftUI

struct SettingsView: View {
    @State private var slots: [PX8Controller.SlotInfo] = []
    @State private var busy = false
    @State private var errorText: String?
    @State private var refresh = 0

    private var savedSlot: Int? { PX8Config.defaults.object(forKey: PX8Config.slotKey) as? Int }
    private var isManual: Bool { PX8Config.defaults.bool(forKey: PX8Config.slotManualKey) }

    var body: some View {
        List {
            Section {
                Button {
                    busy = true
                    Task {
                        do { slots = try await PX8Controller.shared.listSlots() }
                        catch { errorText = error.localizedDescription }
                        busy = false
                        refresh += 1
                    }
                } label: {
                    HStack {
                        Label("헤드폰의 기기 목록 읽기", systemImage: "list.bullet")
                        Spacer()
                        if busy { ProgressView() }
                    }
                }

                ForEach(slots) { s in
                    Button {
                        PX8Controller.shared.chooseSlot(s.index)
                        refresh += 1
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(s.name)
                                if s.connected { Text("지금 연결됨").font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            if savedSlot == s.index { Image(systemName: "checkmark").foregroundStyle(.tint) }
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Button("자동 감지로 되돌리기") {
                    PX8Controller.shared.chooseSlot(nil)
                    refresh += 1
                }
                .disabled(savedSlot == nil)
            } header: {
                Text("이 기기는 헤드폰의 어느 항목인가요?")
            } footer: {
                Text(currentText + "\n\n헤드폰은 페어링한 기기를 목록에 저장해요. \"이 기기에 연결\"이 올바른 기기로 가도록 이 기기가 어느 항목인지 알려줘요. 보통 자동으로 찾아요. 엉뚱한 기기로 연결되면 직접 골라 주세요.")
                    .id(refresh)
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(busy)
        .alert("실패했어요", isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorText ?? "")
        }
    }

    private var currentText: String {
        guard let s = savedSlot else { return "현재: 아직 감지 전이에요. 목록을 읽거나 연결하면 자동으로 정해져요." }
        return (isManual ? "현재: 직접 선택 (슬롯 \(s))" : "현재: 자동 감지 (슬롯 \(s))")
    }
}
