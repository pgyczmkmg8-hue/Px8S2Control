# Px8S2Control

Bowers & Wilkins **Px8 S2** 헤드폰의 노이즈캔슬링(ANC) 모드를 아이폰에서 버튼 하나로 바꾸는 비공식 iOS 앱이에요.
B&W Music 앱을 열지 않고 **단축어, 액션 버튼, 제어 센터, 홈 화면 위젯**에서 모드를 바꿀 수 있어요.

> **B&W와 관련 없는 비공식 오픈소스 프로젝트예요.** 헤드폰이 B&W 앱과 주고받는 블루투스(BLE) 통신을 분석해서 만들었어요.
> 펌웨어 업데이트로 동작이 바뀔 수 있고, **Px8 S2에서만 확인**했어요. 사용에 따른 책임은 사용자에게 있어요.

## 기능

- 모드 3가지: **노이즈캔슬링 / 주변음 허용 / 끄기**
- **단축어 액션 "헤드폰 연결 / ANC 순환"**
  - 헤드폰이 이 기기에 연결돼 있지 않으면 **연결만** 해요.
  - 연결돼 있으면 고른 모드(2~3개)를 **순서대로 순환**해요.
- 헤드폰이 다른 기기(맥, 아이패드 등)에 붙어 있어도 **이 기기로 연결**해 오는 버튼
- 홈 화면 위젯: 고정 버튼 위젯, 보여줄 모드를 고르는 위젯

## 설치 (사이드로딩)

App Store에는 올라가 있지 않아요. [Releases](../../releases)의 서명 안 된 `Px8S2Control.ipa`를 직접 서명해서 설치해요.

1. Releases에서 `Px8S2Control.ipa`를 받아요.
2. AltStore, Sideloadly, Feather 같은 도구로 **본인 Apple ID(또는 개발자 인증서)로 서명해서 설치**해요.
3. 처음 실행할 때 **블루투스 권한**을 허용해요.

> 헤드폰을 아이폰에 평소처럼 페어링해 두면 돼요. 이 앱이 따로 페어링을 요구하지는 않아요.
> 무료 Apple ID로 설치하면 7일마다 다시 서명해야 하고, 앱 개수 제한이 있어요. 위젯 익스텐션도 앱 ID를 하나 더 써요.

## 사용법

앱 안의 **"단축어·위젯 사용법"** 메뉴에도 같은 내용이 있어요.

### 단축어 (권장)

1. 단축어 앱에서 새 단축어를 만들고 액션 검색에서 `Px8S2Control`을 찾아 **헤드폰 연결 / ANC 순환**을 추가해요.
2. "순환할 모드"를 2~3개 골라요.
3. 이 단축어를 **액션 버튼, 잠금 화면, 제어 센터의 "단축어" 컨트롤, Siri**에 지정해서 써요.

### 제어 센터

앱이 직접 제공하는 제어 센터 컨트롤은 없어요. 위 단축어를 시스템의 **"단축어" 컨트롤**에 지정해서 쓰세요.
(제어 센터 컨트롤의 인텐트는 위젯 익스텐션 안에서 실행되는데, 거기서는 블루투스를 쓸 수 없어서 동작하지 않아요.)

### 홈 화면 위젯 (실험적)

- **PX8 ANC (고정)**: 끄기 / 노이즈캔슬링 / 주변음 허용 버튼
- **PX8 ANC (모드 선택)**: 위젯을 길게 눌러 "위젯 편집"에서 보일 모드를 골라요.

설치 방식에 따라 위젯 버튼이 동작하지 않을 수 있어요. 그럴 땐 단축어를 쓰세요.

## 문제 해결

- **헤드폰을 찾지 못해요**: 헤드폰이 아이폰에 블루투스로 연결돼 있는지 확인하고, **B&W Music 앱을 완전히 종료**하세요.
- **엉뚱한 기기로 연결돼요**: 앱의 **설정**에서 "헤드폰의 기기 목록 읽기"를 누르고 이 기기에 해당하는 항목을 직접 고르세요.
- **키보드를 올릴 때마다 헤드폰에서 삑 소리가 나요**: 이 앱과 무관한 현상이에요. iOS의 **키보드 사운드**가 무음 오디오 스트림을 열 때 헤드폰이 소리를 내는 걸로 보여요. 설정 → 사운드 및 햅틱 → 키보드 피드백에서 **소리**를 끄면 사라져요.

## 직접 빌드

필요한 것: Xcode, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

```bash
xcodegen generate
open PX8Control.xcodeproj
```

서명하려면 `project.yml`에서 아래 값을 본인 것으로 바꾸세요.

- `DEVELOPMENT_TEAM`
- 번들 ID: `com.MACHU.Px8S2Control` (위젯은 `….Widgets`)
- App Group: `group.com.MACHU.Px8S2Control` (`Shared/PX8Config.swift`의 `appGroup`도 같이)

서명 없이 IPA만 만들려면:

```bash
xcodebuild -project PX8Control.xcodeproj -scheme PX8Control -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
mkdir Payload && cp -R build/Build/Products/Release-iphoneos/Px8S2Control.app Payload/
zip -qry Px8S2Control.ipa Payload
```

## 어떻게 동작하나요

헤드폰이 BLE로 받는 짧은 명령을 그대로 보내요. 분석한 내용은 [PROTOCOL.md](PROTOCOL.md)에 정리해 뒀어요.

## 한계

- Px8 S2에서만 확인했어요. 같은 프로토콜을 쓰는 다른 B&W 헤드폰은 동작할 수도 있지만 확인하지 않았어요.
- 위젯과 단축어 같은 시스템 진입점은 iOS 버전과 설치 방식에 영향을 받아요. iOS 18 이상에서 개발했어요.
- 이 앱은 헤드폰의 현재 모드를 직접 읽지 못해요(조회 명령을 찾지 못했어요). 마지막으로 보낸 모드와 헤드폰이 알려주는 상태 이벤트로 추적해요. 헤드폰 버튼이나 B&W 앱으로 모드를 바꿨다면 첫 순환이 예상과 다르게 갈 수 있어요.

## 라이선스

[MIT](LICENSE)
