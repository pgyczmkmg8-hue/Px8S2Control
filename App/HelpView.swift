import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section {
                step("1", "단축어 앱에서 + 를 눌러 새 단축어를 만들어요.")
                step("2", "액션 검색에서 \"Px8S2Control\"을 찾아 \"헤드폰 연결 / ANC 순환\"을 추가해요.")
                step("3", "\"순환할 모드\"를 2개 또는 3개 골라요. 누를 때마다 고른 순서대로 돌아요.")
            } header: {
                Text("단축어 만들기 (권장)")
            } footer: {
                Text("헤드폰이 이 기기에 연결돼 있지 않으면 연결만 하고, 연결돼 있을 때 누르면 모드를 바꿔요.")
            }

            Section("제어 센터에 넣기") {
                step("1", "제어 센터를 길게 누르고 \"컨트롤 추가\"를 눌러요.")
                step("2", "\"단축어\" 컨트롤을 추가하고 위에서 만든 단축어를 골라요.")
            }

            Section("액션 버튼 / 잠금 화면 / Siri") {
                Text("만든 단축어를 액션 버튼에 지정하거나, 잠금 화면 컨트롤에 넣거나, Siri로 실행할 수 있어요.")
            }

            Section {
                step("1", "홈 화면을 길게 눌러 + 를 누르고 \"Px8S2Control\"을 찾아요.")
                step("2", "\"PX8 ANC (고정)\"은 세 모드 버튼이 모두 나와요.")
                step("3", "\"PX8 ANC (모드 선택)\"은 위젯을 길게 눌러 \"위젯 편집\"에서 보일 모드를 골라요.")
            } header: {
                Text("홈 화면 위젯")
            } footer: {
                Text("설치 방식에 따라 위젯 버튼이 동작하지 않을 수 있어요. 그럴 땐 단축어를 사용해 주세요.")
            }
        }
        .navigationTitle("사용법")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func step(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(n).font(.callout.bold()).frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor.opacity(0.18)))
            Text(text)
        }
    }
}
