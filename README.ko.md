<div align="center">

<img src="design/app-icon.svg" width="128" alt="TurtleNeck app icon">

# TurtleNeck

**거북목을 고쳐주는 잔소리꾼 거북이**

자세가 무너지면 거북이가 화면에 슬며시 나타나고,<br>
계속 구부정하면 점점 화를 냅니다.

[![macOS 13+](https://img.shields.io/badge/macOS-13.0+-black?logo=apple)](https://www.apple.com/macos/)
[![Windows beta](https://img.shields.io/badge/Windows-beta-0078D6?logo=windows)](Windows/README.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-blue?logo=kofi)](https://ko-fi.com/kpryu)

**[웹사이트](https://kpryu6.github.io/turtleneck/)** · [English](README.md) · **한국어**

<img src="docs/images/alerts.png" width="500" alt="갈색 거북이에서 빨간 거북이로 점점 화가 나는 TurtleNeck 알림">

</div>

---

## 설치 (macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/kpryu6/turtleneck/main/install.sh | bash
```

이 한 줄이면 끝이에요. [Releases](https://github.com/kpryu6/turtleneck/releases)에서 최신 버전을 받아 응용 프로그램 폴더에 설치하고 바로 실행해요(Homebrew 필요 없음). 업데이트할 때도 같은 명령을 다시 실행하면 돼요. 처음 실행하면 카메라 권한을 허용하고 5초 동안 바른 자세로 앉아 기준 자세를 저장하면 끝이에요.

<details>
<summary>다른 설치 방법</summary>

**Homebrew**
```bash
brew tap kpryu6/turtleneck
brew trust kpryu6/turtleneck
brew install --cask turtleneck
xattr -cr /Applications/TurtleNeck.app
```

**DMG**

1. [Releases](https://github.com/kpryu6/turtleneck/releases)에서 `.dmg`를 받아 TurtleNeck을 응용 프로그램 폴더로 끌어다 놓으세요.
2. 앱을 여세요. 아직 Apple 공증을 받지 않은 앱이라 처음에는 macOS가 실행을 막아요.
3. **시스템 설정 → 개인정보 보호 및 보안**에서 **그래도 열기**를 누르세요. 터미널에서 `xattr -cr /Applications/TurtleNeck.app`를 실행해도 돼요.

</details>

### Windows (베타)

**[TurtleNeck-Setup.exe 다운로드](https://github.com/kpryu6/turtleneck/releases/latest/download/TurtleNeck-Setup.exe)** 후 실행하세요. 내 계정에만 설치되고(관리자 권한 불필요), **설정 → 앱**에서 삭제할 수 있어요.

PowerShell로 설치하려면:

```powershell
irm https://raw.githubusercontent.com/kpryu6/turtleneck/main/install.ps1 | iex
```

아직 코드 서명이 없어서 Windows SmartScreen 경고가 뜰 수 있어요. **추가 정보 → 실행**을 누르세요. Windows 버전에는 아직 macOS 기능이 다 들어 있지는 않아요. 되는 기능은 [Windows/README.md](Windows/README.md)를 보세요.

## 동작 방식

1. **기준 자세 저장.** 바르게 앉은 자세를 기준으로 저장해요.
2. **감지.** 1초에 한 번 웹캠 화면 속 얼굴 위치를 확인해요. 분석은 Mac 안에서 Apple Vision으로 해요.
3. **알림.** 머리가 내려가거나 화면 쪽으로 다가간 상태가 5초 넘게 이어지면 거북이가 나타나요.
4. **단계 상승.** 오래 구부정할수록 거북이가 점점 화를 내요.

| | 단계 | 구부정한 시간 | 예시 |
|---|-------|---------|---------|
| 🐢 | 부드럽게 | 0–20초 | *"Hey buddy, I came out just for you"* |
| 🐢💢 | 짜증 | 20–60초 | *"Your spine called. It wants a divorce."* |
| 🐢🔥 | 분노 | 60초+ | *"Your posture is a CRIME and I'm the police 🚨"* |

## 기능

- **메뉴 막대 앱.** 자세가 나빠지면 거북이 아이콘이 노랑, 빨강으로 바뀌어요.
- **나만의 메시지와 캐릭터.** 잔소리 문구를 직접 쓰거나, 거북이를 고양이·강아지·부엉이 또는 내 사진으로 바꿀 수 있어요.
- **통계.** 일별 점수, 거북이 등장 횟수, 주간 추이, GitHub 잔디 같은 연간 캘린더, 🔥 연속 기록을 보여줘요. 점수가 70점 이상인 날마다 연속 기록이 늘고, 주말처럼 앱을 안 쓴 날은 기록이 끊기지 않아요.
- **휴식 알림.** 뽀모도로 방식의 작업/휴식 타이머예요. 설정은 앱을 다시 켜도 유지돼요.
- **방해하지 않기.** 근무 시간에만 켜거나, 특정 앱을 쓰는 동안이나 집중 모드일 때 쉬게 할 수 있어요.
- **8개 언어.** 한국어, English, 日本語, 中文, Español, Deutsch, Français, Português.

## 개인정보

모든 처리는 Mac 안에서만 이뤄져요. **카메라 영상은 녹화하지도, 저장하지도, 어디로 보내지도 않아요.** 서버도, 분석 도구도, 계정도 없어요. 기준 자세와 비교하기 위한 얼굴 위치와 크기만 기억해요.

## 다운로드 파일 검증

모든 릴리스는 이 저장소에서 GitHub Actions가 빌드하고, 서명된 [빌드 출처 증명](https://docs.github.com/actions/security-for-github-actions/using-artifact-attestations)이 붙어요. 받은 파일이 정말 여기서 만들어졌는지 확인하려면:

```bash
gh attestation verify TurtleNeck.dmg --repo kpryu6/turtleneck
```

## 자주 묻는 질문

**배터리를 많이 먹나요?**
그렇지 않아요. 카메라는 켜져 있지만 분석은 1초에 한 프레임만 해요. 메뉴 막대에서 **일시정지**를 누르면 카메라가 완전히 꺼져요.

**카메라 불이 계속 켜져 있어요.**
자세를 보려면 카메라가 필요해요. 일시정지하거나 앱을 끄면 불도 꺼져요.

**바르게 앉아도 계속 경고가 떠요.**
메뉴 막대의 **캘리브레이션**에서 평소 앉는 자리 그대로 다시 기준을 잡거나, 설정에서 **민감도**를 Loose로 바꿔보세요. 노트북이나 모니터 위치를 옮겼다면 다시 캘리브레이션하는 게 가장 효과적이에요.

**집중 모드 중 일시정지가 안 돼요.**
macOS는 집중 모드 상태를 보호된 위치에 저장해요. **시스템 설정 → 개인정보 보호 및 보안**에서 TurtleNeck에 전체 디스크 접근 권한을 줘야 읽을 수 있고, 권한이 없으면 이 옵션은 동작하지 않아요.

**삭제는 어떻게 하나요?**
```bash
brew uninstall --cask --zap turtleneck   # Homebrew로 설치했다면
rm -rf /Applications/TurtleNeck.app      # 그 외
defaults delete com.turtleneck.app       # 설정과 통계까지 지우기
```

## 소스에서 빌드하기

Xcode 15 이상이 필요해요.

```bash
brew install xcodegen
git clone https://github.com/kpryu6/turtleneck.git
cd turtleneck
xcodegen generate
xcodebuild -project TurtleNeck.xcodeproj -scheme TurtleNeck build
```

버그 제보, 아이디어, 새로운 잔소리 문구 모두 [Issues](https://github.com/kpryu6/turtleneck/issues)에 남겨주세요.

## 후원

TurtleNeck은 **무료 오픈소스**예요. 목이 좀 편해졌다면 거북이에게 커피 한 잔 사주세요.

<a href="https://ko-fi.com/kpryu"><img src="https://ko-fi.com/img/githubbutton_sm.svg" /></a>

## 라이선스

[MIT](LICENSE)

---

<div align="center">
<sub>목은 고마워할 거예요. 거북이는 아니겠지만요. 🐢</sub>
</div>
