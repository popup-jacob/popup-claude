# Base Module 설치 에러 케이스 종합 보고서 (macOS)

> **작성일**: 2026-02-23
> **대상**: macOS 환경에서 Homebrew, Node.js, Git, VS Code, Docker Desktop, Antigravity 설치
> **목적**: 다양한 macOS 환경에서 base 모듈 설치 시 발생 가능한 모든 에러 케이스 정리

---

## 목차

1. [개요](#1-개요)
2. [Homebrew (사전 필수)](#2-homebrew-사전-필수)
   - 2.1 [macOS 버전 호환성](#21-macos-버전-호환성)
   - 2.2 [Apple Silicon vs Intel Mac 차이](#22-apple-silicon-vs-intel-mac-차이)
   - 2.3 [Xcode Command Line Tools](#23-xcode-command-line-tools)
   - 2.4 [권한(Permission) 에러](#24-권한permission-에러)
   - 2.5 [기업/엔터프라이즈 환경 (MDM)](#25-기업엔터프라이즈-환경-mdm)
   - 2.6 [네트워크 문제 (프록시/방화벽/VPN)](#26-네트워크-문제-프록시방화벽vpn)
   - 2.7 [디스크 공간 문제](#27-디스크-공간-문제)
   - 2.8 [SIP (System Integrity Protection)](#28-sip-system-integrity-protection)
   - 2.9 [PATH 설정 문제](#29-path-설정-문제)
   - 2.10 [Rosetta 2 관련 문제](#210-rosetta-2-관련-문제)
   - 2.11 [쉘 설정 문제 (zsh/bash)](#211-쉘-설정-문제-zshbash)
   - 2.12 [FileVault 암호화 관련](#212-filevault-암호화-관련)
   - 2.13 [다중 사용자 계정 문제](#213-다중-사용자-계정-문제)
   - 2.14 [기존 Homebrew 손상/구버전](#214-기존-homebrew-손상구버전)
   - 2.15 [curl/git 실패](#215-curlgit-실패)
3. [Node.js 에러 케이스](#3-nodejs-에러-케이스)
   - 3.1 [Homebrew Node.js vs nvm/fnm/volta 충돌](#31-homebrew-nodejs-vs-nvmfnmvolta-충돌)
   - 3.2 [npm 전역 설치 권한 에러 (EACCES)](#32-npm-전역-설치-권한-에러-eacces)
   - 3.3 [Apple Silicon native vs Rosetta Node.js](#33-apple-silicon-native-vs-rosetta-nodejs)
   - 3.4 [node-gyp / 네이티브 모듈 컴파일 에러](#34-node-gyp--네이티브-모듈-컴파일-에러)
   - 3.5 [Xcode Command Line Tools 요구사항](#35-xcode-command-line-tools-요구사항)
   - 3.6 [Python 의존성 문제 (node-gyp)](#36-python-의존성-문제-node-gyp)
   - 3.7 [PATH 충돌 (다중 Node.js 설치)](#37-path-충돌-다중-nodejs-설치)
   - 3.8 [npm 레지스트리 접근 문제 (기업 프록시/VPN)](#38-npm-레지스트리-접근-문제-기업-프록시vpn)
   - 3.9 [npm 캐시 손상](#39-npm-캐시-손상)
   - 3.10 [brew link 에러](#310-brew-link-에러)
4. [Git 에러 케이스](#4-git-에러-케이스)
   - 4.1 [Apple 기본 Git vs Homebrew Git 충돌](#41-apple-기본-git-vs-homebrew-git-충돌)
   - 4.2 [Xcode Git vs 독립 Git](#42-xcode-git-vs-독립-git)
   - 4.3 [Git Credential Helper 문제 (Keychain)](#43-git-credential-helper-문제-keychain)
   - 4.4 [SSH 키 문제 (macOS Keychain 통합)](#44-ssh-키-문제-macos-keychain-통합)
   - 4.5 [Git LFS 문제](#45-git-lfs-문제)
   - 4.6 [기업 프록시/SSL 인증서 문제](#46-기업-프록시ssl-인증서-문제)
   - 4.7 [대소문자 비구분 파일시스템 (APFS)](#47-대소문자-비구분-파일시스템-apfs)
   - 4.8 [.gitconfig 위치 문제](#48-gitconfig-위치-문제)
   - 4.9 [Git 버전 구식 문제](#49-git-버전-구식-문제)
5. [VS Code 설치 에러](#5-vs-code-설치-에러)
   - 5.1 [Homebrew Cask 설치 실패](#51-homebrew-cask-설치-실패)
   - 5.2 [`code` 명령어 PATH 문제](#52-code-명령어-path-문제)
   - 5.3 [Gatekeeper / Quarantine 문제](#53-gatekeeper--quarantine-문제)
   - 5.4 [확장 (Extension) 설치 실패](#54-확장-extension-설치-실패)
   - 5.5 [VS Code Insiders vs Stable 충돌](#55-vs-code-insiders-vs-stable-충돌)
   - 5.6 [기업 MDM 차단](#56-기업-mdm-차단)
   - 5.7 [Apple Silicon (Rosetta 2) 문제](#57-apple-silicon-rosetta-2-문제)
   - 5.8 [Remote SSH 확장 문제](#58-remote-ssh-확장-문제)
   - 5.9 [터미널 통합 (Shell Detection) 문제](#59-터미널-통합-shell-detection-문제)
   - 5.10 [확장 디렉토리 권한 문제](#510-확장-디렉토리-권한-문제)
6. [Docker Desktop 설치 에러](#6-docker-desktop-설치-에러)
   - 6.1 [Apple Silicon (M1/M2/M3/M4) 호환성 문제](#61-apple-silicon-m1m2m3m4-호환성-문제)
   - 6.2 [Rosetta 2 요구사항](#62-rosetta-2-요구사항)
   - 6.3 [Docker Desktop 라이선스](#63-docker-desktop-라이선스)
   - 6.4 [Virtualization Framework / QEMU 백엔드](#64-virtualization-framework--qemu-백엔드)
   - 6.5 [Docker 데몬 미시작](#65-docker-데몬-미시작)
   - 6.6 [메모리/CPU 할당 문제](#66-메모리cpu-할당-문제)
   - 6.7 [파일 공유 / Bind Mount 성능](#67-파일-공유--bind-mount-성능)
   - 6.8 [네트워크 (VPN 충돌)](#68-네트워크-vpn-충돌)
   - 6.9 [Docker Desktop 업데이트 실패](#69-docker-desktop-업데이트-실패)
   - 6.10 [macOS 버전별 호환성](#610-macos-버전별-호환성)
   - 6.11 [`docker` 명령어 미등록](#611-docker-명령어-미등록)
   - 6.12 [디스크 공간 문제](#612-디스크-공간-문제)
   - 6.13 [기업 프록시 설정](#613-기업-프록시-설정)
7. [Antigravity (Google) 설치 에러](#7-antigravity-google-설치-에러)
   - 7.1 [Homebrew Cask 설치](#71-homebrew-cask-설치)
   - 7.2 [Gatekeeper / Quarantine 차단](#72-gatekeeper--quarantine-차단)
   - 7.3 [`agy` CLI PATH 문제](#73-agy-cli-path-문제)
   - 7.4 [Google 계정 요구사항/제한](#74-google-계정-요구사항제한)
   - 7.5 [Copilot 확장 충돌](#75-copilot-확장-충돌)
   - 7.6 [OpenVSX vs VS Code Marketplace 차이](#76-openvsx-vs-vs-code-marketplace-차이)
8. [Claude Code CLI 설치](#8-claude-code-cli-설치)
   - 8.1 [네이티브 설치 (curl installer)](#81-네이티브-설치-curl-installer)
   - 8.2 [npm 설치 (deprecated)](#82-npm-설치-deprecated)
   - 8.3 [네트워크/프록시 문제](#83-네트워크프록시-문제)
   - 8.4 [Shell/PATH 문제](#84-shellpath-문제)
   - 8.5 [macOS 플랫폼 고유 문제](#85-macos-플랫폼-고유-문제)
   - 8.6 [인증 문제](#86-인증-문제)
   - 8.7 [VS Code 확장 문제 (Claude Code)](#87-vs-code-확장-문제-claude-code)
9. [Gemini CLI 설치](#9-gemini-cli-설치)
   - 9.1 [npm 설치](#91-npm-설치)
   - 9.2 [Homebrew 설치](#92-homebrew-설치)
   - 9.3 [네트워크/프록시 문제](#93-네트워크프록시-문제)
   - 9.4 [인증 문제](#94-인증-문제)
   - 9.5 [할당량 및 지역 제한](#95-할당량-및-지역-제한)
10. [bkit Plugin](#10-bkit-plugin)
    - 10.1 [Claude Code Plugin (MCP 서버)](#101-claude-code-plugin-mcp-서버)
    - 10.2 [Gemini CLI Extensions](#102-gemini-cli-extensions)
11. [환경별 위험도 매트릭스 (종합)](#11-환경별-위험도-매트릭스-종합)
12. [Top 15 빈출 에러 (종합)](#12-top-15-빈출-에러-종합)

---

## 1. 개요

### 설치 대상 프로그램

| Step | 프로그램 | 설치 방법 | 필수 여부 |
|------|---------|----------|----------|
| 0 | Homebrew | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` | **필수** |
| 1 | Node.js LTS | `brew install node` | **필수** |
| 2 | Git | `brew install git` | **필수** |
| 3 | VS Code / Antigravity | `brew install --cask visual-studio-code` | **필수** |
| 4 | Docker Desktop | `brew install --cask docker` | 모듈 필요 시 |
| 5 | Claude Code CLI | `curl -fsSL https://claude.ai/install.sh \| bash` (네이티브, 권장) | **필수** |
| 6 | Gemini CLI | `npm install -g @google/gemini-cli` 또는 `brew install gemini-cli` | **필수** |
| 7 | bkit Plugin | `claude mcp add` / Gemini extensions | **필수** |

### 테스트 대상 환경 유형

- **일반 Mac 사용자**: macOS Sonoma/Sequoia, 기본 설정
- **Apple Silicon (M1/M2/M3/M4)**: ARM64 네이티브
- **Intel Mac**: x86_64 아키텍처
- **기업 환경 (MDM 관리)**: Jamf/Mosyle, 프록시, 방화벽
- **교육기관**: 제한된 사용자 권한
- **개발자 환경**: 기존 nvm/fnm/volta, 다중 Node.js 버전

---

## 2. Homebrew (사전 필수)

> 현재 코드: Homebrew 없으면 `curl` 설치 스크립트 실행 → PATH 추가 → 확인

### 설치 경로 (아키텍처별)

| 플랫폼 | 기본 경로 | 비고 |
|--------|----------|------|
| Apple Silicon (M1/M2/M3/M4) | `/opt/homebrew` | macOS 11+ 전용 |
| Intel x86_64 | `/usr/local` | macOS 10.15+ |

### Homebrew 지원 티어 (2025년 11월 기준)

| 티어 | Apple Silicon | Intel x86_64 | 설명 |
|------|-------------|-------------|------|
| Tier 1 | Sequoia 15, Sonoma 14 | Sequoia 15, Sonoma 14 | 완전 지원, CI 빌드 |
| Tier 3 | Ventura 13 이하 | Ventura 13 이하 | 미지원, 소스 빌드 필요할 수 있음 |

### 2.1 macOS 버전 호환성

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| V1 | macOS Mojave 10.14 이하 | `Homebrew is not supported on this macOS version` | Homebrew 4.x+는 Catalina 10.15 이상 필요 | macOS 업그레이드 필수 |
| V2 | macOS Catalina 10.15 | `Warning: You are using macOS 10.15. We (and Apple) do not provide support for this old version.` | Tier 3 지원. 2026년 9월 이후 완전 미지원 예정 | macOS 업그레이드 권장 |
| V3 | macOS Big Sur 11 | 일부 formula bottle 미제공 경고 | Tier 3. CI 빌드 미수행 | 소스 빌드 fallback. Xcode CLT 최신 유지 |
| V4 | macOS Monterey 12 | `Warning: You are using macOS 12. We do not provide support for this old version.` | 2024년부터 Tier 3 강등 | Sonoma 14 이상으로 업그레이드 |
| V5 | macOS Ventura 13 | 일부 최신 formula에서 bottle 미제공 | 2025년 11월부터 Tier 3 | Sonoma 14 이상 업그레이드 권장 |
| V6 | macOS 베타/프리릴리스 | `We do not provide support for this pre-release version` | Homebrew가 베타 macOS 인식 못함 | 정식 릴리스 대기 또는 `brew update` 후 재시도 |
| V7 | macOS 버전 인식 실패 | `unknown or unsupported macOS version: :dunno` | Homebrew 내부 버전 매핑 테이블에 없음 | `brew update-reset` 실행 |
| V8 | macOS 업그레이드 직후 | `dyld: Library not loaded: /opt/homebrew/opt/icu4c/lib/libicui18n.76.dylib` | 시스템 라이브러리 변경으로 기존 빌드 깨짐 | `xcode-select --install` 후 `brew upgrade` |
| V9 | macOS 업그레이드 직후 | `configure: error: Cannot find libz` | Xcode CLT가 비호환 상태 | `xcode-select --install` 재설치 후 `brew upgrade` |
| V10 | macOS Sequoia 15 (초기) | `Error: Homebrew does not provide support for this macOS version` | Homebrew 4.4.0 이전 미지원 | `brew update`로 4.4.0+ 업데이트 |

#### 향후 지원 중단 예고

| 시점 | 변경 사항 |
|------|----------|
| 2026년 9월 이후 | Catalina 10.15 이하 완전 미지원. Intel x86_64 전체 Tier 3 강등 |
| 2027년 9월 이후 | Big Sur 11 미지원 (Apple Silicon). Intel x86_64 전체 미지원 |

### 2.2 Apple Silicon vs Intel Mac 차이

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| A1 | Apple Silicon에서 `/usr/local`에 설치 시도 | `Cannot install in Homebrew on ARM processor in Intel default prefix (/usr/local)` | ARM Mac에서 Intel 전용 경로에 설치 시도 | `/opt/homebrew`에 새로 설치 |
| A2 | Migration Assistant로 Intel Mac에서 이전 | `/usr/local`과 `/opt/homebrew` 두 개의 Homebrew 공존 | MA가 Intel Mac의 `/usr/local`을 그대로 복사 | Intel 설치 제거 후 ARM만 유지 |
| A3 | Apple Silicon에서 x86_64 터미널 사용 | brew가 `/usr/local` 경로를 사용 | iTerm2 등이 Rosetta 모드로 실행 | "Open using Rosetta" 체크 해제. `arch` 명령으로 `arm64` 확인 |
| A4 | Apple Silicon에서 설치 후 brew 못 찾음 | `zsh: command not found: brew` | `/opt/homebrew/bin`이 PATH에 없음 | `eval "$(/opt/homebrew/bin/brew shellenv)"` 을 `~/.zprofile`에 추가 |
| A5 | Intel Mac에서 `/opt/homebrew`에 설치 시도 | `Homebrew is not (yet) supported on this hardware` | Intel Mac은 `/usr/local`만 지원 | 기본 설치 스크립트 사용 |
| A6 | Universal binary 충돌 | 특정 formula가 arm64 bottle 미제공 | 일부 formula는 arm64 미지원 | `brew install --build-from-source <formula>` 또는 Rosetta 사용 |

### 2.3 Xcode Command Line Tools

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| X1 | CLT 미설치 | `xcode-select: note: No developer tools were found` | Homebrew에 Xcode CLT 필수 | `xcode-select --install` |
| X2 | CLT 설치 UI 실패 | `Can't install the software because it is not currently available from the Software Update server` | Apple 서버 문제 또는 macOS 너무 오래됨 | developer.apple.com/download/all/ 에서 수동 다운로드 |
| X3 | CLT 버전 구버전 | `Your Command Line Tools are too outdated` | macOS 업그레이드 후 CLT 버전 불일치 | `sudo rm -rf /Library/Developer/CommandLineTools && xcode-select --install` |
| X4 | Xcode와 CLT 충돌 | `Your CLT does not support macOS <version>` | 전체 Xcode와 독립 CLT 간 버전 충돌 | `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` |
| X5 | CLT 부분 설치 | `Xcode alone is not sufficient on <macOS version>` | CLT 설치가 불완전 | `sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --install` |
| X6 | Xcode 라이선스 미동의 | `You have not agreed to the Xcode license` | Xcode 설치 후 라이선스 동의 필요 | `sudo xcodebuild -license accept` |
| X7 | 헤드리스 설치 실패 | `xcode-select --install` GUI 팝업 필요한데 SSH 세션 | 원격 세션에서 GUI 팝업 불가 | `softwareupdate --install "Command Line Tools for Xcode-<version>"` |
| X8 | CLT 업데이트 감지 실패 | `brew doctor` 경고는 뜨지만 Software Update에 없음 | macOS 소프트웨어 업데이트 캐시 문제 | Apple Developer 사이트에서 직접 다운로드 |

### 2.4 권한(Permission) 에러

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| P1 | Intel Mac - `/usr/local` 소유권 | `Permission denied @ dir_s_mkdir - /usr/local/Frameworks` | 다른 프로그램이 소유권 변경 | `sudo chown -R $(whoami):admin /usr/local/*` |
| P2 | Intel Mac - zsh compinit | `zsh compinit: insecure directories` | `/usr/local/share/zsh/site-functions` 권한 불일치 | `chmod go-w /usr/local/share` |
| P3 | Apple Silicon - `/opt/homebrew` 소유권 | `Permission denied - /opt/homebrew/Cellar` | 다른 사용자가 설치 또는 sudo로 설치 | `sudo chown -R $(whoami):admin /opt/homebrew` |
| P4 | Cask 설치 - `/Applications` 쓰기 불가 | `Operation not permitted` | MDM 또는 TCC가 Applications 접근 차단 | `brew install --cask <app> --appdir=~/Applications` |
| P5 | `sudo brew` 실행 시도 | `Running Homebrew as root is extremely dangerous and no longer supported.` | root로 Homebrew 실행 시도 | sudo 없이 일반 사용자로 실행 |
| P6 | `/opt/homebrew` 생성 불가 | `Failed to create /opt/homebrew` | `/opt`에 쓰기 권한 없음 | 사용자가 admin 그룹에 속해야 함 |
| P7 | macOS Sequoia TCC 제한 | `Operation not permitted` | TCC가 터미널의 폴더 접근 차단 | Privacy & Security > Full Disk Access에 Terminal.app 추가 |
| P8 | Homebrew Caskroom 소유권 | `Permission denied @ dir_s_mkdir - /opt/homebrew/Caskroom/<app>` | Caskroom 권한 불일치 | `sudo chown -R $(whoami):admin $(brew --caskroom)` |

### 2.5 기업/엔터프라이즈 환경 (MDM)

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| M1 | MDM이 소프트웨어 설치 차단 | `Operation not permitted` | Jamf/Kandji 등이 비인가 소프트웨어 제한 | IT에 Homebrew 허용 요청. Workbrew 검토 |
| M2 | MDM Mac - admin 권한 없음 | sudo 사용 불가 | 일반 사용자는 admin 권한 없음 | IT에 admin 권한 요청 또는 MDM PKG 배포 요청 |
| M3 | Configuration Profile이 터미널 제한 | 특정 명령어 실행 불가 | MDM Profile이 터미널 기능 제한 | IT에 개발자용 Profile 예외 요청 |
| M4 | MDM이 `/opt` 접근 차단 | `mkdir: /opt/homebrew: Operation not permitted` | SIP 강화 또는 MDM 파일시스템 제한 | IT에 디렉토리 생성 허용 요청 |
| M5 | MDM root 계정으로 설치 | 일반 사용자로 사용 불가 | MDM 스크립트가 root로 실행 | 사용자 계정으로 설치: `sudo -u $loggedInUser brew install ...` |
| M6 | 기업 인증서 스토어 충돌 | `curl: (60) SSL certificate problem` | 기업 프록시 SSL 인터셉트 | 기업 CA 인증서를 키체인에 추가 |
| M7 | Homebrew가 root 실행 거부 | `Don't run this as root!` | Homebrew는 root 불가 설계 | Homebrew PKG Installer 사용 |

### 2.6 네트워크 문제 (프록시/방화벽/VPN)

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| N1 | 기업 프록시 | `curl: (7) Failed to connect to raw.githubusercontent.com` | 프록시가 GitHub 차단 | `export http_proxy=http://proxy:port && export https_proxy=http://proxy:port` |
| N2 | 방화벽이 GitHub 차단 | `curl: (28) Connection timed out` | 방화벽이 GitHub 도메인 차단 | `github.com`, `raw.githubusercontent.com`, `ghcr.io` 허용 요청 |
| N3 | VPN 사용 중 | `error: RPC failed; curl 92 HTTP/2 stream was not closed cleanly` | VPN이 HTTP/2 간섭 | VPN 해제 후 설치 또는 `git config --global http.version HTTP/1.1` |
| N4 | SSL 인터셉트 프록시 | `curl failed to verify the legitimacy of the server` | 기업 프록시 SSL MitM | 기업 CA 인증서를 키체인에 추가. `export HOMEBREW_FORCE_BREWED_CURL=1` |
| N5 | `.curlrc` 간섭 | 다양한 curl 에러 | `~/.curlrc`가 curl 동작 변경 | `mv ~/.curlrc ~/.curlrc.bak` 후 재시도 |
| N6 | DNS 해석 실패 | `curl: (6) Could not resolve host` | DNS 서버 문제 | DNS를 `8.8.8.8` 또는 `1.1.1.1`로 변경 |
| N7 | Git clone 연결 끊김 | `fatal: early EOF` | 불안정한 네트워크 | 유선 연결. `git config --global http.postBuffer 524288000` |
| N8 | Homebrew API 다운로드 실패 | `Error: Failure while executing; /usr/bin/curl ... exit status 56` | JSON API 다운로드 실패 | `brew update --force` 재시도 |
| N9 | bottle 다운로드 실패 | `curl: (18) transfer closed with outstanding read data remaining` | bottle 다운로드 중 연결 종료 | 재시도. 소스 빌드 fallback |

### 2.7 디스크 공간 문제

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| D1 | 디스크 공간 부족 | `No space left on device` | Homebrew + formulae에 수 GB 필요 | `brew cleanup` 으로 캐시 정리 |
| D2 | 캐시 비대화 | 디스크 공간 지속 감소 | `~/Library/Caches/Homebrew`에 bottle 보관 | `brew cleanup --prune=all` |
| D3 | APFS 컨테이너 혼동 | `No space left on device` 이지만 전체에는 공간 있음 | APFS 볼륨 간 공간 공유 문제 | Disk Utility에서 볼륨 확인. Time Machine 스냅샷 삭제 |
| D4 | Xcode CLT 설치 시 | `Not enough free disk space` | CLT가 약 1.5-3GB 필요 | 불필요한 파일 삭제 후 설치 |
| D5 | 소스 빌드 시 | `make: *** [all] Error 1` + 공간 부족 로그 | 소스 빌드에 수 GB 임시 공간 필요 | 최소 10GB 여유 공간 확보 |

### 2.8 SIP (System Integrity Protection)

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| S1 | SIP 활성에서 `/usr/local` 접근 | `Operation not permitted` | SIP가 시스템 디렉토리 보호 | Homebrew 기본 스크립트 사용 (SIP 우회 불필요) |
| S2 | SIP 비활성화 상태 | `brew doctor` 경고: `Your system has SIP disabled` | 보안 위험 증가 | SIP 재활성화: Recovery > Terminal > `csrutil enable` |
| S3 | macOS 업그레이드 + SIP 비활성 | 시스템 불안정, 부팅 실패 | SIP 비활성 상태에서 업그레이드 시 문제 | 업그레이드 전 SIP 재활성화 필수 |
| S4 | `/usr/local/bin` 심볼릭 링크 실패 | `Error: Could not symlink ... is not writable` | SIP 또는 다른 프로그램이 권한 변경 | `sudo chown -R $(whoami):admin /usr/local/bin` |

### 2.9 PATH 설정 문제

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| PA1 | Apple Silicon 설치 직후 | `zsh: command not found: brew` | `/opt/homebrew/bin`이 PATH에 없음 | `echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile` |
| PA2 | 터미널 미재시작 | `command not found: brew` | 현재 세션에 미적용 | 터미널 재시작 또는 `source ~/.zprofile` |
| PA3 | Intel PATH가 ARM보다 우선 | 잘못된 brew 버전 실행 | Migration 후 PATH 순서 문제 | `~/.zprofile`에서 `brew shellenv`가 맨 위에 오도록 확인 |
| PA4 | `path_helper` 간섭 | PATH 순서가 예상과 다름 | `/usr/libexec/path_helper`가 PATH 재정렬 | `brew shellenv`를 `path_helper` 이후에 설정 |
| PA5 | formula가 PATH에 없음 | `command not found: <installed-program>` | keg-only이거나 `brew link` 안 됨 | `brew link <formula>` 또는 PATH에 수동 추가 |
| PA6 | bash 사용자 | `bash: brew: command not found` | `~/.bash_profile`에 설정해야 함 | `echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile` |

### 2.10 Rosetta 2 관련 문제

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| R1 | ARM에서 Intel Homebrew 설치 시도 | `Cannot install in Homebrew on ARM processor in Intel default prefix` | ARM Mac에서 `/usr/local`에 설치 시도 | 기본 스크립트 사용 → 자동으로 `/opt/homebrew` |
| R2 | Rosetta 미설치 | `Bad CPU type in executable` | Rosetta 2 없이 x86_64 바이너리 실행 | `softwareupdate --install-rosetta --agree-to-license` |
| R3 | Rosetta 터미널에서 Homebrew 설치 | `/usr/local`에 설치됨 (의도와 다름) | Rosetta 모드 터미널은 x86_64로 인식 | "Open using Rosetta" 해제 후 재설치 |
| R4 | ARM + x86_64 Homebrew 공존 | 패키지 충돌 | 이중 설치 | Intel 버전 제거, ARM만 유지 |
| R5 | formula가 arm64 미지원 | `<formula> is not available for the arm64 architecture` | arm64 빌드 미지원 | `arch -x86_64 /usr/local/bin/brew install <formula>` |

### 2.11 쉘 설정 문제 (zsh/bash)

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| SH1 | zsh PATH 미설정 | `zsh: command not found: brew` | `~/.zprofile`에 `brew shellenv` 미추가 | `echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile` |
| SH2 | `.zshrc`에 설정했지만 login shell에서 안 됨 | 비-인터랙티브 쉘에서 못 찾음 | `.zshrc`는 인터랙티브에서만 로드 | 환경변수는 `~/.zprofile`에 배치 |
| SH3 | bash에서 zsh 설정 무시 | `bash: brew: command not found` | bash는 `~/.bash_profile` 사용 | 쉘에 맞는 설정 파일 사용 |
| SH4 | fish shell | `fish: Unknown command 'brew'` | fish는 POSIX 호환 아님 | `echo 'eval (/opt/homebrew/bin/brew shellenv)' >> ~/.config/fish/config.fish` |
| SH5 | oh-my-zsh PATH 재정렬 | 시스템 버전으로 실행됨 | oh-my-zsh가 PATH 변경 | oh-my-zsh 로드 전에 `brew shellenv` 설정 확인 |
| SH6 | `~/.zshenv` 사용 시 | PATH 순서 뒤집힘 | `path_helper`가 `.zshenv` 설정 덮어씀 | `~/.zshenv` 대신 `~/.zprofile` 사용 |

#### Homebrew `shellenv` 설정 가이드

| 쉘 | 설정 파일 | 명령어 |
|----|----------|--------|
| zsh (기본) | `~/.zprofile` | `echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile` |
| bash | `~/.bash_profile` | `echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile` |
| fish | `~/.config/fish/config.fish` | `echo 'eval (/opt/homebrew/bin/brew shellenv)' >> ~/.config/fish/config.fish` |

> **참고**: Intel Mac은 `/opt/homebrew/bin/brew`를 `/usr/local/bin/brew`로 대체

### 2.12 FileVault 암호화 관련

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| F1 | FileVault 암호화 진행 중 설치 | 설치 극도로 느림 | FileVault 초기 암호화가 I/O 점유 | 암호화 완료 후 설치 |
| F2 | FileVault + 저용량 디스크 | `No space left on device` | 암호화가 추가 공간 사용 | 여유 공간 15% 이상 확보 |
| F3 | 부팅 후 디스크 잠금 | Homebrew 경로 접근 불가 | 잠금 해제 전 스크립트가 접근 | 사용자 로그인 후 실행되도록 설정 |

### 2.13 다중 사용자 계정 문제

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| MU1 | 다른 사용자가 설치한 Homebrew | `Permission denied` 다수 | Homebrew는 단일 사용자용 설계 | 각 사용자별 독립 Homebrew 설치 |
| MU2 | 공유 설치 - 권한 충돌 | `Error: Permission denied` | 여러 사용자가 같은 prefix 접근 | 사용자별 독립 설치 권장 |
| MU3 | `su`/`sudo -u` 전환 후 | 권한 에러 | 환경변수/PATH 불일치 | 각 사용자 계정에서 직접 로그인 |
| MU4 | 게스트 계정 | 설치 실패 | 로그아웃 시 데이터 삭제 | 정식 사용자 계정에서 설치 |

### 2.14 기존 Homebrew 손상/구버전

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| B1 | `brew update` 실패 | `fatal: Could not resolve HEAD to a revision` | git repository 손상 | `brew update-reset` |
| B2 | git 충돌 | `error: Your local changes would be overwritten` | 수동으로 Homebrew 파일 수정 | `cd "$(brew --repository)" && git reset --hard FETCH_HEAD` |
| B3 | Tap 손상 | `Error: Tap <name> already tapped` | tap repository 손상 | `brew tap --repair` 또는 `brew untap && brew tap` |
| B4 | 극도로 오래된 Homebrew | `Error: undefined method` Ruby 에러 | 현재 formula 포맷 불일치 | 완전 재설치: `brew bundle dump`, uninstall, reinstall |
| B5 | Homebrew 1.x→4.x+ 업그레이드 | API 변경 에러 | 4.x에서 JSON API 전환 | 완전 재설치 권장 |
| B6 | `brew doctor` 경고 다수 | 다양한 경고 | 설정 불일치 누적 | `brew doctor` 출력 순차 해결 |
| B7 | Cellar/Caskroom 손상 | `Error: No such keg` | 패키지 파일 부분 삭제 | `brew reinstall <formula>` |
| B8 | macOS 업그레이드 후 전체 깨짐 | 대부분 brew 명령 실패 | 시스템 라이브러리 변경 | `xcode-select --install && brew update && brew upgrade` |

### 2.15 curl/git 실패

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| C1 | 설치 스크립트 다운로드 실패 | `curl: (7) Failed to connect to raw.githubusercontent.com` | 네트워크 차단 | 모바일 핫스팟 시도. DNS 변경 |
| C2 | Git clone 타임아웃 | `fatal: early EOF` | 불안정한 네트워크 | `git config --global http.postBuffer 524288000`. 유선 연결 |
| C3 | SSL 인증서 검증 실패 | `curl: (60) SSL certificate problem: certificate has expired` | 시스템 시간 틀림 | 시스템 시간 자동 동기화 활성화 |
| C4 | GitHub rate limit | `curl: (22) The requested URL returned error: 403` | API 호출 횟수 초과 | `export HOMEBREW_GITHUB_API_TOKEN=<token>` |
| C5 | HTTP/2 프로토콜 문제 | `error: RPC failed; curl 92 HTTP/2 stream was not closed cleanly` | 네트워크 장비가 HTTP/2 미지원 | `git config --global http.version HTTP/1.1` |
| C6 | Git shallow clone 실패 | `fatal: error processing shallow info: 4` | shallow clone 네트워크 문제 | `HOMEBREW_NO_AUTO_UPDATE=1` 설정 후 수동 업데이트 |

### 현재 코드의 대응 수준

```
현재:
  Mac: brew 없으면 curl 설치 → PATH 추가 → 확인
  실패 시: 수동 설치 안내 (URL + PATH 명령)

개선 필요:
  - Apple Silicon vs Intel 자동 감지 + 올바른 PATH 안내
  - Xcode CLT 사전 검사 + 자동 설치
  - Rosetta 모드 터미널 감지 + 경고
  - 기업 MDM/프록시 환경 감지
  - 기존 Homebrew 손상 여부 검사 (brew doctor)
```

---

## 3. Node.js 에러 케이스

### 3.1 Homebrew Node.js vs nvm/fnm/volta 충돌

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| NV1 | nvm + brew node 동시 설치 | `node` 명령이 예상과 다른 버전 실행 | nvm이 shell 초기화 시 PATH를 덮어씀. `~/.nvm/versions/node/` 경로가 우선됨 | **하나만 사용**: `brew uninstall node` 또는 `nvm deactivate && nvm unload` |
| NV2 | fnm + brew node 동시 설치 | `which node`가 fnm 경로 표시, `node -v`가 다른 버전 | fnm의 shim이 Homebrew보다 PATH에서 앞에 위치 | fnm 사용 시 `brew uninstall node`. Homebrew 사용 시 shell rc에서 fnm 초기화 제거 |
| NV3 | volta + brew node 동시 설치 | `npm install -g` 패키지가 실행 안됨 | volta가 자체 shim 시스템 사용 (`~/.volta/bin`), npm global과 충돌 | volta 사용 시 `brew uninstall node`. volta의 `volta install` 사용 |
| NV4 | asdf + brew node | `No version is set for command node` | asdf가 node를 관리하나 shim이 Homebrew node를 가림 | asdf 사용 시 brew node 제거, 또는 asdf에서 node 플러그인 제거 |
| NV5 | nvm + brew로 nvm 설치 | nvm 동작 불안정, `nvm is not compatible with the npm config "prefix"` | **nvm 공식 문서에서 Homebrew를 통한 nvm 설치를 지원하지 않음** | `brew uninstall nvm` 후 공식 설치 스크립트 사용: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh \| bash` |

**감지 로직 권장사항**:
```bash
# 기존 Node.js 버전 매니저 감지
if command -v nvm &>/dev/null || [ -d "$HOME/.nvm" ]; then
  echo "Warning: nvm이 감지되었습니다. brew install node와 충돌할 수 있습니다."
fi
if command -v fnm &>/dev/null; then
  echo "Warning: fnm이 감지되었습니다."
fi
if command -v volta &>/dev/null || [ -d "$HOME/.volta" ]; then
  echo "Warning: volta가 감지되었습니다."
fi
```

---

### 3.2 npm 전역 설치 권한 에러 (EACCES)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| NP1 | `npm install -g` 실행 | `EACCES: permission denied, access '/usr/local/lib/node_modules'` | npm global 디렉토리가 root 소유. 과거 `sudo npm install` 사용으로 인한 소유권 변경 | `sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}` |
| NP2 | npm 캐시 디렉토리 권한 | `EACCES: permission denied, mkdir '/Users/<user>/.npm/_cacache'` | `~/.npm` 디렉토리가 root 소유 (과거 sudo 사용) | `sudo chown -R $(whoami) ~/.npm` |
| NP3 | Apple Silicon + Homebrew | `EACCES: permission denied, access '/opt/homebrew/lib/node_modules'` | `/opt/homebrew` 디렉토리 소유권 문제 | `sudo chown -R $(whoami) /opt/homebrew` |
| NP4 | 다중 사용자 Mac | 다른 사용자가 설치한 npm global 패키지 접근 불가 | node_modules 디렉토리가 다른 사용자 소유 | 사용자별 npm prefix 설정: `npm config set prefix '~/.npm-global'` 후 PATH에 `~/.npm-global/bin` 추가 |

**권장 해결 전략** (npm 공식 문서 기반):
```bash
# 방법 1: npm global 디렉토리를 사용자 디렉토리로 변경
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
# ~/.zshrc에 추가:
export PATH="$HOME/.npm-global/bin:$PATH"

# 방법 2: Homebrew Node.js 디렉토리 소유권 수정
sudo chown -R $(whoami) $(brew --prefix)/lib/node_modules
sudo chown -R $(whoami) $(brew --prefix)/bin
```

---

### 3.3 Apple Silicon native vs Rosetta Node.js

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| AS1 | Rosetta 터미널에서 brew install node | x86_64 Node.js 설치됨 (`/usr/local/bin/node`) | Terminal이 Rosetta 모드로 실행 중이어서 Intel Homebrew 사용 | Terminal.app 정보 > "Rosetta를 사용하여 열기" 해제. `arch` 명령으로 확인 |
| AS2 | ARM64 Node.js + x86_64 npm 패키지 | `Error: Unsupported platform: darwin-arm64` 또는 `mach-o file, but is an incompatible architecture (have 'x86_64', need 'arm64')` | npm 패키지가 Rosetta 환경에서 설치되어 x86_64 바이너리만 포함 | `rm -rf node_modules && npm install` (ARM64 터미널에서) |
| AS3 | esbuild/swc 아키텍처 불일치 | `Error: The package "esbuild-darwin-arm64" could not be found` | package-lock.json이 다른 아키텍처 환경에서 생성됨 | `rm package-lock.json node_modules && npm install` |
| AS4 | 두 종류 Homebrew 동시 설치 | 혼란스러운 동작, 패키지 중복 | `/usr/local` (Intel)과 `/opt/homebrew` (ARM64) 모두 존재 | Intel Homebrew 제거: `/usr/local/bin/brew` 삭제 후 ARM64만 사용 |
| AS5 | node-sass 등 레거시 패키지 | `Unsupported architecture (arm64)` | 레거시 패키지가 ARM64 바이너리 미제공 | 대체 패키지 사용 (예: `node-sass` -> `sass`) |

**아키텍처 확인 명령**:
```bash
# 현재 아키텍처 확인
arch                          # arm64 또는 i386
uname -m                      # arm64 또는 x86_64

# Node.js 아키텍처 확인
node -p "process.arch"        # arm64 또는 x64

# Homebrew 아키텍처 확인
file $(which brew)            # Mach-O 64-bit executable arm64
```

---

### 3.4 node-gyp / 네이티브 모듈 컴파일 에러

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| NG1 | Xcode CLT 미설치 | `gyp: No Xcode or CLT version detected!` | node-gyp가 C++ 컴파일러(clang) 필요 | `xcode-select --install` |
| NG2 | macOS 업그레이드 후 | `gyp ERR! stack Error: Could not find any Python installation to use` 또는 `xcrun: error: invalid active developer path` | macOS 업그레이드가 CLT를 무효화함 | `sudo xcode-select --reset` 또는 `xcode-select --install` 재실행 |
| NG3 | Apple Silicon + 구버전 네이티브 모듈 | `ld: warning: ignoring file, building for macOS-x86_64 but attempting to link with file built for macOS-arm64` | 네이티브 모듈이 ARM64 미지원 또는 아키텍처 혼합 | 모듈 업데이트 또는 `npm rebuild` |
| NG4 | node-gyp + Python 3.12+ | `ModuleNotFoundError: No module named 'distutils'` | Python 3.12에서 distutils 모듈 제거됨 (PEP 632) | **node-gyp v10+로 업데이트**: `npm install -g node-gyp@latest` 또는 `pip3 install setuptools` |
| NG5 | macOS Sonoma + CLT only (Xcode 미설치) | `xcode-select: error: tool 'xcodebuild' requires Xcode` | 일부 node-gyp 버전이 full Xcode를 요구 | `sudo xcode-select -s /Library/Developer/CommandLineTools` 또는 node-gyp 최신 버전으로 업데이트 |
| NG6 | `-march=native` 컴파일러 플래그 | `error: the clang compiler does not support '-march=native'` | Apple Silicon의 clang이 특정 x86 컴파일러 플래그 미지원 | 해당 모듈의 binding.gyp에서 플래그 제거 또는 모듈 업데이트 |

---

### 3.5 Xcode Command Line Tools 요구사항

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| XC1 | CLT 완전 미설치 | `xcode-select: note: no developer tools were found at '/Applications/Xcode.app'` | 깨끗한 macOS에 개발 도구 없음 | `xcode-select --install` (약 1.2GB 다운로드) |
| XC2 | macOS 메이저 업그레이드 후 | `xcrun: error: invalid active developer path (/Library/Developer/CommandLineTools)` | OS 업그레이드가 CLT를 무효화. 설치 기록은 남아있으나 바이너리 무효 | `sudo rm -rf /Library/Developer/CommandLineTools && xcode-select --install` |
| XC3 | Xcode 설치됨 + CLT 미설치 | Xcode가 있으나 CLI 빌드 실패 | Xcode가 있어도 CLT를 별도 설치해야 할 수 있음 | `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` 또는 CLT 별도 설치 |
| XC4 | CLT 버전 불일치 | `Agreeing to the Xcode/iOS license requires admin privileges` | Xcode 업데이트 후 라이선스 동의 필요 | `sudo xcodebuild -license accept` |
| XC5 | `softwareupdate` 으로 CLT 업데이트 안됨 | CLT 업데이트가 소프트웨어 업데이트 목록에 없음 | Apple의 소프트웨어 업데이트 카탈로그 문제 | Apple Developer 사이트에서 직접 다운로드: https://developer.apple.com/download/all/ |

**CLT 상태 확인**:
```bash
# CLT 설치 확인
xcode-select -p                    # 설치 경로 표시
xcode-select --version             # 버전 확인
pkgutil --pkg-info=com.apple.pkg.CLTools_Executables  # 상세 정보

# CLT에 포함된 도구 확인
gcc --version     # Apple clang version
make --version    # GNU Make
```

---

### 3.6 Python 의존성 문제 (node-gyp)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| PY1 | Python 3.12+ (Homebrew) | `ModuleNotFoundError: No module named 'distutils'` | Python 3.12에서 `distutils` 제거됨. node-gyp가 의존 | `npm install -g node-gyp@latest` (v10+는 distutils 불필요) 또는 `pip3 install setuptools` |
| PY2 | Python 미설치 | `gyp ERR! find Python - Python is not set` | macOS에 Python이 없음 (최신 macOS는 Python 2 제거됨) | `brew install python@3.11` 또는 Xcode CLT 설치 (Python 3 포함) |
| PY3 | 다중 Python 버전 | node-gyp가 잘못된 Python 버전 사용 | PATH에 여러 Python이 있어 node-gyp가 호환되지 않는 버전 선택 | `npm config set python /usr/bin/python3` 또는 `export npm_config_python=$(which python3)` |
| PY4 | Python 2 / Python 3 혼재 | `gyp ERR! stack Error: Could not find any Python installation to use` | node-gyp v5+는 Python 3.6+ 필요. Python 2만 있으면 실패 | Python 3 설치: `brew install python` |
| PY5 | macOS 시스템 Python 제거됨 | `/usr/bin/python: No such file or directory` | macOS 12.3+에서 Python 2(`/usr/bin/python`) 제거 | `brew install python` 후 `npm config set python $(which python3)` |

---

### 3.7 PATH 충돌 (다중 Node.js 설치)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| PA1 | nvm + Homebrew node | `node -v` 결과가 예상과 다름 | `~/.nvm` 경로가 PATH에서 Homebrew보다 앞에 있음 | 하나만 사용. `brew uninstall node` 권장 (nvm 사용 시) |
| PA2 | Intel Homebrew + ARM Homebrew | 두 개의 `node` 바이너리 존재 | `/usr/local/bin/node` (Intel)과 `/opt/homebrew/bin/node` (ARM) 충돌 | Intel Homebrew 제거: `/usr/local/Homebrew` 삭제 |
| PA3 | 수동 설치 + Homebrew | `env: node: No such file or directory` (스크립트에서) | non-interactive shell에서 PATH가 달라서 node를 못 찾음 | `~/.zshenv`에 PATH 설정 추가 (`.zshrc` 대신) |
| PA4 | npm global bin과 PATH | `npm install -g`로 설치한 명령어 실행 안됨 | npm global bin 경로가 PATH에 없음 | `export PATH="$(npm config get prefix)/bin:$PATH"` 를 shell rc에 추가 |
| PA5 | volta shim 충돌 | `volta`로 설치한 패키지가 Homebrew node에서 안 보임 | volta가 자체 shim 디렉토리(`~/.volta/bin`) 사용 | volta와 Homebrew node 중 하나만 사용 |

**PATH 디버깅 명령**:
```bash
# 현재 node 위치와 버전 확인
which -a node          # 모든 node 경로 표시
node -v                # 현재 활성 버전
npm config get prefix  # npm global 설치 경로

# PATH 순서 확인
echo $PATH | tr ':' '\n'

# 어떤 shell 설정 파일이 PATH를 변경하는지 확인
grep -n 'PATH\|nvm\|fnm\|volta' ~/.zshrc ~/.zprofile ~/.zshenv ~/.bash_profile 2>/dev/null
```

---

### 3.8 npm 레지스트리 접근 문제 (기업 프록시/VPN)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| NR1 | 기업 프록시 | `npm ERR! network request to https://registry.npmjs.org failed, reason: connect ETIMEDOUT` | HTTP/HTTPS 프록시가 직접 연결 차단 | `npm config set proxy http://proxy.company.com:8080` 및 `npm config set https-proxy http://proxy.company.com:8080` |
| NR2 | SSL 검사 프록시 (MITM) | `npm ERR! code UNABLE_TO_VERIFY_LEAF_SIGNATURE` | 기업 보안 솔루션이 SSL 트래픽 가로채기하여 인증서 교체 | **권장**: `npm config set cafile /path/to/corporate-ca.pem`. **임시 우회**: `npm config set strict-ssl false` (보안 위험) |
| NR3 | VPN + split tunneling | `npm ERR! code ECONNREFUSED` 또는 매우 느린 설치 | VPN이 npm 레지스트리 트래픽을 잘못 라우팅 | VPN split tunneling 설정에서 `registry.npmjs.org` 제외 요청 |
| NR4 | DNS 해석 실패 | `npm ERR! code EAI_AGAIN` 또는 `getaddrinfo ENOTFOUND registry.npmjs.org` | DNS 서버가 응답 안 함 | DNS 확인: `nslookup registry.npmjs.org`. DNS 서버 변경 (8.8.8.8 등) |
| NR5 | 방화벽이 443 포트 차단 | `npm ERR! network socket hang up` | 기업 방화벽이 특정 도메인/포트 차단 | IT 관리자에게 `registry.npmjs.org:443` 허용 요청 |
| NR6 | 사내 npm 레지스트리 | 공용 패키지 못 찾음 | `.npmrc`에 사내 레지스트리만 설정됨 | `npm config set registry https://registry.npmjs.org/` 또는 사내 레지스트리에서 공용 패키지 미러링 확인 |

**프록시 설정 확인 및 해결**:
```bash
# 현재 npm 설정 확인
npm config list
npm config get proxy
npm config get https-proxy
npm config get registry

# 기업 CA 인증서 설정
npm config set cafile /etc/ssl/certs/corporate-ca-bundle.crt

# 프록시 설정
npm config set proxy http://proxy.company.com:8080
npm config set https-proxy http://proxy.company.com:8080
```

---

### 3.9 npm 캐시 손상

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| NC1 | 설치 중 네트워크 끊김 | `npm ERR! code EINTEGRITY` `sha512-... integrity checksum failed` | 다운로드가 불완전하여 캐시된 패키지의 해시가 불일치 | `npm cache clean --force && npm install` |
| NC2 | npm 버전 업그레이드 후 | `npm ERR! Unexpected end of JSON input` | 구버전 npm 캐시 형식이 신버전과 호환 안됨 | `npm cache verify` 또는 `npm cache clean --force` |
| NC3 | 디스크 공간 부족으로 캐시 손상 | `ENOSPC: no space left on device` 반복 | npm 캐시(`~/.npm/_cacache`)가 디스크 공간 소진 | 디스크 공간 확보 후 `npm cache clean --force` |
| NC4 | `package-lock.json` 불일치 | `EINTEGRITY` 에러가 특정 패키지에서만 발생 | package-lock.json의 integrity 해시가 현재 레지스트리 버전과 불일치 | `rm package-lock.json && npm install` |
| NC5 | 권한 문제로 캐시 쓰기 실패 | `EACCES: permission denied, open '/Users/<user>/.npm/_cacache/...'` | `~/.npm` 디렉토리 일부가 root 소유 | `sudo chown -R $(whoami) ~/.npm` |

**캐시 관리 명령**:
```bash
# 캐시 상태 확인
npm cache verify

# 캐시 강제 정리
npm cache clean --force

# 캐시 위치 확인
npm config get cache    # 기본: ~/.npm

# 완전 클린 설치
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

---

### 3.10 brew link 에러

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| BL1 | 이전 Node.js 설치 잔존 | `Error: Could not symlink bin/node. Target /opt/homebrew/bin/node already exists.` | 이전 수동 설치 또는 다른 방법으로 설치된 파일이 남아있음 | `brew link --overwrite node` |
| BL2 | keg-only 수식 | `Warning: node is keg-only and must be linked with --force` | 특정 버전의 node가 keg-only로 설치됨 (예: `node@18`) | `brew link --force node@18` 후 PATH에 추가: `export PATH="$(brew --prefix node@18)/bin:$PATH"` |
| BL3 | 디렉토리 권한 문제 | `Error: Could not symlink share/man/man1/node.1. /opt/homebrew/share/man/man1 is not writable.` | Homebrew 디렉토리의 소유권이 현재 사용자가 아님 | `sudo chown -R $(whoami) $(brew --prefix)/share/man` |
| BL4 | 다른 node 버전이 이미 link됨 | `Error: node conflicts with node@20` | 여러 node 버전이 설치되어 충돌 | `brew unlink node@20 && brew link node` |
| BL5 | Homebrew prefix 불일치 | `Error: Could not symlink` 반복 실패 | ARM/Intel Homebrew 혼재로 prefix 경로 충돌 | `brew doctor` 실행하여 문제 진단 후 하나의 Homebrew만 사용 |

**brew link 진단 및 해결**:
```bash
# Homebrew 상태 진단
brew doctor

# 현재 link 상태 확인
brew list --versions node
brew info node

# link 강제 수행
brew link --overwrite --force node

# 모든 link 해제 후 재연결
brew unlink node && brew link node
```

---

## 4. Git 에러 케이스

### 4.1 Apple 기본 Git vs Homebrew Git 충돌

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| AG1 | brew install git 후 | `which git`가 여전히 `/usr/bin/git` 표시 | macOS 기본 `/usr/bin/git`이 PATH에서 Homebrew보다 앞에 있음 | shell 재시작 또는 `eval "$(/opt/homebrew/bin/brew shellenv)"` 확인. PATH에서 Homebrew가 `/usr/bin`보다 앞에 와야 함 |
| AG2 | Apple Silicon에서 | `git --version` 이 Apple Git 표시 (예: `git version 2.39.5 (Apple Git-154)`) | `/opt/homebrew/bin`이 PATH에 없음 | `~/.zprofile`에 `eval "$(/opt/homebrew/bin/brew shellenv)"` 추가 |
| AG3 | 두 Git 버전 혼재 사용 | Git 설정/hook이 예상과 다르게 동작 | Apple Git과 Homebrew Git이 다른 설정 경로를 참조할 수 있음 | `which -a git`으로 모든 git 경로 확인 후 원하는 것만 PATH에 유지 |
| AG4 | IDE/에디터에서 다른 Git 사용 | VS Code 등이 시스템 Git(`/usr/bin/git`) 사용 | IDE가 별도 PATH 또는 하드코딩된 경로 사용 | VS Code: `"git.path": "/opt/homebrew/bin/git"` 설정 |

---

### 4.2 Xcode Git vs 독립 Git

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| XG1 | Xcode 설치됨 | `/usr/bin/git`이 Xcode의 Git shim | `/usr/bin/git`은 실제 바이너리가 아닌 Xcode CLT로의 shim | Homebrew Git 사용 시 PATH 우선순위 확인 |
| XG2 | Xcode 업데이트 후 | `xcrun: error: invalid active developer path` | Xcode 업데이트가 developer path를 변경 | `sudo xcode-select --reset` |
| XG3 | Xcode 삭제 후 | `git` 명령 실행 시 Xcode 설치 다이얼로그 표시 | `/usr/bin/git` shim이 Xcode/CLT를 요구 | `xcode-select --install` 또는 `brew install git` |
| XG4 | Xcode CLT 버전 < Git 최소 요구사항 | 특정 Git 기능 미작동 | Apple이 CLT에 포함하는 Git 버전이 최신이 아닐 수 있음 (보통 3~6개월 지연) | `brew install git`으로 최신 버전 설치 |

---

### 4.3 Git Credential Helper 문제 (Keychain)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| GC1 | 비밀번호 변경 후 | `remote: Invalid username or password. fatal: Authentication failed` | macOS Keychain에 저장된 이전 자격 증명이 만료/변경됨 | Keychain Access.app에서 `github.com` 항목 삭제 또는 `git credential-osxkeychain erase` |
| GC2 | GitHub 2FA 활성화 후 | `remote: Support for password authentication was removed` | 비밀번호 대신 Personal Access Token(PAT) 또는 SSH 키 필요 | SSH 키 설정 또는 Git Credential Manager(GCM) 설치: `brew install --cask git-credential-manager` |
| GC3 | credential.helper 미설정 | 매번 비밀번호 입력 요구 | Git이 macOS Keychain을 사용하도록 설정되지 않음 | `git config --global credential.helper osxkeychain` 또는 GCM 사용 |
| GC4 | Homebrew Git + osxkeychain | `git: 'credential-osxkeychain' is not a git command` | Homebrew Git에 osxkeychain helper가 포함되지 않았거나 경로 불일치 | `brew install git` (최신 버전은 포함됨) 또는 GCM 설치 |
| GC5 | 원격 접속 시 Keychain 미잠금 | `error: unable to read askpass response` | SSH/원격 세션에서 macOS Keychain이 잠겨있음 | `security unlock-keychain ~/Library/Keychains/login.keychain` 또는 SSH 키 기반 인증 사용 |

**Credential 설정 권장사항**:
```bash
# 방법 1: Git Credential Manager (권장, 2FA/OAuth 지원)
brew install --cask git-credential-manager
git config --global credential.helper manager

# 방법 2: macOS Keychain (기본)
git config --global credential.helper osxkeychain

# 자격 증명 초기화
echo -e "protocol=https\nhost=github.com" | git credential-osxkeychain erase
```

---

### 4.4 SSH 키 문제 (macOS Keychain 통합)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| SK1 | macOS 재시작 후 SSH 키 분실 | `Permission denied (publickey)` (재부팅 후 발생) | ssh-agent가 재시작 시 키를 잊음 | `~/.ssh/config`에 `AddKeysToAgent yes` 및 `UseKeychain yes` 추가 |
| SK2 | `ssh-add --apple-use-keychain` 미작동 | `ssh-add: illegal option -- apple-use-keychain` | Homebrew에서 설치한 OpenSSH가 Apple 확장 옵션 미지원 | Apple 기본 `/usr/bin/ssh-add` 사용: `/usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519` |
| SK3 | `-K` / `-A` 플래그 deprecated | `WARNING: -K and -A flags are deprecated` | macOS Monterey+에서 플래그 이름 변경 | `-K` -> `--apple-use-keychain`, `-A` -> `--apple-load-keychain` 사용 |
| SK4 | SSH config 미설정 | 매번 passphrase 입력 요구 | SSH config에 Keychain 통합 미설정 | 아래 SSH config 추가 |
| SK5 | 잘못된 키 알고리즘 | `no mutual signature algorithm` | 구버전 RSA 키 (1024bit) 미지원 | ED25519 키 생성: `ssh-keygen -t ed25519 -C "email@example.com"` |
| SK6 | `~/.ssh` 디렉토리 권한 | `Permissions 0777 for '/Users/<user>/.ssh/id_ed25519' are too open.` | SSH 키 파일 권한이 너무 열려있음 | `chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_* && chmod 644 ~/.ssh/*.pub` |

**SSH config 권장 설정** (`~/.ssh/config`):
```
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
```

**SSH 키 생성 및 등록**:
```bash
# ED25519 키 생성 (권장)
ssh-keygen -t ed25519 -C "your_email@example.com"

# macOS Keychain에 추가 (Apple SSH 사용 필수)
/usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# 연결 테스트
ssh -T git@github.com
```

---

### 4.5 Git LFS 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| LF1 | Git LFS 미설치 | `git: 'lfs' is not a git command. See 'git --help'.` | git-lfs가 설치되지 않음 | `brew install git-lfs && git lfs install` |
| LF2 | Homebrew Git + Xcode Git 경로 불일치 | 터미널에서 `git lfs` 작동하나 스크립트/IDE에서 안됨 | 스크립트가 `/usr/bin/git`을 사용하는데 git-lfs가 Homebrew 경로에만 있음 | symlink 생성: `sudo ln -s "$(which git-lfs)" "$(git --exec-path)/git-lfs"` |
| LF3 | `git lfs install` 미실행 | LFS 파일이 포인터 파일로만 다운로드됨 (수 바이트 텍스트) | `git lfs install`로 hooks 등록 안됨 | `git lfs install && git lfs pull` |
| LF4 | LFS 대역폭/저장소 한도 초과 | `batch response: This repository is over its data quota` | GitHub LFS 무료 한도 (1GB 저장소, 1GB/월 대역폭) 초과 | LFS 데이터 팩 구매 또는 불필요한 LFS 파일 정리 |
| LF5 | LFS + 기업 프록시 | `LFS: client error 407` | 프록시 인증 필요 | `git config --global http.proxy http://user:pass@proxy:8080` |

---

### 4.6 기업 프록시/SSL 인증서 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| GS1 | SSL 검사 프록시 | `SSL certificate problem: unable to get local issuer certificate` | 기업 프록시가 SSL 트래픽을 가로채고 자체 인증서로 교체 | `git config --global http.sslCAInfo /path/to/corporate-ca.pem` |
| GS2 | 자체 서명 인증서 | `SSL certificate problem: self-signed certificate in certificate chain` | 사내 Git 서버가 자체 서명 인증서 사용 | 기업 CA 인증서를 시스템 키체인에 추가 또는 `git config --global http.sslCAInfo` 설정 |
| GS3 | 기업 프록시 인증 | `Proxy Authentication Required (407)` | 프록시가 NTLM/Basic 인증 요구 | `git config --global http.proxy http://user:password@proxy.company.com:8080` |
| GS4 | SSL 비활성화 (비권장) | 보안 경고 무시 | SSL 검증을 비활성화 | `git config --global http.sslVerify false` (**보안 위험! 임시 디버깅 용도로만 사용**) |
| GS5 | macOS Keychain + 기업 CA | `SecTrustEvaluateWithError: The certificate chain is not trusted` | macOS 시스템 신뢰 저장소에 기업 CA가 없음 | Keychain Access.app > 시스템 키체인에 기업 CA 인증서 추가 후 "항상 신뢰" 설정 |

**기업 환경 SSL 설정**:
```bash
# 기업 CA 인증서 내보내기 (브라우저에서)
# 1. 브라우저로 Git 서버 접속
# 2. 자물쇠 아이콘 > 인증서 보기 > 루트 CA 내보내기 (PEM 형식)

# Git에 CA 인증서 등록
git config --global http.sslCAInfo /usr/local/share/ca-certificates/corporate-ca.pem

# 특정 호스트에만 적용
git config --global http.https://git.company.com/.sslCAInfo /path/to/corporate-ca.pem
```

---

### 4.7 대소문자 비구분 파일시스템 (APFS)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| CF1 | 파일명 대소문자만 변경 | `git mv README.md Readme.md` 가 변경 감지 안됨 | macOS APFS는 기본적으로 case-insensitive | 2단계로 이름 변경: `git mv README.md temp.md && git mv temp.md Readme.md` |
| CF2 | Linux에서 만든 repo clone | 같은 이름 다른 대소문자 파일 (예: `File.js`와 `file.js`)이 하나만 보임 | APFS가 대소문자를 구분하지 않아 파일 덮어쓰기 | `git config --global core.ignorecase false` 설정 (감지는 가능하나 파일시스템 제한 해결 불가) |
| CF3 | CI/CD (Linux)에서 실패 | macOS에서는 빌드 성공하나 Linux CI에서 import 경로 에러 | `import './Component'` vs `'./component'` 가 macOS에서는 같지만 Linux에서는 다름 | 임포트 경로 대소문자를 파일명과 정확히 일치시킴. ESLint `import/no-unresolved` 규칙 활성화 |
| CF4 | 대소문자 다른 디렉토리 | `src/Components/` 와 `src/components/` 충돌 | APFS에서 같은 디렉토리로 취급됨 | 디렉토리 이름 통일. 대소문자 구분 볼륨 생성 (Disk Utility > APFS Case-sensitive 볼륨) |

**예방 조치**:
```bash
# Git 대소문자 감지 활성화
git config --global core.ignorecase false

# 대소문자 구분 볼륨 생성 (개발 전용)
# Disk Utility > 볼륨 추가 > APFS (Case-sensitive)
# 또는 CLI:
diskutil apfs addVolume disk1 "APFS (Case-sensitive)" DevCode
```

---

### 4.8 .gitconfig 위치 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| GF1 | XDG_CONFIG_HOME 설정 사용 | `~/.gitconfig` 설정이 무시됨 | `$XDG_CONFIG_HOME/git/config`가 존재하면 `~/.gitconfig`보다 우선 | 하나의 위치만 사용. `git config --list --show-origin`으로 어떤 파일이 적용되는지 확인 |
| GF2 | `~/.config/git/config` 존재 | 설정이 예상과 다르게 적용됨 | XDG_CONFIG_HOME이 설정되지 않으면 `~/.config`가 기본값. `~/.gitconfig`가 없으면 이 파일 사용 | `git config --list --show-origin --show-scope`로 설정 출처 확인 |
| GF3 | 시스템 gitconfig 충돌 | `includeIf` 등이 예상대로 안됨 | `/etc/gitconfig` 또는 Homebrew의 `$(brew --prefix)/etc/gitconfig`이 존재 | `git config --list --show-origin`으로 모든 설정 파일 위치 확인 |
| GF4 | 기업 MDM이 gitconfig 배포 | 사용자 설정이 덮어씌워짐 | MDM이 `/etc/gitconfig` 또는 시스템 레벨 설정을 관리 | `--local` 플래그로 프로젝트별 설정 사용: `git config --local user.email "email@example.com"` |

**gitconfig 위치 우선순위** (낮은 우선순위 -> 높은 우선순위):
```
1. $(brew --prefix)/etc/gitconfig          # Homebrew 시스템
2. /etc/gitconfig                           # 시스템
3. ~/.gitconfig 또는 $XDG_CONFIG_HOME/git/config  # 글로벌
4. .git/config                              # 로컬 (프로젝트)
5. .git/config.worktree                     # Worktree
6. 명령줄 옵션 (-c)                          # 일회성
```

```bash
# 모든 설정과 출처 확인
git config --list --show-origin --show-scope

# 특정 설정 출처 확인
git config --show-origin --show-scope user.email
```

---

### 4.9 Git 버전 구식 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| GV1 | Apple 기본 Git 사용 | 최신 Git 기능 (예: `git switch`, `git restore` 초기 지원) 미작동 | Apple이 제공하는 Git은 최신 릴리즈보다 3~6개월 뒤처질 수 있음 | `brew install git` 으로 최신 버전 설치 |
| GV2 | `git` 첫 실행 시 설치 팝업 | "The git command requires the command line developer tools. Would you like to install them?" | Git 미설치 (깨끗한 macOS). `/usr/bin/git`이 CLT shim | "Install" 클릭하여 Xcode CLT 설치 또는 `brew install git` |
| GV3 | macOS 메이저 업그레이드 후 | `xcrun: error: invalid active developer path` | OS 업그레이드가 CLT를 무효화하여 git shim 동작 중단 | `xcode-select --install` 재실행 |
| GV4 | CLT 업데이트 안됨 | `softwareupdate -l`에 CLT 업데이트 안 보임 | Apple 소프트웨어 업데이트 카탈로그 문제 | Apple Developer 사이트에서 직접 다운로드: https://developer.apple.com/download/all/ |
| GV5 | `git -C` 등 상대적으로 새로운 옵션 미지원 | `unknown option: -C` | Apple Git 버전이 너무 오래됨 | `brew install git` |

**Git 버전 확인 및 업데이트**:
```bash
# Apple Git 버전 확인
/usr/bin/git --version          # git version 2.x.x (Apple Git-xxx)

# Homebrew Git 버전 확인
/opt/homebrew/bin/git --version  # git version 2.x.x (Homebrew 최신)
# 또는 Intel Mac:
/usr/local/bin/git --version

# Homebrew로 최신 Git 설치
brew install git

# 현재 사용 중인 Git 확인
which git && git --version
```

---

## 5. VS Code 설치 에러

### 5.1 Homebrew Cask 설치 실패

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| VC1 | Homebrew 미설치 | `zsh: command not found: brew` | macOS에 Homebrew가 설치되지 않음 | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` 실행. Apple Silicon의 경우 설치 후 `eval "$(/opt/homebrew/bin/brew shellenv)"` 를 `~/.zprofile` 에 추가 |
| VC2 | Homebrew 버전 오래됨 | `Error: Cask 'visual-studio-code' is unreadable` 또는 다운로드 URL 404 | 로컬 Homebrew 메타데이터가 최신 cask 정보와 맞지 않음 | `brew update` 실행 후 재시도 |
| VC3 | SHA256 mismatch | `Error: SHA256 mismatch. Expected: ... Actual: ...` | 소스 서버에서 파일이 업데이트되었으나 Homebrew 캐시가 이전 해시를 참조 | `brew update-reset && brew update` 후 재시도. 또는 `brew install --cask visual-studio-code --force` |
| VC4 | 기존 VS Code 존재 | `Error: It seems there is already an App at '/Applications/Visual Studio Code.app'` | 수동 설치 등으로 이미 VS Code가 존재 | `brew install --cask visual-studio-code --force` 또는 기존 앱 삭제 후 재시도 |
| VC5 | VSCodium과 충돌 | `Error: Cask 'vscodium' conflicts with 'visual-studio-code'` | VSCodium과 VS Code cask가 상호 충돌로 정의됨 | 둘 중 하나를 uninstall 후 원하는 것을 설치 |
| VC6 | Xcode CLT 미설치 | `Error: No developer tools installed. Install the Command Line Tools` | Homebrew 동작에 필요한 Xcode Command Line Tools 없음 | `xcode-select --install` 실행 |
| VC7 | 디스크 공간 부족 | `Error: No space left on device` | VS Code ~500MB, 확장 포함 시 더 필요 | 디스크 공간 확보 후 재시도 |
| VC8 | macOS Catalina (10.15) 이하 | 설치는 되지만 실행 불가 또는 설치 실패 | VS Code 1.97 이후 macOS 10.15 지원 종료 | macOS 업그레이드 또는 VS Code 1.97 이하 수동 설치 |
| VC9 | Apple Silicon + 잘못된 아키텍처 | Rosetta 에뮬레이션 경고, 느린 성능 | Intel(x64) 버전을 Apple Silicon에서 실행 중 | `brew install --cask visual-studio-code`는 자동으로 ARM64 버전 설치. 수동 설치 시 "Apple Silicon" 빌드 다운로드 확인 |
| VC10 | 기업 프록시/방화벽 | `curl: (35) SSL connect error` 또는 다운로드 타임아웃 | 기업 네트워크에서 CDN 차단 | `export HOMEBREW_PROXY=http://proxy:port` 설정. 또는 `ALL_PROXY` 환경변수 설정 |

---

### 5.2 `code` 명령어 PATH 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| VP1 | 설치 직후 | `zsh: command not found: code` | VS Code가 `code` symlink를 자동 생성하지 않음 (macOS 전용 동작) | VS Code 내에서 `Cmd+Shift+P` > "Shell Command: Install 'code' command in PATH" 실행 |
| VP2 | Applications 폴더 외 실행 | `code` 명령이 재부팅 후 동작 안 함 | macOS App Translocation이 임시 경로에서 앱을 실행하여 symlink 경로가 깨짐 | VS Code를 반드시 `/Applications/` 폴더로 이동 후 Shell Command 재설치 |
| VP3 | PATH 수동 설정 | 터미널 재시작 후 `code` 동작 안 함 | `~/.zshrc` 에 PATH 추가를 안 했거나 잘못된 경로 사용 | `~/.zshrc`에 `export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"` 추가 |
| VP4 | 여러 쉘 사용 | bash에서는 되는데 zsh에서 안 됨 | 쉘별로 다른 프로파일 파일 사용 | zsh: `~/.zshrc`, bash: `~/.bash_profile`, fish: `~/.config/fish/config.fish` 각각에 PATH 추가 |
| VP5 | 영구 symlink 생성 | 재부팅/업데이트마다 `code` 사라짐 | VS Code 업데이트 시 내부 경로가 변경될 수 있음 | `sudo ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code` 로 영구 symlink 생성 |

---

### 5.3 Gatekeeper / Quarantine 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| VG1 | 직접 다운로드 (비 Homebrew) | `"Visual Studio Code" is damaged and can't be opened` | macOS가 다운로드한 .app에 quarantine 속성을 부여 | `sudo xattr -r -d com.apple.quarantine "/Applications/Visual Studio Code.app"` |
| VG2 | Gatekeeper 차단 | `"Visual Studio Code" can't be opened because Apple cannot check it for malicious software` | Gatekeeper가 서명 검증 실패 | 시스템 환경설정 > 보안 및 개인 정보 > "확인 없이 열기" 클릭. 또는 Control+클릭 > 열기 |
| VG3 | macOS Sequoia 강화된 보안 | 이전 방법으로 우회 불가 | Sequoia에서 `spctl --master-disable` 후에도 시스템 설정에서 확인 필요 | 시스템 설정 > 개인정보 및 보안에서 직접 허용. Homebrew `--no-quarantine` 플래그 사용: `brew install --cask visual-studio-code --no-quarantine` |
| VG4 | Full Disk Access 필요 | `Operation not permitted` (xattr 제거 시) | 최신 macOS에서 Terminal에 Full Disk Access 권한 없음 | 시스템 설정 > 개인정보 및 보안 > Full Disk Access > Terminal.app 추가 |

---

### 5.4 확장 (Extension) 설치 실패

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| VE1 | `code` 명령 미등록 | `code: command not found` 이후 확장 설치 불가 | CLI에서 확장 설치하려면 `code` 명령이 PATH에 있어야 함 | 위 VP1 해결 후 재시도 |
| VE2 | 네트워크 오류 | `Error: connect ENOENT` 또는 `Failed to fetch extension` | 마켓플레이스 서버 연결 불가 (프록시, DNS) | VS Code 설정에서 `http.proxy` 설정. 또는 기업 방화벽에서 `marketplace.visualstudio.com` 허용 |
| VE3 | 권한 문제 | `EACCES: permission denied, open '.../.vscode/extensions/extensions.json'` | `~/.vscode/extensions` 디렉토리 소유권 문제 (sudo로 VS Code 실행 이력 등) | `sudo chown -R $USER:staff ~/.vscode && chmod -R u+rwX ~/.vscode` |
| VE4 | VSIX 파일 손상 | `End of central directory record signature not found` | 번들 확장 VSIX 파일이 손상됨 | VSIX 파일 재다운로드 후 `code --install-extension <path>.vsix` |
| VE5 | 마켓플레이스 미서명 확장 | `Extension is not signed by the marketplace` | 확장 발행자가 서명하지 않은 확장 | VS Code 설정에서 `extensions.verifySignature` 를 `false` 로 변경 (보안 위험 인지 필요) |
| VE6 | 기업 확장 제한 정책 | 확장 설치 차단 메시지 | MDM 정책으로 `extensions.allowed` 에 포함되지 않은 확장 차단 | IT 관리자에게 해당 확장 허용 요청 |
| VE7 | 호환성 문제 | `Incompatible: requires VS Code ^x.y.z` | 확장이 요구하는 VS Code 버전이 설치된 버전보다 높음 | VS Code 업데이트 후 재시도 |

---

### 5.5 VS Code Insiders vs Stable 충돌

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| VI1 | 양립 설치 시 CLI 충돌 | `code` 명령이 항상 Stable 실행 | Insiders는 `code-insiders`, Stable은 `code` 명령 사용 | Insiders 사용자를 위해 `code-insiders` 명령어도 검사에 추가 |
| VI2 | Settings Sync 충돌 | 설정 동기화 데이터 호환성 문제 | Insiders와 Stable이 다른 Sync 서비스 사용 | 동시 Sync 비활성화 또는 한쪽만 Sync 사용 |
| VI3 | 확장 호환성 | Insiders에서 확장이 동작하나 Stable에서 실패 (또는 반대) | Insiders가 더 최신 API를 사용하여 확장 호환성 차이 | 한쪽에서만 사용하거나 양쪽 모두에서 테스트 |

---

### 5.6 기업 MDM 차단

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| VM1 | MDM으로 앱 설치 차단 | 설치 자체 불가 | JAMF/Intune 등에서 승인되지 않은 앱 설치 차단 | IT 관리자에게 VS Code 앱 승인 요청 |
| VM2 | PKG 인스톨러 미제공 | JAMF/Intune으로 대량 배포 불가 | Microsoft가 macOS용 VS Code를 .app 형태로만 제공 (PKG 없음) | ZIP 파일을 래핑하여 MDM으로 배포하거나, Homebrew cask를 스크립트로 감싸서 배포 |
| VM3 | "Managed by Organization" 표시 | 특정 설정이 잠겨 있음 | MDM 프로필이 VS Code 정책을 설정함 (`com.microsoft.VSCode` plist) | IT 관리자에게 필요 설정 해제 요청 |
| VM4 | 업데이트 차단 | VS Code 자동 업데이트 실패 | MDM이 앱 수정을 차단 | IT 관리자가 배포한 버전만 사용 가능 |

---

### 5.7 Apple Silicon (Rosetta 2) 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| VA1 | Intel 버전을 Apple Silicon에서 실행 | 에뮬레이션 경고 배너, 현저히 느린 성능 | x86_64 빌드가 Rosetta 2 번역을 거쳐 실행됨 | Apple Silicon(ARM64) 빌드 재설치. `file /Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron` 명령으로 아키텍처 확인 |
| VA2 | Universal Binary 혼란 | 성능이 기대보다 낮음 | Universal Binary가 때때로 Intel 바이너리를 우선 로드 | Activity Monitor에서 VS Code 프로세스의 "Kind" 열 확인. "Intel"이면 ARM64 전용 빌드 재설치 |
| VA3 | 확장 네이티브 모듈 | 확장이 로드 실패 또는 느림 | 확장의 네이티브 바이너리가 x86_64 전용으로 빌드됨 | 확장 업데이트 확인 |

---

### 5.8 Remote SSH 확장 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| VR1 | 원격 서버 연결 실패 | `Could not establish connection. The VS Code Server failed to start` | 원격 서버에서 VS Code Server 설치/시작 실패 | 원격 서버의 `~/.vscode-server/` 삭제 후 재시도 |
| VR2 | Server 설치 중 멈춤 | `Waiting for server log...` 반복 | wget/curl 다운로드 실패 또는 서버 방화벽 차단 | 원격 서버에서 `https://update.code.visualstudio.com` 접근 가능 여부 확인 |
| VR3 | 확장 버전 호환성 | 특정 Remote-SSH 버전에서 연결 실패 | Remote-SSH 확장의 특정 버전에 버그 (예: v0.109.0) | 이전 안정 버전으로 다운그레이드 (예: v0.107.1) |
| VR4 | 메모리 부족 (원격) | 서버 연결 후 바로 끊김 | VS Code Server + Node.js가 원격 서버에서 과도한 메모리 사용 | 원격 서버 메모리 확인 (최소 1GB 여유 권장) |
| VR5 | SSH 키 인증 실패 | `Permission denied (publickey)` | macOS Keychain과 VS Code의 SSH agent 포워딩 차이 | `~/.ssh/config` 에 `AddKeysToAgent yes` 및 `UseKeychain yes` 추가 |

---

### 5.9 터미널 통합 (Shell Detection) 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| VT1 | 쉘 변경 미감지 | VS Code가 이전 쉘(bash)을 계속 사용 | `chsh` 로 기본 쉘을 변경했으나 VS Code가 캐시 | `terminal.integrated.defaultProfile.osx` 를 명시적으로 설정 |
| VT2 | Shell Integration 비활성 | 명령 데코레이션, Sticky Scroll 등 미동작 | Shell Integration 자동 주입 실패 | `~/.zshrc`에 `. "$(code --locate-shell-integration-path zsh)"` 수동 추가 |
| VT3 | Powerlevel10k 충돌 | Shell Integration 관련 경고 또는 프롬프트 깨짐 | Powerlevel10k 테마가 Shell Integration과 충돌 | Powerlevel10k 최신 버전 업데이트 |
| VT4 | fish shell 미지원 (구버전) | Shell Integration 자동 주입 실패 | fish 구버전이 `$XDG_DATA_DIRS` 미지원 | fish 3.6.0 이상으로 업데이트 |

---

### 5.10 확장 디렉토리 권한 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| VD1 | sudo로 VS Code 실행 이력 | `EACCES: permission denied` (확장 설치/업데이트 시) | `sudo code` 로 실행하면 `~/.vscode/extensions` 소유권이 root로 변경됨 | `sudo chown -R $USER:staff ~/.vscode` 실행. 절대 `sudo code` 사용 금지 |
| VD2 | 마이그레이션 후 권한 | 확장 로드 실패 | Time Machine 복원 또는 Migration Assistant 사용 후 권한 불일치 | `sudo chown -R $USER:staff ~/.vscode && chmod -R u+rwX ~/.vscode` |
| VD3 | 여러 사용자 계정 | 다른 사용자의 확장과 충돌 | macOS 멀티 유저 환경에서 `~/.vscode` 디렉토리 공유 불가 | 각 사용자 홈 디렉토리의 `~/.vscode` 확인. `--extensions-dir` 로 경로 지정 |

---

## 6. Docker Desktop 설치 에러

### 6.1 Apple Silicon (M1/M2/M3/M4) 호환성 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DA1 | x86 이미지 실행 실패 | `exec format error` 또는 `no matching manifest for linux/arm64` | ARM64 Mac에서 x86_64 전용 이미지 실행 시도 | `--platform linux/amd64` 플래그 사용. 또는 "Use Rosetta for x86_64/amd64 emulation" 활성화 |
| DA2 | Rosetta 에뮬레이션 느림 | 빌드/실행이 현저히 느림 | QEMU 기반 x86 에뮬레이션 (네이티브 대비 10-20x 느림) | Rosetta 활성화 (QEMU 대비 4-5x 빠름). 가능하면 ARM64 네이티브 이미지 사용 |
| DA3 | pip/npm 패키지 설치 실패 (빌드 중) | `no matching distribution found` 또는 `platform mismatch` | Dockerfile에서 x86 전용 패키지를 ARM 환경에서 빌드 시도 | `FROM --platform=linux/amd64` 지정. 또는 ARM 호환 패키지 사용 |
| DA4 | M3/M4 칩 특정 문제 | 컨테이너 빌드/실행 중 크래시 | 최신 Apple Silicon 칩과 Docker Desktop 특정 버전 간 호환성 문제 | Docker Desktop 최신 버전 업데이트. 또는 안정 버전(예: 4.32.0)으로 다운그레이드 |
| DA5 | Rosetta 2 에뮬레이션 100% CPU | 컨테이너가 응답 없음, CPU 100% 고정 | Rosetta 에뮬레이션 하에서 특정 Node.js/amd64 워크로드가 무한 루프에 빠짐 | Rosetta 비활성화 후 QEMU로 전환. 또는 해당 워크로드를 ARM64 네이티브로 전환 |

---

### 6.2 Rosetta 2 요구사항

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DR1 | Rosetta 2 미설치 | Docker Desktop 설치 실패 또는 일부 CLI 도구 오류 | 일부 Docker Desktop 컴포넌트가 여전히 Rosetta 2 필요 | `softwareupdate --install-rosetta --agree-to-license` 실행 |
| DR2 | Rosetta 설정 오류 메시지 | `Rosetta is only intended to run on Apple Silicon` | macOS Sequoia에서 Rosetta 관련 설정 충돌 | Docker Desktop 최신 버전 업데이트. "Use Rosetta" 토글 해제 후 재활성화 |
| DR3 | x86 컨테이너 성능 경고 | `WARNING: The requested image's platform (linux/amd64) does not match the detected host platform` | ARM Mac에서 x86 이미지를 에뮬레이션하지만 성능 저하 | ARM64 네이티브 이미지 사용. `docker buildx build --platform linux/arm64` |

---

### 6.3 Docker Desktop 라이선스

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DL1 | 250인+ 기업 | Docker Desktop 사용 시 라이선스 위반 | 250명 이상 또는 연매출 $10M 이상 기업은 유료 구독 필수 | Docker Business ($24/월/사용자) 또는 Docker Pro ($5/월) 구독. 또는 Colima/Lima 사용 |
| DL2 | 인증 요구 | Docker Desktop 로그인 프롬프트 | 2024년 12월 이후 유료 플랜 가격 변경, 기업 사용자 인증 강화 | Docker Hub 계정으로 로그인. 기업은 SSO/SCIM 설정 |
| DL3 | 오프라인 환경 | 라이선스 검증 실패 | Docker Desktop이 라이선스 서버에 주기적으로 접속 필요 | 오프라인 라이선스 토큰 설정 |

---

### 6.4 Virtualization Framework / QEMU 백엔드

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DV1 | QEMU 지원 종료 | Docker Desktop 기동 경고 | QEMU 가상화 옵션이 2025년 7월 14일부로 완전 deprecated | "Use Virtualization Framework" 활성화. Apple Virtualization Framework 또는 Docker VMM으로 전환 |
| DV2 | Apple Virtualization Framework 오류 | VM 시작 실패 | 하이퍼바이저 권한 문제 | `sysctl kern.hv_support` 로 확인. 시스템 설정 > 보안에서 가상화 허용 |
| DV3 | Docker VMM (Beta) 불안정 | 간헐적 크래시 또는 성능 저하 | Docker VMM이 아직 Beta 상태 | 안정적인 Apple Virtualization Framework 사용 |
| DV4 | 가상화 미지원 (구형 Mac) | `HV support: 0` | Intel Mac 중 하이퍼바이저 미지원 모델 | `sysctl kern.hv_support` 로 확인 |

---

### 6.5 Docker 데몬 미시작

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DD1 | 데몬 연결 실패 | `Cannot connect to the Docker daemon at unix:///var/run/docker.sock` | Docker Desktop 앱이 실행되지 않았거나 데몬 시작 실패 | Docker Desktop 앱 실행 확인. 메뉴바 아이콘에서 상태 확인 |
| DD2 | 디스크 마운트 오류 | `mounting read write disk: invalid argument` | VM 디스크 이미지 손상 | Troubleshoot > "Clean / Purge data" 실행 |
| DD3 | macOS Sequoia 방화벽 간섭 | 데몬 시작 후 DNS 해석 실패 | macOS Sequoia의 향상된 방화벽이 Docker 네트워킹 간섭 | Docker Desktop 4.37.2 이상으로 업데이트 |
| DD4 | 리소스 부족 | Docker Desktop 앱은 열리지만 데몬 무응답 | 할당된 메모리/CPU 부족으로 VM 시작 실패 | Settings > Resources > Memory를 최소 4GB 이상으로 증가 |
| DD5 | "Docker.app will damage your computer" | macOS가 Docker 실행 차단 | 2024년 Docker 인증서 만료 사건으로 인한 false positive | Docker Desktop 4.37.2 이상으로 업데이트. 또는 `sudo xattr -r -d com.apple.quarantine /Applications/Docker.app` |

---

### 6.6 메모리/CPU 할당 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DM1 | OOM (Out of Memory) | 컨테이너 크래시, `Killed` 메시지 | Docker VM에 할당된 메모리 부족 (기본 2GB) | Memory 증가 (권장: 물리 RAM의 50%). Apple Silicon은 Unified Memory라 호스트 영향 적음 |
| DM2 | 빌드 느림 | `docker build` 가 매우 느림 | CPU 코어 할당 부족 | Settings > Resources > CPUs 증가 |
| DM3 | 호스트 Mac 느려짐 | macOS 전체 성능 저하 | Docker에 과도한 리소스 할당 | Settings > Resources에서 할당 감소. Resource Saver 모드 활성화 |
| DM4 | 8+ CPU 코어 할당 시 불안정 | Docker Desktop 크래시 (M1 Max 등) | Apple Silicon에서 높은 코어 수 할당 시 VM 불안정 | CPU 할당을 8 이하로 제한 |
| DM5 | Swap 과다 사용 | 디스크 I/O 급증, 느린 성능 | 컨테이너가 할당 메모리 초과하여 swap 사용 | 물리 메모리 할당 증가. `docker stats` 로 모니터링 |

---

### 6.7 파일 공유 / Bind Mount 성능

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DF1 | node_modules 포함 bind mount | `npm install` 이 10x+ 느림 | 수만 개의 작은 파일이 호스트/VM 경계를 넘어 각각 I/O 발생 | `.dockerignore` 에 `node_modules` 추가. Named volume 사용 |
| DF2 | gRPC FUSE (레거시) | 파일 I/O가 네이티브 대비 10x 느림 | gRPC FUSE 성능 불량 | "VirtioFS" 활성화 (macOS 12.5+ 필요) |
| DF3 | VirtioFS 대용량 파일 | 2GB+ 파일이 잘림 (truncated) | VirtioFS 초기 버전의 대용량 파일 버그 | Docker Desktop 최신 버전 업데이트 |
| DF4 | 파일 감시 (inotify) | Hot reload 미동작, 파일 변경 감지 안 됨 | macOS FSEvents가 VM 내 Linux inotify로 전파 안 됨 | VirtioFS 사용. 또는 `CHOKIDAR_USEPOLLING=true` 환경변수 설정 |
| DF5 | Synchronized File Shares | 설정 후에도 느림 | Docker Desktop 유료 기능 (Pro+) | Settings > Resources > File Sharing에서 Synchronized File Shares 설정 |

---

### 6.8 네트워크 (VPN 충돌)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DN1 | VPN 연결 시 DNS 실패 | 컨테이너에서 `Could not resolve host` | Docker 컨테이너가 호스트 DNS를 상속하지만 VPN이 DNS를 변경 | Docker Desktop 4.42+ 사용. 또는 `docker run --dns 8.8.8.8` |
| DN2 | VPN + Docker 동시 사용 시 크래시 | Docker Desktop이 VPN 연결 시 종료됨 | Docker 네트워킹과 VPN (Cisco AnyConnect, AWS VPN)의 서브넷 충돌 | Docker 네트워크 서브넷 변경: `docker network create --subnet=172.28.0.0/16 custom_net` |
| DN3 | 사내 레지스트리 접근 불가 | `dial tcp: lookup registry.internal.corp: no such host` | VPN을 통한 사내 레지스트리가 컨테이너에서 접근 불가 | `daemon.json` 에 `"dns": ["10.0.0.2", "8.8.8.8"]` 추가 |
| DN4 | 포트 충돌 | `Bind for 0.0.0.0:xxxx failed: port is already allocated` | 호스트에서 해당 포트를 이미 사용 중 | `lsof -i :포트번호` 로 확인. 다른 포트로 매핑 |

---

### 6.9 Docker Desktop 업데이트 실패

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DU1 | 업데이트 다운로드 멈춤 | "Updating..." 상태에서 진행 없음 | 다운로드 서버 문제 또는 네트워크 불안정 | `brew upgrade --cask docker` 로 Homebrew 경유 업데이트 |
| DU2 | 업데이트 후 시작 불가 | Docker Desktop이 열리지 않음 | 업데이트 중 파일 손상 | 완전 삭제 후 재설치: `brew uninstall --cask docker` + 관련 Library 폴더 삭제 |
| DU3 | In-app 업데이트가 최신 버전 미반영 | 알림은 뜨지만 실제 최신 버전이 아님 | In-app updater 버그 | 공식 사이트에서 DMG 수동 다운로드. 또는 `brew upgrade --cask docker` |
| DU4 | 업데이트 후 데이터 손실 | 컨테이너/이미지/볼륨 사라짐 | 메이저 업데이트 시 VM 재생성 | `docker compose` 로 재현 가능한 환경 유지 |

---

### 6.10 macOS 버전별 호환성

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DO1 | macOS Ventura (13) 이하 | Docker Desktop 최신 버전 설치/실행 불가 | Docker Desktop 4.53+ 은 macOS Sonoma (14) 이상만 지원 | macOS 업그레이드. 또는 Docker Desktop 4.36 사용 |
| DO2 | macOS Sequoia (15) DNS 버그 | 컨테이너 내부에서 DNS 해석 실패 | macOS Sequoia 방화벽의 DNS 관련 버그 | Docker Desktop 4.37.2+ 으로 업데이트 |
| DO3 | macOS Sequoia (15.3) GUI 문제 | Docker Desktop 앱이 열리지 않지만 데몬은 동작 | Sequoia 15.3의 윈도우 관리 변경 | Docker Desktop 최신 버전 업데이트. CLI는 정상 동작 |
| DO4 | macOS Sonoma (14) GUI 무응답 | Docker Desktop 창이 반응 없음 | Docker Desktop 4.28-4.33 버전의 Sonoma GUI 버그 | Docker Desktop 4.34 이상으로 업데이트 |
| DO5 | macOS 업그레이드 후 Docker 깨짐 | Docker Desktop 시작 불가 | macOS를 Docker Desktop보다 먼저 업그레이드 | 항상 Docker Desktop을 먼저 업데이트한 후 macOS 업그레이드 |

---

### 6.11 `docker` 명령어 미등록

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DC1 | 설치 직후 | `zsh: command not found: docker` | Docker Desktop이 CLI를 `$HOME/.docker/bin` 에 설치 (USER 모드 기본값) | Settings > Advanced > "System" 선택. 또는 `~/.zshrc` 에 PATH 추가 |
| DC2 | symlink 깨짐 | `docker` 명령이 갑자기 동작 안 함 | Docker Desktop 업데이트 시 symlink 재생성 실패 | Settings > Advanced > "System" 재설정 |
| DC3 | Homebrew 설치 후 | `docker: command not found` | `brew install --cask docker` 후 Docker Desktop 앱을 실행하지 않음 | Docker Desktop 앱을 한 번 실행하여 CLI 도구 설치 완료 |
| DC4 | docker-compose vs docker compose | `docker-compose: command not found` | Docker Compose V2는 `docker compose` (하이픈 없음)으로 변경됨 | `docker compose` 사용 |

---

### 6.12 디스크 공간 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DS1 | 이미지 누적 | Mac 저장 공간 경고, Docker 빌드 실패 | 미사용 Docker 이미지/레이어 누적 (20-50GB+) | `docker system prune -a`. `docker system df` 로 확인 |
| DS2 | Docker.raw 파일 비대 | `~/Library/Containers/com.docker.docker/Data/vms/` 에 수십 GB | VM 디스크 이미지가 삭제 후에도 축소되지 않음 (sparse file) | "Clean / Purge Data" 로 VM 재생성 |
| DS3 | 빌드 캐시 누적 | `docker build` 캐시가 수 GB 차지 | BuildKit 캐시가 자동 정리되지 않음 | `docker builder prune` |
| DS4 | 볼륨 고아화 | `docker volume ls` 에 미사용 볼륨 다수 | 컨테이너 삭제 시 볼륨은 자동 삭제되지 않음 | `docker volume prune` (데이터 손실 주의) |
| DS5 | Disk image size 제한 | `no space left on device` (컨테이너 내부) | Docker VM 디스크 이미지 최대 크기 초과 | Settings > Resources > Disk image size 증가 |

---

### 6.13 기업 프록시 설정

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| DP1 | Docker pull 실패 | `proxyconnect tcp: dial tcp: connect: connection refused` | 기업 프록시가 Docker Hub 접근 차단 | Settings > Resources > Proxies에서 HTTP/HTTPS 프록시 설정 |
| DP2 | NTLM/Kerberos 인증 프록시 | 프록시 인증 실패 | 기업 프록시가 NTLM/Kerberos 인증 요구 | Docker Desktop 4.30+ 사용 (NTLM/Kerberos 자동 지원) |
| DP3 | SOCKS5 프록시 | 연결 실패 | SOCKS5 프록시 미지원 (구버전) | Docker Desktop 4.30+ 사용 (SOCKS5 지원 추가) |
| DP4 | SSL 인증서 (MITM) | `x509: certificate signed by unknown authority` | 기업 보안 솔루션이 SSL 트래픽 가로채기 | 기업 CA 인증서를 Docker에 추가. 또는 `"insecure-registries"` 설정 |
| DP5 | Docker build 중 프록시 | `Dockerfile`의 `RUN apt-get update` 등이 실패 | 빌드 타임 프록시 미설정 | `docker build --build-arg HTTP_PROXY=http://proxy:port` 사용 |

---

## 7. Antigravity (Google) 설치 에러

### 7.1 Homebrew Cask 설치

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| AGY1 | Cask 미발견 | `Error: Cask 'google-antigravity' is unavailable` | Homebrew 메타데이터가 오래됨 또는 cask 이름 변경 | `brew update` 후 `brew search antigravity` 로 확인 |
| AGY2 | 다운로드 실패 (404) | `Error: Download failed on Cask 'google-antigravity'` | 특정 버전의 릴리즈 파일이 GitHub에서 누락됨 | `brew update` 후 재시도. 또는 `curl -O https://dl.google.com/antigravity/latest/Antigravity-mac.dmg` |
| AGY3 | SHA256 불일치 | `Error: SHA256 mismatch` | Homebrew 해시와 실제 파일 해시 불일치 | `brew update-reset && brew update` 후 재시도 |
| AGY4 | 기존 설치와 충돌 | `Error: It seems there is already an App at '/Applications/Antigravity Tools.app'` | 수동 설치 Antigravity가 이미 존재 | `brew install --cask google-antigravity --force` |
| AGY5 | Apple Silicon 호환성 | 설치는 되지만 Rosetta 에뮬레이션으로 실행 | ARM64 네이티브 빌드가 아닌 빌드 설치 | Activity Monitor에서 "Kind" 열 확인 |

---

### 7.2 Gatekeeper / Quarantine 차단

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| AQ1 | "앱이 손상됨" 오류 | `"Antigravity Tools" is damaged and can't be opened` | macOS quarantine 속성 부착 | `sudo xattr -rd com.apple.quarantine "/Applications/Antigravity Tools.app"` |
| AQ2 | 미확인 개발자 차단 | `"Antigravity Tools" can't be opened because it is from an unidentified developer` | Gatekeeper 서명 검증 실패 | `--no-quarantine` 플래그 사용. 또는 시스템 설정에서 허용 |
| AQ3 | macOS Sequoia 강화 보안 | 이전 우회 방법이 동작하지 않음 | Sequoia에서 Gatekeeper 우회가 더 어려워짐 | 시스템 설정 > 개인정보 및 보안에서 직접 앱 허용 |
| AQ4 | 보안 소프트웨어 간섭 | Antigravity 확장 파일이 격리됨 | Norton, Kaspersky 등이 확장 파일을 의심 | 보안 소프트웨어 예외 목록에 Antigravity 추가 |

---

### 7.3 `agy` CLI PATH 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| AP1 | CLI 명령 미등록 | `zsh: command not found: agy` | Antigravity가 `agy` symlink를 자동 생성하지 않음 | Command Palette > "Install 'agy' command in PATH" 실행. 또는 수동 symlink 생성 |
| AP2 | 바이너리명 불일치 | `agy: command not found` 이지만 `antigravity` 는 동작 | 패키지 관리자가 바이너리를 `antigravity` 로 설치 | `sudo ln -s /usr/bin/antigravity /usr/local/bin/agy` |
| AP3 | PATH 미적용 | 터미널 재시작 후에도 `agy` 없음 | `~/.zshrc` 에 PATH 미추가 | `~/.zshrc` 에 PATH 추가 후 `source ~/.zshrc` |
| AP4 | Gemini CLI와의 연동 실패 | `error: agy not found. Please ensure it is in your system's PATH.` | Gemini CLI가 `agy`를 PATH에서 못 찾음 | 위 AP1-AP3 해결 후 재시도 |

---

### 7.4 Google 계정 요구사항/제한

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| AA1 | 미인증 상태 | AI 기능 미동작, Gemini 모델 접근 불가 | Google 계정 로그인 필수 | Google 계정으로 로그인. 개인 Gmail 계정 권장 |
| AA2 | 미지원 지역 | `Your current account is not eligible for Antigravity` | Google 계정 등록 지역이 지원 지역 외 | 계정 지역을 지원 지역 (미국, 일본, 대만 등)으로 변경 |
| AA3 | 연령 제한 | 계정 부적격 메시지 | 18세 미만 Google 계정 | 18세 이상의 계정 사용 |
| AA4 | Workspace 계정 | 로그인 실패 또는 기능 제한 | 프리뷰 기간 중 Workspace 계정 미지원 가능 | 개인 Gmail 계정으로 로그인 |
| AA5 | OAuth 리다이렉트 실패 | 로그인 후 빈 페이지 또는 오류 | OAuth 콜백 URL 차단 (방화벽, VPN, 브라우저 확장) | `antigravity.google` 도메인 접근 확인. 광고 차단기 일시 비활성화 |

---

### 7.5 Copilot 확장 충돌

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| AC1 | 이중 자동 완성 | 두 개의 자동 완성 제안이 동시에 표시 | GitHub Copilot 확장과 Antigravity 내장 AI 동시 동작 | Antigravity 내에서 Copilot 확장 비활성화 |
| AC2 | 키바인딩 충돌 | AI 관련 단축키가 예상과 다르게 동작 | 두 AI 확장의 키바인딩 충돌 | Keyboard Shortcuts에서 충돌 키바인딩 조정 |
| AC3 | 성능 저하 | 에디터 반응 느림, 높은 CPU 사용 | 두 AI 확장이 동시에 동작 | 하나의 AI 어시스턴트만 활성화 |

---

### 7.6 OpenVSX vs VS Code Marketplace 차이

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| AO1 | 확장 미발견 | 특정 확장이 검색되지 않음 | OpenVSX 레지스트리에 Microsoft 독점 확장 없음 (C#, Remote-SSH 등) | `.vsix` 파일을 직접 다운로드하여 수동 설치 |
| AO2 | 확장 버전 차이 | VS Code에서보다 오래된 버전 | OpenVSX에 최신 버전 미게시 | GitHub 릴리즈에서 `.vsix` 다운로드 후 수동 설치 |
| AO3 | 악성 확장 위험 | `Extension 'xyz' is not verified` 경고 | OpenVSX에 사칭 확장 등록 사례 (2025년 12월 발견) | 확장 설치 전 발행자 확인. Antigravity 최신 버전 업데이트 |
| AO4 | VS Code 확장 수동 설치 | `.vsix` 설치 시 호환성 문제 | VS Code 독점 API 미지원 가능 | 확장의 API 호환성 확인 |

---

## 8. Claude Code CLI 설치

> **네이티브 설치 (권장)**: `curl -fsSL https://claude.ai/install.sh | bash`
> **npm 설치 (deprecated)**: `npm install -g @anthropic-ai/claude-code`
> **진단 명령**: `claude doctor`

### 8.1 네이티브 설치 (curl installer)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| CC1 | curl 미설치 | `zsh: command not found: curl` | 극히 드물지만 커스텀 macOS에서 발생 가능 | `brew install curl` 또는 Xcode CLT 설치 |
| CC2 | SSL 인증서 오류 | `curl: (60) SSL certificate problem: unable to get local issuer certificate` | 기업 프록시의 TLS 인터셉션 또는 시스템 인증서 스토어 문제 | `export NODE_EXTRA_CA_CERTS=/path/to/ca-cert.pem` 설정, IT에서 CA 인증서 획득 |
| CC3 | 프록시/방화벽 차단 | `curl: (7) Failed to connect to claude.ai port 443` | 기업 방화벽이 claude.ai 도메인 차단 | IT에 `claude.ai`, `api.anthropic.com` 화이트리스트 요청 |
| CC4 | DNS 해석 실패 | `curl: (6) Could not resolve host: claude.ai` | DNS 설정 문제 또는 네트워크 미연결 | DNS 서버 확인 (8.8.8.8 등), 네트워크 연결 확인 |
| CC5 | 프록시 인증 필요 | `curl: (407) Proxy Authentication Required` | 기업 프록시 사용 시 인증 미설정 | `export HTTPS_PROXY=http://user:pass@proxy:port` 설정 |
| CC6 | 다운로드 타임아웃 | `curl: (28) Connection timed out` | 느린 네트워크 또는 방화벽 간섭 | VPN 해제 시도, 다른 네트워크 시도 |
| CC7 | bash 실행 문제 (zsh 기본) | 스크립트가 bash로 실행되나 PATH를 zsh에 반영 못함 | macOS Catalina+ 기본 셸이 zsh이나 스크립트가 bash로 실행 | 설치 후 `~/.zshrc`에 PATH 수동 추가 |
| CC8 | install.sh 다운로드 불완전 | 스크립트 실행 중 구문 오류 | 네트워크 중단으로 스크립트 일부만 다운로드 | `curl -fsSL` 의 `-f` 플래그가 처리하지만, 재시도 필요 |
| CC9 | ~/.local/bin 디렉토리 생성 실패 | `Permission denied: mkdir ~/.local/bin` | 디스크 권한 문제 (극히 드묾) | `mkdir -p ~/.local/bin && chmod 755 ~/.local/bin` |
| CC10 | 아키텍처 감지 오류 | x86_64 바이너리가 ARM64 Mac에 설치됨 | install.sh가 아키텍처를 잘못 감지 (Rosetta 환경 등) | `arch -arm64 bash -c "curl -fsSL https://claude.ai/install.sh \| bash"` |

**소스**: [Claude Code Troubleshooting](https://code.claude.com/docs/en/troubleshooting), [ARM64 binary issue #13617](https://github.com/anthropics/claude-code/issues/13617), [Architecture Mismatch #4749](https://github.com/anthropics/claude-code/issues/4749)

---

### 8.2 npm 설치 (deprecated)

> **주의**: Anthropic은 네이티브 설치를 권장하며 npm 설치는 deprecated입니다.

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| CN1 | npm EACCES 권한 오류 | `EACCES: permission denied, access '/usr/local/lib/node_modules'` | npm 글로벌 디렉토리에 쓰기 권한 없음 | `npm config set prefix '~/.npm-global'` + PATH 추가, 또는 nvm 사용 |
| CN2 | Node.js 버전 부족 | `Claude Code requires Node.js version 18 or higher` | Node.js 16 이하 설치됨 | `brew install node@20` 또는 `nvm install 20` |
| CN3 | Node.js 미설치 | `npm: command not found` | Node.js/npm 미설치 | Homebrew로 Node.js 설치: `brew install node` |
| CN4 | Homebrew Node.js 심링크 오류 | `claude: command not found` (설치 성공 후) | Homebrew Node.js로 설치 시 심링크가 JS 파일을 가리킴 (실행 스크립트 아님) | 심링크 수동 수정: `ln -sf $(npm prefix -g)/lib/node_modules/@anthropic-ai/claude-code/cli.js $(brew --prefix)/bin/claude` |
| CN5 | 네이티브 설치와 npm 설치 충돌 | `segmentation fault` 또는 버전 혼란 | 두 가지 설치 방식이 동시에 존재 | npm 글로벌 설치 제거 후 네이티브 설치: `npm uninstall -g @anthropic-ai/claude-code && curl -fsSL https://claude.ai/install.sh \| bash` |
| CN6 | nvm/asdf 버전 관리자 충돌 | PATH 우선순위 문제로 잘못된 claude 바이너리 실행 | nvm/asdf shim이 npm-global 경로를 가림 | `which claude`로 경로 확인, shim 재설정 |
| CN7 | npm 캐시 오염 | 업데이트 시 npm-local 모드로 잘못 전환 | 이전 npm 설치의 캐시가 남아있음 | `npm cache clean --force` 후 재설치 |
| CN8 | sudo npm install | 향후 권한 문제 연쇄 발생 | root로 설치된 파일이 일반 사용자 접근 차단 | **절대 sudo로 npm install하지 말 것**. `sudo chown -R $(whoami) ~/.npm` 후 재설치 |

**소스**: [npm/native conflict #7734](https://github.com/anthropics/claude-code/issues/7734), [Homebrew symlink #3172](https://github.com/anthropics/claude-code/issues/3172), [Auto-updater npm-global #22415](https://github.com/anthropics/claude-code/issues/22415)

**혼합 설치 완전 제거 절차**:
```bash
# 1. npm 글로벌 설치 제거
npm uninstall -g @anthropic-ai/claude-code 2>/dev/null

# 2. npm-global 유령 바이너리 제거
rm -f ~/.npm-global/bin/claude 2>/dev/null

# 3. npm 캐시에서 이전 패키지 제거
npm cache clean --force

# 4. 네이티브 설치 제거 (필요 시)
rm -f ~/.local/bin/claude

# 5. 네이티브 재설치 (권장)
curl -fsSL https://claude.ai/install.sh | bash
```

---

### 8.3 네트워크/프록시 문제

> 기업 환경에서 Claude Code 사용 시 추가 네트워크 설정 필요

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| CP1 | 기업 프록시 | `ECONNREFUSED` 또는 API 호출 실패 | 프록시 미설정 | `export HTTPS_PROXY=https://proxy.example.com:8080` |
| CP2 | TLS 인터셉션 (SSL MITM) | `Self-signed certificate detected` / `UNABLE_TO_VERIFY_LEAF_SIGNATURE` | 기업 보안 솔루션이 SSL 인증서 교체 | `export NODE_EXTRA_CA_CERTS=/path/to/corporate-ca.pem` |
| CP3 | 방화벽 URL 차단 | API 호출 타임아웃 | 필수 URL이 화이트리스트에 없음 | `api.anthropic.com`, `claude.ai`, `platform.claude.com` 허용 |
| CP4 | mTLS 인증 필요 | 클라이언트 인증서 오류 | 기업 환경에서 상호 TLS 인증 요구 | `CLAUDE_CODE_CLIENT_CERT`, `CLAUDE_CODE_CLIENT_KEY` 환경변수 설정 |
| CP5 | SOCKS 프록시 사용 | 연결 실패 | Claude Code는 SOCKS 프록시 미지원 | HTTP/HTTPS 프록시로 변경 또는 LLM Gateway 사용 |
| CP6 | VPN 충돌 | 간헐적 연결 실패 | VPN split tunneling 설정 문제 | VPN 설정에서 `api.anthropic.com` 제외 또는 포함 확인 |
| CP7 | NO_PROXY 미설정 | MCP 로컬 서버 연결 시 프록시 경유 | localhost 요청이 프록시를 통해 라우팅 | `export NO_PROXY="localhost 127.0.0.1"` |

**소스**: [Enterprise network config](https://code.claude.com/docs/en/network-config), [Self-signed cert #24470](https://github.com/anthropics/claude-code/issues/24470)

**기업 환경 설정 예시** (`~/.zshrc`에 추가):
```bash
# Claude Code 프록시 설정
export HTTPS_PROXY=https://proxy.company.com:8080
export NO_PROXY="localhost 127.0.0.1"
export NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/corporate-ca.pem

# mTLS 인증 (필요 시)
export CLAUDE_CODE_CLIENT_CERT=/path/to/client-cert.pem
export CLAUDE_CODE_CLIENT_KEY=/path/to/client-key.pem
```

---

### 8.4 Shell/PATH 문제

> macOS Catalina (10.15)부터 기본 셸이 zsh로 변경됨

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| CS1 | 설치 후 command not found | `zsh: command not found: claude` | `~/.local/bin`이 PATH에 없음 | `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc` |
| CS2 | 틸드(~) 확장 버그 | PATH에 리터럴 `~` 문자가 들어감 | install.sh가 `export PATH="~/.local/bin:$PATH"` 형태로 안내 → 따옴표 안 틸드 미확장 | `$HOME` 사용: `export PATH="$HOME/.local/bin:$PATH"` |
| CS3 | .zshrc 미존재 | PATH 추가가 반영되지 않음 | 새 Mac에서 `.zshrc` 파일이 없을 수 있음 | `touch ~/.zshrc` 후 PATH export 추가 |
| CS4 | .zprofile vs .zshrc 혼돈 | 로그인 셸에서만 작동 또는 그 반대 | macOS Terminal은 로그인 셸로 실행 (`.zprofile` 읽음) | 양쪽 모두에 추가하거나 `.zprofile`에서 `.zshrc` source |
| CS5 | bash 사용자 (비기본) | `.bash_profile` 또는 `.bashrc`에 PATH 없음 | 수동으로 bash로 변경한 사용자 | `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile` |
| CS6 | source 미실행 | 설치 직후 `claude` 인식 안됨 | 셸 설정 파일 변경 후 source 미실행 | `source ~/.zshrc` 또는 새 터미널 탭 열기 |
| CS7 | install 명령이 PATH에 추가 안함 | `claude install` 성공 메시지 후 command not found | `claude install`이 `~/.local/bin/claude`에 설치하지만 셸 설정 파일에 PATH 미추가 | 수동으로 `~/.zshrc`에 PATH 추가 |
| CS8 | 네이티브 설치 후 npm-global 유령 바이너리 | 이전 npm 버전이 실행됨 | 자동 업데이터가 `~/.npm-global/bin/claude` 재생성하여 PATH 우선순위 문제 | `rm ~/.npm-global/bin/claude` 후 `which claude`로 확인 |

**소스**: [PATH expansion bug #6090](https://github.com/anthropics/claude-code/issues/6090), [Incorrect PATH syntax for zsh #5177](https://github.com/anthropics/claude-code/issues/5177), [PATH Fails with Quoted Tilde #4453](https://github.com/anthropics/claude-code/issues/4453), [claude install doesn't persist PATH #21069](https://github.com/anthropics/claude-code/issues/21069)

**Shell 설정 파일 로딩 순서** (macOS zsh):
```
로그인 셸 (Terminal.app 기본):
  1. /etc/zshenv → 2. ~/.zshenv → 3. /etc/zprofile → 4. ~/.zprofile
  → 5. /etc/zshrc → 6. ~/.zshrc → 7. /etc/zlogin → 8. ~/.zlogin

비로그인 셸 (tmux, 스크립트):
  1. /etc/zshenv → 2. ~/.zshenv → 3. /etc/zshrc → 4. ~/.zshrc
```

---

### 8.5 macOS 플랫폼 고유 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| CM1 | Gatekeeper 경고 | `"claude" Not Opened: Apple could not verify "claude" is free of malware` | 바이너리가 Apple 공증(notarization) 안됨 | 시스템 설정 > 개인 정보 보호 및 보안 > "확인 없이 열기" 또는 `xattr -d com.apple.quarantine ~/.local/bin/claude` |
| CM2 | .node 파일 Gatekeeper 경고 | `.7fd3dfffbffbbd2f-00000000.node Not Opened` 반복 팝업 | Bun 런타임이 추출하는 네이티브 .node 모듈이 코드 서명 미상속 | `xattr -cr ~/.local/share/claude-code/` 또는 시스템 설정에서 허용 |
| CM3 | Apple Silicon에서 x86_64 바이너리 설치 | 성능 저하, Rosetta 의존 | install 명령이 아키텍처 잘못 감지하여 x86_64 바이너리 설치 | `file ~/.local/bin/claude`로 확인 후 ARM64 바이너리 재설치 |
| CM4 | Intel Mac에서 Apple Silicon 필요 오류 | `Apple Silicon required` 에러 (잘못된 감지) | cowork 기능이 아키텍처를 잘못 감지 | CLI 업데이트로 해결: `claude update` |
| CM5 | Segmentation Fault | `Segmentation fault: 11` | 혼합 설치 (npm + 네이티브, Bun + Node.js 충돌) | 모든 기존 설치 제거 후 네이티브 재설치 (8.2 혼합 설치 제거 절차 참고) |
| CM6 | macOS Tahoe (26) 비호환 | 기능 오류 또는 실행 안됨 | 최신 macOS 베타와 호환성 문제 | 안정 릴리즈 macOS 사용 또는 Claude Code 업데이트 대기 |
| CM7 | Bun 런타임 크래시 | `Bun has crashed` | 네이티브 바이너리의 Bun 런타임 내부 오류 | Claude Code 최신 버전으로 업데이트: `claude update` |
| CM8 | CPU AVX 지원 없음 (VM 환경) | `CPU lacks AVX support` | 가상 머신에서 AVX 미지원 CPU 에뮬레이션 | Node.js 기반 npm 설치 사용 (Bun 대신) |

**소스**: [Gatekeeper .node warning #14911](https://github.com/anthropics/claude-code/issues/14911), [Homebrew blocked by Gatekeeper #19897](https://github.com/anthropics/claude-code/issues/19897), [Segfault on macOS Silicon #15925](https://github.com/anthropics/claude-code/issues/15925), [Wrong architecture install #15571](https://github.com/anthropics/claude-code/issues/15571)

**아키텍처 확인 및 Gatekeeper 해결**:
```bash
# 바이너리 아키텍처 확인
file ~/.local/bin/claude
# 기대 결과 (Apple Silicon): Mach-O 64-bit executable arm64

# Gatekeeper quarantine 속성 제거
xattr -d com.apple.quarantine ~/.local/bin/claude
xattr -cr ~/.local/share/claude-code/

# 현재 아키텍처 확인
arch    # arm64 (Apple Silicon) 또는 i386 (Rosetta/Intel)
```

---

### 8.6 인증 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| CA1 | API 키 오류 | `Invalid API key · Please run /login` | API 키 만료 또는 잘못된 키 | `/logout` 후 `/login`으로 재인증, 또는 Anthropic Console에서 키 확인 |
| CA2 | macOS 키체인 문제 | 로그인 성공 후 즉시 `Missing API key` 반복 | OAuth 토큰이 macOS 키체인에 저장되지 않음 | `security unlock-keychain ~/Library/Keychains/login.keychain-db` 후 재시도 |
| CA3 | 인증 무한 루프 | `/login` → 성공 → 즉시 `Missing API key` → `/login` 반복 | 키체인 접근 권한 문제 또는 auth.json 손상 | `rm -rf ~/.config/claude-code/auth.json` 후 `claude` 재실행 |
| CA4 | 브라우저가 열리지 않음 | OAuth URL 열기 실패 | 기본 브라우저 설정 문제 또는 헤드리스 환경 | `c` 키를 눌러 OAuth URL을 클립보드에 복사 후 수동으로 브라우저에 붙여넣기 |
| CA5 | SSH 세션에서 인증 | 토큰 미저장 | SSH 환경에서 키체인에 접근 불가 | `ANTHROPIC_API_KEY` 환경변수로 API 키 직접 설정 |
| CA6 | 기업/개인 계정 혼재 | 기업 설정이 개인 설정 덮어쓰기 | employer API 키 설정이 개인 설정을 오염 | `~/.claude.json`에서 잘못된 설정 수동 삭제 |

**소스**: [Auth loop macOS #8280](https://github.com/anthropics/claude-code/issues/8280), [Invalid API key #5167](https://github.com/anthropics/claude-code/issues/5167), [Login not persisting Mac SSH #5225](https://github.com/anthropics/claude-code/issues/5225)

**인증 완전 초기화**:
```bash
# 1. 로그아웃
claude /logout 2>/dev/null

# 2. 인증 정보 삭제
rm -rf ~/.config/claude-code/auth.json

# 3. 키체인 잠금 해제 (SSH 세션)
security unlock-keychain ~/Library/Keychains/login.keychain-db

# 4. 재로그인
claude
# 또는 API 키 직접 설정
export ANTHROPIC_API_KEY=sk-ant-xxxxx
```

---

### 8.7 VS Code 확장 문제 (Claude Code)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| CV1 | 확장 설치 ENOENT | `Error installing VS Code extension: 1: ENOENT` | 번들된 .vsix 파일 손상 (0 바이트) | VS Code Marketplace에서 직접 설치 |
| CV2 | Node.js 18 필요 에러 | `Claude Code requires Node.js version 18 or higher to be installed` | VS Code가 잘못된 Node.js 경로 참조 | VS Code 설정에서 node 경로 지정, 또는 시스템 Node.js 업데이트 |
| CV3 | 확장 호스트 크래시 | `Extension host terminated unexpectedly` 반복 | 메모리 한도 초과 (2-3GB) | VS Code 재시작, `--max-memory` 설정, 또는 CLI 사용 |
| CV4 | 메모리 누수 | 프로세스당 6-11GB RAM 사용 | 특정 확장 버전의 메모리 누수 버그 | 확장 업데이트 또는 다운그레이드, VS Code 주기적 재시작 |
| CV5 | ARM64 SIGABRT (Remote SSH) | `SIGABRT (exit code 134)` | ARM64 64KB 페이지 사이즈와 비호환 | CLI 사용 또는 확장 업데이트 대기 |
| CV6 | macOS Tahoe 비호환 | 확장 아이콘 미표시, UI 로드 안됨 | macOS 26 Tahoe 베타와 비호환 | 안정 macOS 버전 사용 |
| CV7 | CPU 99% 사용 | Code Helper (Renderer) 프로세스 CPU 과다 사용 | VS Code 렌더러 프로세스 과부하 | VS Code 재시작, 다른 확장 비활성화 시도 |

**소스**: [VS Code crash ARM64 #10496](https://github.com/anthropics/claude-code/issues/10496), [Memory Leak 11.6GB #21182](https://github.com/anthropics/claude-code/issues/21182), [Extension host terminated #12229](https://github.com/anthropics/claude-code/issues/12229), [Not compatible macOS Tahoe #2270](https://github.com/anthropics/claude-code/issues/2270)

---

## 9. Gemini CLI 설치

> **npm 설치**: `npm install -g @google/gemini-cli`
> **Homebrew 설치**: `brew install gemini-cli`
> **Node.js 필수 요구사항**: Node.js 20.0.0+

### 9.1 npm 설치

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| GN1 | npm EACCES 권한 오류 | `EACCES: permission denied, access '/usr/local/lib/node_modules'` | npm 글로벌 디렉토리에 쓰기 권한 없음 | `mkdir ~/.npm-global && npm config set prefix '~/.npm-global'` + PATH 추가. 또는 nvm 사용 |
| GN2 | Node.js 버전 부족 | `EBADENGINE Unsupported engine { required: { node: '>=20' } }` | Node.js 20 미만 설치됨 (Gemini CLI는 **Node.js 20+ 필수**) | `brew install node@20` 또는 `nvm install 20 && nvm use 20` |
| GN3 | Node.js 미설치 | `npm: command not found` | Node.js/npm 미설치 | `brew install node` 또는 [nodejs.org](https://nodejs.org) 에서 설치 |
| GN4 | npm 레지스트리 접근 불가 | `npm ERR! network request to https://registry.npmjs.org failed` | 프록시/방화벽이 npm 레지스트리 차단 | `npm config set proxy http://proxy:port` 또는 미러 사용 |
| GN5 | 의존성 deprecated 경고 (다수) | 다수의 deprecated 패키지 경고 | 내부 의존성이 deprecated 패키지 사용 | **무시 가능** - 경고일 뿐 설치는 진행됨 |
| GN6 | ripgrep 다운로드 타임아웃 | `RequestError: connect ETIMEDOUT` (GitHub releases 서버) | Gemini CLI가 GitHub에서 ripgrep 바이너리 다운로드 시 타임아웃 | `~/.gemini/settings.json`에 `"useRipgrep": false` 추가 |
| GN7 | npx GitHub 설치 실패 | `npx https://github.com/google-gemini/gemini-cli` 후 무반응 | GitHub repo에는 빌드된 `bundle/` 디렉토리 없음 | **올바른 방법**: `npx @google/gemini-cli` (npm 패키지에서 직접) |
| GN8 | 설치 후 command not found | `zsh: command not found: gemini` | npm 글로벌 bin 디렉토리가 PATH에 없음 | `echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc` |
| GN9 | ERR_REQUIRE_ESM | `ERR_REQUIRE_ESM` 모듈 로딩 오류 | Node.js 버전과 ESM 모듈 비호환 | Node.js 20+로 업그레이드 |
| GN10 | sudo npm install 후유증 | 향후 권한 문제 연쇄 | root 소유 파일이 일반 사용자 접근 차단 | `sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}` |
| GN11 | npm 업데이트 실패 | `Automatic update failed. Please try updating manually` | PATH 충돌 또는 권한 문제로 자동 업데이트 실패 | `npm install -g @google/gemini-cli@latest` |
| GN12 | npm/Homebrew 설치 충돌 | 버전 불일치 경고 반복, 업데이트 루프 | 두 패키지 매니저로 동시 설치됨 | 하나로 통일: `brew uninstall gemini-cli` 또는 `npm uninstall -g @google/gemini-cli` |
| GN13 | EOVERRIDE 크래시 | CLI가 시작 시 크래시 | `npm list` 실패가 초기화를 중단 | npm 설정 확인, `npm config delete overrides` |

**소스**: [npm install fails #2264](https://github.com/google-gemini/gemini-cli/issues/2264), [Installation impossible #7795](https://github.com/google-gemini/gemini-cli/issues/7795), [EBADENGINE Node.js v20 #2870](https://github.com/google-gemini/gemini-cli/issues/2870), [command not found #8397](https://github.com/google-gemini/gemini-cli/issues/8397), [npx GitHub fails #2077](https://github.com/google-gemini/gemini-cli/issues/2077)

---

### 9.2 Homebrew 설치

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| GH1 | 첫 실행 EACCES | `Error: EACCES: permission denied, mkdir '/Library/Application Support/GeminiCli'` | 코드가 `/Library/Application Support/` (시스템 레벨) 사용, sudo 필요 | `sudo mkdir -p '/Library/Application Support/GeminiCli' && sudo chown $(whoami) '/Library/Application Support/GeminiCli'` |
| GH2 | Homebrew 미설치 | `brew: command not found` | Homebrew 미설치 | [brew.sh](https://brew.sh) 에서 Homebrew 설치 |
| GH3 | Homebrew 업데이트 불일치 | `outdated version` 경고가 반복 표시 | Homebrew 설치와 npm 설치 버전 충돌 | 하나의 패키지 매니저로 통일 |
| GH4 | macOS 15.7 temp 폴더 권한 | `Permission Denied to Temp folder` (`/var/folders/.../T/gemini-cli-warnings.txt`) | macOS Sequoia 업그레이드 후 임시 폴더 rootless 권한 변경 | macOS 재시작 또는 `chmod 755 /var/folders/...` (특정 temp 경로) |
| GH5 | 업데이트 후 command not found | 업데이트 후 `gemini` 실행 안됨 | 업데이트 시 실행 파일 경로가 변경됨 | `brew unlink gemini-cli && brew link gemini-cli` |

**소스**: [EACCES Homebrew first run #13547](https://github.com/google-gemini/gemini-cli/issues/13547), [Temp folder permission macOS 15.7 #8690](https://github.com/google-gemini/gemini-cli/issues/8690), [Homebrew/npm version mismatch #5939](https://github.com/google-gemini/gemini-cli/issues/5939)

---

### 9.3 네트워크/프록시 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| GP1 | 기업 프록시 차단 | 연결 오류, API 호출 실패 | 기업 방화벽이 Google API 서버 차단 | settings.json에 proxy 설정 또는 환경변수 사용 |
| GP2 | 프록시 인증 중 미작동 | OAuth 인증 시 프록시 불통 | settings.json의 proxy 설정이 인증 과정에서 적용 안됨 | API 키 인증으로 전환 (OAuth 우회): `export GEMINI_API_KEY=your_key` |
| GP3 | ripgrep 다운로드 프록시 미경유 | 초기화 시 2.5분 지연 | ripgrep 다운로드가 프록시 설정 무시 | `~/.gemini/settings.json`에 `"useRipgrep": false` 설정 |
| GP4 | npm 레지스트리 프록시 설정 | npm install 시 타임아웃 | npm이 프록시 설정 미반영 | `npm config set proxy http://proxy:port && npm config set https-proxy http://proxy:port` |
| GP5 | MCP 로컬 서버 프록시 충돌 | localhost MCP 서버 연결 실패 | 프록시가 localhost 요청도 가로챔 | `NO_PROXY` 환경변수에 localhost 추가 |
| GP6 | --proxy 플래그 미지원 (최신 버전) | `--proxy` 옵션 인식 안됨 | Gemini CLI 0.11.x+ 에서 `--proxy` 인수 제거됨 | settings.json에서 proxy 설정 또는 환경변수 사용 |

**소스**: [Corporate Network issue #4581](https://github.com/google-gemini/gemini-cli/issues/4581), [--proxy removed 0.11.x #12392](https://github.com/google-gemini/gemini-cli/issues/12392), [proxy not working during auth #8616](https://github.com/google-gemini/gemini-cli/issues/8616), [ripgrep hang behind proxy #13611](https://github.com/google-gemini/gemini-cli/issues/13611)

---

### 9.4 인증 문제

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| GA1 | 브라우저 리다이렉트 루프 | 로그인 후 브라우저가 리다이렉트 반복, CLI 대기 중 | OAuth 콜백 URL (`localhost:[port]/oauth2callback`) 접근 실패 | **API 키 인증으로 전환**: `export GEMINI_API_KEY=your_key` |
| GA2 | Safari 연결 불가 | `Safari cannot connect to server` (localhost URL) | Safari가 로컬 OAuth 콜백 서버에 연결 못함 | 다른 브라우저(Chrome)를 기본 브라우저로 설정 후 재시도 |
| GA3 | 인증 미완료 | `The authentication did not complete successfully` | OAuth 흐름 중 타임아웃 또는 취소 | 재시도하거나 API 키 방식 사용 |
| GA4 | 인증 코드 입력 루프 | 인증 코드 요청 → URL 방문 → 다시 인증 요청 반복 | OAuth 콜백 처리 버그 | `npm install -g @google/gemini-cli@latest` 로 최신 버전 업데이트 |
| GA5 | Google Workspace 계정 제한 | 로그인 거부 또는 권한 오류 | 조직 관리자가 Gemini CLI 접근 차단 | Google Workspace 관리자에게 Gemini CLI 활성화 요청 |
| GA6 | 개인 계정 로그인 불가 | `Unable to login with Personal Account` | Google 계정 설정 문제 | Gemini API 키를 직접 생성하여 사용: [aistudio.google.com](https://aistudio.google.com) |

**소스**: [Login redirect loop macOS #2547](https://github.com/google-gemini/gemini-cli/issues/2547), [Auth consistently fails #5580](https://github.com/google-gemini/gemini-cli/issues/5580), [Auth issue #13133](https://github.com/google-gemini/gemini-cli/issues/13133)

**인증 방법 비교**:
```bash
# 방법 1: Google 로그인 (기본, 문제 발생 가능)
gemini    # 자동으로 브라우저 열림

# 방법 2: API 키 (안정적, 권장 대안)
# https://aistudio.google.com 에서 키 생성
export GEMINI_API_KEY=AIzaSy...
gemini

# 방법 3: 서비스 계정 (기업 환경)
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
gemini
```

---

### 9.5 할당량 및 지역 제한

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| GQ1 | 무료 티어 한도 초과 | `429 Too Many Requests` / `RESOURCE_EXHAUSTED` | 무료 티어 RPM/RPD 한도 초과 (5-15 RPM, 모델별 상이) | 잠시 대기 후 재시도, 또는 유료 플랜 업그레이드 |
| GQ2 | 2025.12 무료 티어 대폭 축소 | 갑작스런 429 오류 급증 | 2025년 12월 무료 티어 할당량 50-92% 감소 (Flash: 250→20 RPD) | 유료 플랜 전환 (Google AI Pro/Ultra) 또는 요청 빈도 감소 |
| GQ3 | Gemini 2.5 Pro 무료 제거 | 모델 사용 불가 | 많은 계정에서 Gemini 2.5 Pro가 무료 티어에서 제거됨 | 다른 모델 사용 (Flash 등) 또는 유료 플랜 |
| GQ4 | 지역 제한 | API 접근 불가 또는 특정 기능 차단 | GDPR 규제 (유럽 일부), 제재 국가 (이란, 러시아), 정부 차단 (중국) | VPN 사용 (약관 위반 가능성 있음) 또는 지원 지역에서 사용 |
| GQ5 | Gemini Code Assist 지역 확인 | 특정 국가에서 서비스 미제공 | Google이 해당 국가에서 Gemini Code Assist 미활성화 | [공식 지역 목록](https://developers.google.com/gemini-code-assist/resources/available-locations) 확인 |
| GQ6 | 토큰 한도 초과 | 긴 대화에서 응답 중단 | TPM (tokens per minute) 한도 초과 | 대화 분할 또는 컨텍스트 축소 |

**소스**: [Gemini API Rate Limits](https://ai.google.dev/gemini-api/docs/rate-limits), [Gemini Code Assist Quotas](https://developers.google.com/gemini-code-assist/resources/quotas), [Rate-Limited Free Tier Discussion #2436](https://github.com/google-gemini/gemini-cli/discussions/2436), [Available Regions](https://ai.google.dev/gemini-api/docs/available-regions)

---

## 10. bkit Plugin

### 10.1 Claude Code Plugin (MCP 서버)

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| BP1 | MCP 서버 연결 실패 | `MCP server failed to connect` | MCP 서버 설정 오류 또는 의존성 미설치 | `claude doctor`로 MCP 설정 진단, `.mcp.json` 확인 |
| BP2 | claude mcp add 실패 | `Invalid input` 오류 | JSON 형식 오류 또는 transport 타입 미지원 | `claude mcp add --transport http` 형식 사용 |
| BP3 | GitHub MCP 서버 OAuth 실패 | GitHub 원격 MCP 서버 연결 안됨 | OAuth 인증 흐름 문제 | 토큰 기반 인증으로 전환 또는 로컬 MCP 서버 사용 |
| BP4 | 플러그인 로딩 오류 | `plugin loading error` (claude doctor 출력) | 플러그인 설정 파일 손상 또는 의존성 누락 | 플러그인 재설치, `.claude/settings.json` 확인 |
| BP5 | GitHub 네트워크 접근 불가 | 플러그인 다운로드/설치 타임아웃 | 방화벽/프록시가 github.com 차단 | `github.com`, `raw.githubusercontent.com` 화이트리스트 추가 |
| BP6 | npx 실행 실패 | MCP 서버 npx 실행 오류 | Node.js 미설치 또는 PATH 문제 | Node.js 설치 확인, `which npx` 경로 확인 |
| BP7 | MCP 서버 토큰 사용량 과다 | 컨텍스트 창 소진 경고 | MCP 서버가 너무 많은 토큰 사용 | `claude doctor`에서 MCP 토큰 사용량 확인, 불필요한 MCP 서버 제거 |

**소스**: [MCP servers fail to connect #1611](https://github.com/anthropics/claude-code/issues/1611), [GitHub remote MCP #3433](https://github.com/anthropics/claude-code/issues/3433), [Claude Code Plugins](https://data-wise.github.io/claude-plugins/installation/)

**MCP 진단 및 설정**:
```bash
# MCP 서버 상태 진단
claude doctor

# MCP 서버 추가 (HTTP transport)
claude mcp add --transport http my-server https://example.com/mcp

# MCP 서버 목록 확인
claude mcp list

# MCP 디버그 모드
claude --mcp-debug
```

---

### 10.2 Gemini CLI Extensions

| # | 환경/조건 | 에러 메시지/증상 | 원인 | 해결 방법 |
|---|----------|----------------|------|----------|
| GE1 | extensions install 실패 | 확장 설치 오류 | npm 레지스트리 접근 불가 또는 권한 문제 | npm 프록시 설정 확인, 권한 확인 |
| GE2 | MCP 서버 호환성 | MCP 서버 프로토콜 불일치 | Gemini CLI MCP 구현과 서버 버전 불일치 | 호환 가능한 MCP 서버 버전 사용 |
| GE3 | GitHub 접근 차단 | 확장 소스 다운로드 실패 | 기업 방화벽이 GitHub 차단 | GitHub 도메인 화이트리스트 추가 |
| GE4 | 인증 필요 확장 | 확장이 추가 인증 요구 | 확장이 별도 API 키/토큰 필요 | 각 확장 문서에 따라 인증 설정 |

---

## 11. 환경별 위험도 매트릭스 (종합)

> Homebrew/Node.js/Git/VS Code/Docker Desktop/Antigravity + Claude Code CLI + Gemini CLI + bkit Plugin 전체 통합

| 에러 카테고리 | 일반 사용자 | Apple Silicon | Intel Mac | 기업 환경 | 개발자 환경 |
|-------------|-----------|--------------|----------|----------|-----------|
| **Xcode CLT 문제** | **높음** | **높음** | **높음** | **높음** | 중간 |
| **nvm/fnm/volta 충돌** | 낮음 | 낮음 | 낮음 | 중간 | **높음** |
| **npm EACCES** | 중간 | 중간 | 중간 | 중간 | 중간 |
| **아키텍처 불일치 (Node/CLI)** | 낮음 | **높음** | 해당없음 | **높음** | **높음** |
| **node-gyp 에러** | 낮음 | **높음** | 중간 | **높음** | **높음** |
| **프록시/VPN/방화벽** | 낮음 | 낮음 | 낮음 | **높음** | 중간 |
| **VS Code Homebrew Cask 실패** | 중간 | 중간 | 중간 | **높음** | 낮음 |
| **VS Code `code` PATH 문제** | **높음** | **높음** | **높음** | 중간 | 중간 |
| **VS Code Gatekeeper 차단** | 중간 | 중간 | 중간 | **높음** | 낮음 |
| **VS Code Extension 설치 실패** | 중간 | 중간 | 중간 | **높음** | 중간 |
| **VS Code Insiders/Stable 충돌** | 낮음 | 낮음 | 낮음 | 낮음 | **높음** |
| **VS Code 기업 MDM 차단** | 낮음 | 낮음 | 낮음 | **높음** | 낮음 |
| **VS Code Rosetta 2 호환성** | 낮음 | **높음** | 해당없음 | 중간 | 중간 |
| **VS Code Remote SSH 문제** | 낮음 | 중간 | 중간 | **높음** | **높음** |
| **Docker Desktop Apple Silicon 호환** | 낮음 | **높음** | 해당없음 | **높음** | **높음** |
| **Docker Desktop Rosetta 2 요구** | 낮음 | **높음** | 해당없음 | 중간 | 중간 |
| **Docker Desktop 라이선스 위반** | 낮음 | 낮음 | 낮음 | **높음** | 낮음 |
| **Docker QEMU→VF 마이그레이션** | 중간 | **높음** | 해당없음 | **높음** | **높음** |
| **Docker 데몬 미시작** | **높음** | **높음** | **높음** | 중간 | 중간 |
| **Docker 메모리/CPU 부족** | 중간 | 중간 | **높음** | 중간 | **높음** |
| **Docker Bind Mount 성능** | 낮음 | 중간 | 중간 | 중간 | **높음** |
| **Docker VPN 네트워크 충돌** | 낮음 | 낮음 | 낮음 | **높음** | 중간 |
| **Docker macOS 버전 호환성** | 중간 | 중간 | 중간 | **높음** | 중간 |
| **Docker `docker` 명령어 미등록** | **높음** | **높음** | **높음** | 중간 | 낮음 |
| **Docker 디스크 공간 부족** | 중간 | 중간 | 중간 | 중간 | **높음** |
| **Docker 기업 프록시** | 낮음 | 낮음 | 낮음 | **높음** | 중간 |
| **Antigravity Cask 설치 실패** | **높음** | **높음** | **높음** | **높음** | 중간 |
| **Antigravity Gatekeeper 차단** | 중간 | 중간 | 중간 | **높음** | 낮음 |
| **Antigravity `agy` PATH 문제** | **높음** | **높음** | **높음** | 중간 | 중간 |
| **Antigravity Google 계정 제한** | **높음** | **높음** | **높음** | **높음** | 중간 |
| **Antigravity Copilot 충돌** | 낮음 | 낮음 | 낮음 | 중간 | **높음** |
| **Antigravity OpenVSX 제한** | 중간 | 중간 | 중간 | **높음** | **높음** |
| **Claude Code PATH 문제** | **높음** | **높음** | **높음** | 중간 | 중간 |
| **Claude Code Gatekeeper** | 중간 | 중간 | 중간 | **높음** | 낮음 |
| **Claude Code 인증 루프** | 중간 | 중간 | 중간 | **높음** | 중간 |
| **Claude Code 혼합 설치 충돌** | 낮음 | 낮음 | 낮음 | 낮음 | **높음** |
| **Claude Code VS Code 확장 메모리** | 중간 | 중간 | 중간 | 중간 | 중간 |
| **Gemini CLI Node.js 20+ 요구** | **높음** | **높음** | **높음** | **높음** | 낮음 |
| **Gemini CLI command not found** | **높음** | **높음** | **높음** | 중간 | 중간 |
| **Gemini CLI OAuth 리다이렉트 루프** | 중간 | 중간 | 중간 | **높음** | 중간 |
| **Gemini CLI 할당량 한도** | 중간 | 중간 | 중간 | 낮음 | **높음** |
| **Gemini CLI Homebrew EACCES** | 중간 | 중간 | 중간 | **높음** | 중간 |
| **bkit MCP 연결 실패** | 중간 | 중간 | 중간 | **높음** | 중간 |
| **SSL 인증서 (전체)** | 낮음 | 낮음 | 낮음 | **높음** | 낮음 |
| **Git Credential/SSH** | 중간 | 중간 | 중간 | **높음** | **높음** |
| **brew link 에러** | 중간 | 중간 | 중간 | 중간 | **높음** |

---

## 12. Top 15 빈출 에러 (종합)

발생 빈도와 사용자 영향도를 기준으로 정렬 (Homebrew/Node.js/Git/VS Code/Docker Desktop/Antigravity + Claude Code + Gemini CLI + bkit Plugin 전체 통합):

| 순위 | 에러 | 관련 코드 | 발생 빈도 | 영향도 | 주 대상 환경 |
|------|------|----------|----------|--------|------------|
| 1 | **`claude: command not found` (PATH 미설정)** | CS1, CS2, CS7 | **매우 높음** | **높음** (설치 완전 차단) | 모든 환경 |
| 2 | **Xcode CLT 미설치/무효화** | XC1, XC2 | **매우 높음** | **높음** | 모든 환경 (macOS 업그레이드 후) |
| 3 | **Docker Desktop 데몬 미시작 (`Cannot connect to the Docker daemon`)** | DD1-DD5 | **매우 높음** | **높음** (Docker 사용 불가) | 모든 환경 |
| 4 | **VS Code `code: command not found` (PATH 미등록)** | VP1-VP5 | **높음** | **높음** (터미널 워크플로 차단) | 모든 환경 |
| 5 | **`gemini: command not found` (PATH/Node.js)** | GN2, GN8 | **높음** | **높음** (설치 차단) | 모든 환경 |
| 6 | **Docker `docker: command not found` (심볼릭 링크 미생성)** | DC1-DC4 | **높음** | **높음** (Docker CLI 사용 불가) | 모든 환경 |
| 7 | **npm EACCES 권한 에러** | NP1, CN1, GN1 | **높음** | 중간 | 모든 환경 |
| 8 | **Antigravity Google 계정 인증/지역 제한** | AA1-AA5 | **높음** | **높음** (사용 완전 차단) | 미지원 국가, 기업 환경 |
| 9 | **VS Code / Antigravity Gatekeeper 차단** | VG1-VG4, AQ1-AQ4 | **높음** | 중간 (우회 가능) | 일반 사용자, 기업 환경 |
| 10 | **Claude Code Gatekeeper 경고** | CM1, CM2 | **높음** | 중간 (우회 가능) | 일반 사용자, 기업 환경 |
| 11 | **Docker Desktop QEMU 지원 종료 (2025.07)** | DV1-DV4 | 중간 | **높음** (VM 실행 불가) | Apple Silicon 환경 |
| 12 | **Docker Desktop 라이선스 위반 (250+ 직원)** | DL1-DL3 | 중간 (기업 한정) | **높음** (법적 리스크) | 기업 환경 |
| 13 | **Claude Code 인증 무한 루프 (키체인)** | CA2, CA3 | 중간 | **높음** (사용 차단) | macOS SSH 사용자, 기업 환경 |
| 14 | **기업 프록시/SSL 인터셉션 (Docker/VS Code/CLI 전체)** | CP1, CP2, GP1, NR2, GS1, DP1-DP5 | 중간 (기업 한정) | **높음** (완전 차단) | 기업 환경 |
| 15 | **Antigravity OpenVSX 확장 부족/보안 이슈** | AO1-AO4 | 중간 | 중간 (워크플로 제한) | 개발자 환경 |

---

## 참고 자료

### Node.js 관련
- [npm 공식 문서 - EACCES 권한 에러 해결](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally/)
- [node-gyp GitHub - macOS 설치 가이드](https://github.com/nodejs/node-gyp)
- [node-gyp Python 3.12 distutils 이슈](https://github.com/nodejs/node-gyp/issues/2869)
- [node-gyp macOS Sonoma CLT 이슈](https://github.com/nodejs/node-gyp/issues/2992)
- [npm 공식 문서 - 일반 에러](https://docs.npmjs.com/common-errors/)

### Git 관련
- [GitHub Docs - macOS Keychain 자격 증명 업데이트](https://docs.github.com/en/get-started/getting-started-with-git/updating-credentials-from-the-macos-keychain)
- [GitHub Docs - SSH 키 생성 및 ssh-agent 등록](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [GitHub Docs - ssh-add illegal option 에러](https://docs.github.com/en/authentication/troubleshooting-ssh/error-ssh-add-illegal-option----apple-use-keychain)
- [Git 공식 문서 - Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)
- [기업 환경 Git SSL 인증서 이슈 해결](https://konkretor.com/2024/11/01/understanding-and-fixing-git-ssl-certificate-issues-in-corporate-environments/)

### VS Code 관련
- [VS Code macOS Setup 공식 가이드](https://code.visualstudio.com/docs/setup/mac)
- [VS Code Command Line Interface (code 명령어)](https://code.visualstudio.com/docs/editor/command-line)
- [VS Code Network Connections (프록시 설정)](https://code.visualstudio.com/docs/setup/network)
- [VS Code Remote SSH 문서](https://code.visualstudio.com/docs/remote/ssh)
- [VS Code Extension Marketplace](https://code.visualstudio.com/docs/editor/extension-marketplace)
- [VS Code macOS Catalina EOL (1.97 릴리스)](https://code.visualstudio.com/updates/v1_97)
- [VS Code GitHub - SHA256 mismatch cask issue](https://github.com/Homebrew/homebrew-cask/issues?q=visual-studio-code+sha256)
- [VS Code MDM 배포 가이드](https://code.visualstudio.com/docs/setup/enterprise)
- [VS Code Apple Silicon (Universal Build)](https://code.visualstudio.com/docs/supporting/faq#_apple-silicon)

### Docker Desktop 관련
- [Docker Desktop macOS 설치 가이드](https://docs.docker.com/desktop/setup/install/mac-install/)
- [Docker Desktop 릴리스 노트](https://docs.docker.com/desktop/release-notes/)
- [Docker Desktop 라이선스 FAQ](https://www.docker.com/pricing/faq/)
- [Docker Desktop Virtualization Framework 설정](https://docs.docker.com/desktop/settings-and-maintenance/settings/#general)
- [Docker Desktop 파일 공유 백엔드 (VirtioFS)](https://docs.docker.com/desktop/settings-and-maintenance/settings/#file-sharing)
- [Docker Desktop 네트워크 설정](https://docs.docker.com/desktop/networking/)
- [Docker Desktop 프록시 설정](https://docs.docker.com/desktop/settings-and-maintenance/settings/#proxies)
- [Docker Desktop Troubleshooting (macOS)](https://docs.docker.com/desktop/troubleshoot-and-support/troubleshoot/topics/)
- [Docker QEMU 지원 종료 공지 (2025년 7월)](https://docs.docker.com/desktop/release-notes/#4410)
- [Docker Desktop Synchronized File Shares](https://docs.docker.com/desktop/features/synchronized-file-sharing/)
- [Docker Desktop 시스템 요구사항](https://docs.docker.com/desktop/setup/install/mac-install/#system-requirements)

### Antigravity (Google) 관련
- [Google Antigravity 공식 사이트](https://idx.google.com/antigravity)
- [Antigravity 설치 가이드 (macOS)](https://developers.google.com/idx/guides/antigravity-install)
- [OpenVSX Registry](https://open-vsx.org/)
- [OpenVSX 보안 취약점 보고 (2025년 12월)](https://www.bleepingcomputer.com/news/security/malicious-vscode-extensions-found-on-open-vsx-registry/)
- [Google 계정 연령 제한 정책](https://support.google.com/accounts/answer/1350409)
- [Antigravity GitHub Copilot 호환성 이슈](https://github.com/nicolo-ribaudo/tc39-proposal-seeded-random/issues)

### macOS / Homebrew 관련
- [Homebrew FAQ](https://docs.brew.sh/FAQ)
- [Homebrew Discussion - keg-only 설명](https://github.com/orgs/Homebrew/discussions/239)
- [Apple Silicon Homebrew 아키텍처 에러 수정](https://osxdaily.com/2024/07/06/fix-brew-error-the-arm64-architecture-is-required-for-this-software-on-apple-silicon-mac/)

### Claude Code 공식 문서
- [Claude Code Troubleshooting](https://code.claude.com/docs/en/troubleshooting)
- [Claude Code Setup](https://code.claude.com/docs/en/setup)
- [Enterprise Network Configuration](https://code.claude.com/docs/en/network-config)
- [Claude Code VS Code Extension](https://code.claude.com/docs/en/vs-code)

### Claude Code GitHub Issues (주요)
- [Homebrew symlink issue #3172](https://github.com/anthropics/claude-code/issues/3172)
- [PATH expansion bug #6090](https://github.com/anthropics/claude-code/issues/6090)
- [Incorrect PATH syntax for zsh #5177](https://github.com/anthropics/claude-code/issues/5177)
- [PATH Fails with Quoted Tilde #4453](https://github.com/anthropics/claude-code/issues/4453)
- [claude install doesn't persist PATH #21069](https://github.com/anthropics/claude-code/issues/21069)
- [npm/native conflict #7734](https://github.com/anthropics/claude-code/issues/7734)
- [Native installer deletes working npm #26173](https://github.com/anthropics/claude-code/issues/26173)
- [Auto-updater reinstalls npm-global #22415](https://github.com/anthropics/claude-code/issues/22415)
- [Gatekeeper .node warning #14911](https://github.com/anthropics/claude-code/issues/14911)
- [Homebrew blocked by Gatekeeper #19897](https://github.com/anthropics/claude-code/issues/19897)
- [ARM64 binary replaced #13617](https://github.com/anthropics/claude-code/issues/13617)
- [Architecture Mismatch Apple Silicon #4749](https://github.com/anthropics/claude-code/issues/4749)
- [Wrong architecture install #15571](https://github.com/anthropics/claude-code/issues/15571)
- [Segfault on macOS Silicon #15925](https://github.com/anthropics/claude-code/issues/15925)
- [Bun crash #7848](https://github.com/anthropics/claude-code/issues/7848)
- [Auth loop macOS #8280](https://github.com/anthropics/claude-code/issues/8280)
- [Invalid API key #5167](https://github.com/anthropics/claude-code/issues/5167)
- [Login not persisting Mac SSH #5225](https://github.com/anthropics/claude-code/issues/5225)
- [VS Code crash ARM64 #10496](https://github.com/anthropics/claude-code/issues/10496)
- [Memory Leak 11.6GB #21182](https://github.com/anthropics/claude-code/issues/21182)
- [Extension host terminated #12229](https://github.com/anthropics/claude-code/issues/12229)
- [Not compatible macOS Tahoe #2270](https://github.com/anthropics/claude-code/issues/2270)
- [Self-signed certificate #24470](https://github.com/anthropics/claude-code/issues/24470)
- [Connection Refused #17541](https://github.com/anthropics/claude-code/issues/17541)
- [MCP servers fail #1611](https://github.com/anthropics/claude-code/issues/1611)
- [GitHub remote MCP #3433](https://github.com/anthropics/claude-code/issues/3433)

### Gemini CLI 공식 문서
- [Gemini CLI Troubleshooting Guide](https://google-gemini.github.io/gemini-cli/docs/troubleshooting.html)
- [Gemini CLI Installation](https://geminicli.com/docs/get-started/installation/)
- [Gemini CLI Authentication](https://google-gemini.github.io/gemini-cli/docs/get-started/authentication.html)
- [Gemini CLI FAQ](https://google-gemini.github.io/gemini-cli/docs/faq.html)
- [Gemini CLI Enterprise](https://geminicli.com/docs/cli/enterprise/)
- [Gemini API Rate Limits](https://ai.google.dev/gemini-api/docs/rate-limits)
- [Gemini Code Assist Quotas](https://developers.google.com/gemini-code-assist/resources/quotas)
- [Available Regions](https://ai.google.dev/gemini-api/docs/available-regions)
- [Available Locations - Code Assist](https://developers.google.com/gemini-code-assist/resources/available-locations)

### Gemini CLI GitHub Issues (주요)
- [npm install fails #2264](https://github.com/google-gemini/gemini-cli/issues/2264)
- [Installation impossible #7795](https://github.com/google-gemini/gemini-cli/issues/7795)
- [Installing/running fails #14173](https://github.com/google-gemini/gemini-cli/issues/14173)
- [EBADENGINE Node.js v20 #2870](https://github.com/google-gemini/gemini-cli/issues/2870)
- [command not found #8397](https://github.com/google-gemini/gemini-cli/issues/8397)
- [command not found #2225](https://github.com/google-gemini/gemini-cli/issues/2225)
- [PATH issue after update #13248](https://github.com/google-gemini/gemini-cli/issues/13248)
- [npx GitHub fails #2077](https://github.com/google-gemini/gemini-cli/issues/2077)
- [Updates do not apply #4076](https://github.com/google-gemini/gemini-cli/issues/4076)
- [npm PATH conflict #5886](https://github.com/google-gemini/gemini-cli/issues/5886)
- [Homebrew/npm version mismatch #5939](https://github.com/google-gemini/gemini-cli/issues/5939)
- [EOVERRIDE crash #15627](https://github.com/google-gemini/gemini-cli/issues/15627)
- [EACCES Homebrew first run #13547](https://github.com/google-gemini/gemini-cli/issues/13547)
- [Temp folder permission macOS 15.7 #8690](https://github.com/google-gemini/gemini-cli/issues/8690)
- [OAuth redirect loop macOS #2547](https://github.com/google-gemini/gemini-cli/issues/2547)
- [Auth consistently fails #5580](https://github.com/google-gemini/gemini-cli/issues/5580)
- [Auth issue #13133](https://github.com/google-gemini/gemini-cli/issues/13133)
- [Auth Error #4546](https://github.com/google-gemini/gemini-cli/issues/4546)
- [Corporate Network #4581](https://github.com/google-gemini/gemini-cli/issues/4581)
- [--proxy removed 0.11.x #12392](https://github.com/google-gemini/gemini-cli/issues/12392)
- [proxy not working during auth #8616](https://github.com/google-gemini/gemini-cli/issues/8616)
- [ripgrep hang behind proxy #13611](https://github.com/google-gemini/gemini-cli/issues/13611)
- [ripgrep download timeout #18045](https://github.com/google-gemini/gemini-cli/issues/18045)
- [Rate-Limited Free Tier Discussion #2436](https://github.com/google-gemini/gemini-cli/discussions/2436)
