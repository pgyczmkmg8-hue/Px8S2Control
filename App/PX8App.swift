import SwiftUI
import WidgetKit

@main
struct PX8App: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    /// 화면에 보여줄 순서
    private let modes: [ANCMode] = [.noiseCancelling, .passthrough, .off]

    @State private var busy = false
    @State private var status = ""
    @State private var errorText: String?
    @State private var lastMode: ANCMode? =
        PX8Config.defaults.string(forKey: PX8Config.lastModeKey).flatMap(ANCMode.init(rawValue:))

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(modes, id: \.self) { m in
                        Button {
                            run("\(m.title) 적용 중…") {
                                try await PX8Controller.shared.set(m)
                                lastMode = m
                                WidgetCenter.shared.reloadAllTimelines()
                                return "\(m.title)(으)로 바꿨어요"
                            }
                        } label: {
                            HStack {
                                Label(m.title, systemImage: m.symbol)
                                Spacer()
                                if lastMode == m { Image(systemName: "checkmark").foregroundStyle(.tint) }
                            }
                        }
                    }
                } header: {
                    Text("소리 모드")
                } footer: {
                    Text("헤드폰이 이 기기에 블루투스로 연결된 상태에서 눌러 주세요. 체크 표시는 이 앱에서 마지막으로 보낸 모드예요.")
                }

                Section {
                    Button {
                        run("연결 중…") {
                            switch try await PX8Controller.shared.connectHeadphone() {
                            case .already:   return "이미 연결돼 있어요"
                            case .connected: return "헤드폰을 연결했어요"
                            case .requested: return "연결을 요청했어요. 잠시 뒤 연결돼요"
                            }
                        }
                    } label: {
                        Label("이 기기에 헤드폰 연결", systemImage: "headphones")
                    }
                } header: {
                    Text("연결")
                } footer: {
                    Text("헤드폰이 다른 기기에 연결돼 있을 때 이 기기로 가져와요.")
                }

                if busy || !status.isEmpty {
                    Section {
                        HStack(spacing: 10) {
                            if busy { ProgressView() }
                            Text(status)
                        }
                    }
                }

                Section {
                    NavigationLink { HelpView() } label: { Label("단축어·위젯 사용법", systemImage: "questionmark.circle") }
                    NavigationLink { SettingsView() } label: { Label("설정", systemImage: "gearshape") }
                    NavigationLink { AboutView() } label: { Label("정보", systemImage: "info.circle") }
                }
            }
            .navigationTitle("Px8S2Control")
            .disabled(busy)
            .alert("실패했어요", isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorText ?? "")
            }
        }
    }

    private func run(_ progress: String, _ work: @escaping () async throws -> String) {
        busy = true
        status = progress
        Task {
            do { status = try await work() }
            catch { status = ""; errorText = error.localizedDescription }
            busy = false
        }
    }
}
