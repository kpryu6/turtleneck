# TurtleNeck 배포 가이드

## GitHub 업로드

```bash
cd ~/projects/TurtleNeck

# Git 초기화 (이미 안 했다면)
git init
git add .
git commit -m "🐢 TurtleNeck v1.0.0 - Initial release"

# GitHub 레포 생성 후
git remote add origin https://github.com/kpryu6/TurtleNeck.git
git branch -M main
git push -u origin main
```

## GitHub Release 생성

```bash
# gh CLI 사용 (brew install gh)
gh release create v1.0.0 build/TurtleNeck-1.0.0.dmg \
  --title "TurtleNeck v1.0.0" \
  --notes "🐢 Initial release! A sassy turtle that fixes your posture."
```

또는 GitHub 웹에서:
1. Releases → Create a new release
2. Tag: `v1.0.0`
3. Title: `TurtleNeck v1.0.0`
4. `build/TurtleNeck-1.0.0.dmg` 파일 업로드
5. Publish

## Homebrew Tap 설정

별도 레포 `homebrew-turtleneck` 생성:

```bash
# 새 레포 생성
mkdir ~/projects/homebrew-turtleneck
cd ~/projects/homebrew-turtleneck
git init
mkdir Casks
cp ~/projects/TurtleNeck/Casks/turtleneck.rb Casks/

# Already set to kpryu6

git add .
git commit -m "Add TurtleNeck cask v1.0.0"
git remote add origin https://github.com/kpryu6/homebrew-turtleneck.git
git branch -M main
git push -u origin main
```

사용자 설치:
```bash
brew tap kpryu6/turtleneck
brew install --cask turtleneck
```

## 업데이트 배포

1. 코드 수정 후 `project.yml`에서 버전 올리기
2. `./scripts/build-release.sh` 실행
3. GitHub Release 생성 + DMG 업로드
4. `homebrew-turtleneck` 레포의 Cask 파일에서 version, sha256, url 업데이트
5. Push

## 체크리스트

- [x] GitHub username: kpryu6
- [x] Cask formula updated
- [ ] GitHub 레포 생성
- [ ] Release 생성 + DMG 업로드
- [ ] homebrew-turtleneck 레포 생성
- [ ] `brew install --cask turtleneck` 테스트
