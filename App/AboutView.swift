import SwiftUI

struct AboutView: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    var body: some View {
        List {
            Section {
                LabeledContent("버전", value: version)
                LabeledContent("확인된 모델", value: "Bowers & Wilkins Px8 S2")
            }

            Section("알아두세요") {
                Text("B&W와 관련 없는 비공식 오픈소스 앱이에요. 제품 이름은 호환 모델을 알리는 용도로만 썼어요.")
                Text("헤드폰이 B&W 앱과 주고받는 블루투스 통신을 분석해서 만들었어요. 헤드폰 펌웨어가 바뀌면 동작이 달라질 수 있어요.")
                Text("Px8 S2에서만 확인했어요. 다른 모델에서는 동작을 보장할 수 없어요.")
                Text("B&W 앱이 켜져 있으면 연결이 겹칠 수 있어요. 이 앱을 쓸 때는 B&W 앱을 종료해 두세요.")
            }

            Section("개인정보") {
                Text("이 앱은 블루투스로 헤드폰과만 통신해요. 서버로 보내는 정보는 없어요.")
            }
        }
        .navigationTitle("정보")
        .navigationBarTitleDisplayMode(.inline)
    }
}
