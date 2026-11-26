# black-screen

macOS에서 **화면만 검게** 만드는 작은 도구입니다. 화면 보호기도, 오버레이 창도 아닙니다.
빌드·테스트 자동화를 돌리는 동안 모니터를 어둡게 해 두고 싶지만, 디스플레이를 끄거나
잠금이 걸리면 안 되고 **스크린샷은 정상으로 찍혀야 할 때** 쓰기 위해 만들었습니다.

A tiny macOS utility that blacks out the display by zeroing the **gamma table**.
It is not a screen saver and not an overlay window, so screen captures still show the real screen.

## 동작 방식 / How it works

- `CGSetDisplayTransferByTable`로 모든 디스플레이의 감마 테이블을 0으로 설정합니다.
- 캡처(`screencapture`, ScreenCaptureKit, 브라우저 스크린샷)는 감마가 적용되기 전의 화면을 읽으므로
  검게 나오지 않습니다. (Night Shift나 f.lux가 스크린샷에 반영되지 않는 것과 같은 원리)
- 화면 보호기나 디스플레이 잠자기가 아니므로 잠금(암호 요구)이 걸리지 않고, 앱이 켜져 있는 동안
  GUI 세션과 시스템은 그대로 깨어 있습니다.
- 앱 프로세스가 끝나면 macOS가 감마를 자동으로 원래대로 돌립니다.
- 화면을 깨우거나 모니터 구성이 바뀌어 감마가 풀리면, 2초마다 다시 적용합니다.

## 설치 / Install

Xcode Command Line Tools(`swiftc`)가 필요합니다.

```sh
git clone https://github.com/baboleevan/black-screen.git
cd black-screen
bash build.sh
```

`~/Applications/Black Screen.app`과 `~/.local/bin/black`이 설치됩니다.

## 사용법 / Usage

| 동작 | 방법 |
|---|---|
| 켜기/끄기(토글) | `Black Screen.app` 더블클릭 또는 Dock 아이콘 클릭 |
| 토글 단축키 | `Ctrl + Opt + Cmd + B` |
| 끄기 | `Esc`를 1.5초 안에 3번 |
| CLI | `black on` / `black off` / `black toggle` / `black status` / `black quit` |

SSH 같은 원격 세션에서도 `black on`, `black off`로 제어할 수 있습니다
(GUI 세션에 로그인된 상태여야 합니다).

## 주의 / Notes

- 켜져 있는 동안 `Esc`는 다른 앱에 전달되지 않습니다(3번 누르기 감지에 전역 단축키를 쓰기 때문).
- 감마 방식이라 모니터에 따라 완전한 검정이 아니라 아주 어둡게 보일 수 있고, 백라이트는 켜져 있습니다.
- 앱은 ad-hoc 서명입니다. 처음 실행할 때 macOS가 확인 창을 띄울 수 있습니다.
- macOS 27(Tahoe 이후)에서 작성했고 Apple Silicon 기준입니다. 다른 버전은 확인하지 않았습니다.

## License

MIT
