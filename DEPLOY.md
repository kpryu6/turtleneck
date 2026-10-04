# TurtleNeck 배포 가이드

릴리스는 태그 하나로 끝나요. 빌드, 업로드, Homebrew 업데이트는 GitHub Actions가 해요.

## 새 버전 릴리스

1. `project.yml`에서 버전 올리기
   ```yaml
   MARKETING_VERSION: "1.2.0"
   CURRENT_PROJECT_VERSION: 4   # 매 릴리스마다 +1
   ```
2. `main`에 머지한 뒤 태그 push
   ```bash
   git checkout main && git pull
   git tag -a v1.2.0 -m "TurtleNeck v1.2.0"
   git push origin v1.2.0
   ```

그러면 자동으로 이렇게 돼요.

| 워크플로 | 하는 일 |
|---|---|
| `macos.yml` | 테스트 → `TurtleNeck-1.2.0.dmg` 빌드 → Release에 업로드 |
| `windows.yml` | 테스트 → `TurtleNeck.exe` 빌드 + self-test → `TurtleNeck-Windows-x64.zip` 업로드 |
| `homebrew.yml` | macOS 빌드가 성공하면 DMG의 SHA256을 계산해 [homebrew-turtleneck](https://github.com/kpryu6/homebrew-turtleneck)의 cask를 갱신하고 push |

한 줄 설치(`install.sh`, `install.ps1`)는 항상 최신 Release를 받으므로 따로 할 일이 없어요.

## 확인

```bash
gh run list --limit 5                     # 세 워크플로가 모두 success인지
gh release view v1.2.0                    # DMG와 Windows zip이 붙었는지
curl -fsSL https://raw.githubusercontent.com/kpryu6/turtleneck/main/install.sh | bash
```

## Homebrew 업데이트만 다시 돌리기

자동 업데이트가 실패했거나 다시 해야 할 때:

```bash
gh workflow run homebrew.yml -f tag=v1.2.0
gh workflow run homebrew.yml -f tag=v1.2.0 -f dry_run=true   # push 없이 변경만 확인
```

로컬에서 직접 하려면:

```bash
git clone git@github.com:kpryu6/homebrew-turtleneck.git /tmp/tap
./scripts/update-homebrew-tap.sh v1.2.0 /tmp/tap
cd /tmp/tap && git commit -am "Update TurtleNeck to 1.2.0" && git push
```

## 권한 구조

- `homebrew.yml`은 `HOMEBREW_TAP_DEPLOY_KEY` secret을 써요. homebrew-turtleneck 저장소에만 쓰기 권한이 있는 SSH 배포 키예요.
- 키를 교체하거나 폐기하려면:
  - homebrew-turtleneck → Settings → Deploy keys에서 "turtleneck release workflow" 삭제
  - turtleneck → Settings → Secrets and variables → Actions에서 `HOMEBREW_TAP_DEPLOY_KEY` 삭제
  - 새 키 등록:
    ```bash
    ssh-keygen -t ed25519 -N "" -f /tmp/tapkey
    gh repo deploy-key add /tmp/tapkey.pub --repo kpryu6/homebrew-turtleneck --allow-write --title "turtleneck release workflow"
    gh secret set HOMEBREW_TAP_DEPLOY_KEY --repo kpryu6/turtleneck < /tmp/tapkey
    rm /tmp/tapkey /tmp/tapkey.pub
    ```

## 로컬에서 직접 빌드할 때

```bash
xcodegen generate
./scripts/build-release.sh   # build/TurtleNeck-<버전>.dmg
.\Windows\build.ps1          # Windows에서: Windows\dist\TurtleNeck-Windows-x64.zip
```
