# Base Module 설치 에러 케이스 종합 보고서

> **작성일**: 2026-02-23
> **대상**: `installer/modules/base/install.ps1`
> **목적**: 다양한 Windows 환경에서 base 모듈 설치 시 발생 가능한 모든 에러 케이스 정리

---

## 목차

1. [개요](#1-개요)
2. [winget (Step 1)](#2-winget-step-1)
3. [Node.js (Step 2)](#3-nodejs-step-2)
4. [Git (Step 3)](#4-git-step-3)
5. [VS Code / Antigravity (Step 4)](#5-vs-code--antigravity-step-4)
6. [**VS Code 확장 설치 (Step 4 부속)**](#6-vs-code-확장-설치-step-4-부속)
7. [WSL (Step 5)](#7-wsl-step-5)
8. [Docker Desktop (Step 6)](#8-docker-desktop-step-6)
9. [Claude Code CLI / Gemini CLI (Step 7)](#9-claude-code-cli--gemini-cli-step-7)
10. [bkit Plugin (Step 8)](#10-bkit-plugin-step-8)
11. [공통 에러 (Cross-cutting)](#11-공통-에러-cross-cutting)
12. [Top 10 빈출 에러](#12-top-10-빈출-에러)
13. [환경별 위험도 매트릭스](#13-환경별-위험도-매트릭스)

---

## 1. 개요

### 설치 대상 프로그램

| Step | 프로그램 | 설치 방법 | 필수 여부 |
|------|---------|----------|----------|
| 1 | winget | 사전 필수 (검증만) | **필수** |
| 2 | Node.js LTS | `winget install OpenJS.NodeJS.LTS` | **필수** |
| 3 | Git | `winget install Git.Git` | **필수** |
| 4 | VS Code / Antigravity | `winget install Microsoft.VisualStudioCode` | **필수** |
| 5 | WSL | `wsl --install --no-distribution` | Docker 필요 시 |
| 6 | Docker Desktop | `winget install Docker.DockerDesktop` | 모듈 필요 시 |
| 7 | Claude Code CLI | `irm https://claude.ai/install.ps1 \| iex` | **필수** |
| 8 | bkit Plugin | `claude plugin marketplace add ...` | **필수** |

### 테스트 대상 환경 유형

- **일반 가정용 PC**: Windows 11 Home, 보안 설정 기본값
- **기업 환경 (AD 관리)**: Group Policy, 프록시, 방화벽
- **교육기관**: 제한된 사용자 권한, 필터링
- **구버전 Windows**: Windows 10 1809~21H2
- **특수 에디션**: Windows 11 S Mode, LTSC, Server

---

## 2. winget (Step 1)

> 현재 코드: winget 없으면 에러 throw하고 종료

### 에러 케이스

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| W1 | Windows 10 1709 이하 | `winget not found` | winget은 1809+ 필요 | Windows 업데이트 또는 수동 설치 안내 |
| W2 | Windows LTSC (2019/2021) | `winget not found` | LTSC에는 Microsoft Store 없음 → App Installer 미포함 | GitHub에서 `.msixbundle` 수동 설치 |
| W3 | Windows Server 2019/2022 | `winget not found` | Server에 기본 미포함 | Server 2025부터 기본 포함. 이전 버전은 수동 설치 |
| W4 | Windows 11 S Mode | `winget not found` 또는 설치 차단 | S Mode는 Store 앱만 허용 | S Mode 해제 필요 (설정 > 활성화) |
| W5 | 기업 환경 (MSIX sideload 차단) | App Installer 설치 불가 | Group Policy로 sideload 차단 | IT 관리자에게 요청 |
| W6 | 손상된 App Installer | `winget` 명령 있으나 실행 안됨 | App Installer 패키지 손상 | `Add-AppxPackage -Register` 재등록 또는 Store에서 재설치 |
| W7 | winget 소스 미동의 | `agreements not accepted` | 첫 실행 시 소스 동의 필요 | `--accept-source-agreements` 플래그 (이미 적용됨) |

### 현재 코드의 대응 수준

```
현재: winget 없으면 throw → 설치 중단
개선 필요:
  - LTSC/Server 감지 시 수동 설치 가이드 표시
  - App Installer Store 링크 제공 (이미 구현)
  - GitHub releases 직접 다운로드 fallback 추가 고려
```

---

## 3. Node.js (Step 2)

> 현재 코드: `winget install OpenJS.NodeJS.LTS` → `Refresh-Path` → 확인

### 에러 케이스

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| N1 | 관리자 권한 없음 | `Access denied` / 설치 실패 | winget이 관리자 권한 필요할 수 있음 | UAC 프롬프트 허용 또는 `--scope user` 사용 |
| N2 | 기존 Node.js (nvm 설치) | 충돌 또는 PATH 우선순위 문제 | nvm-windows가 PATH를 관리하여 충돌 | nvm 존재 시 winget 설치 스킵 |
| N3 | 기존 Node.js (직접 설치) | `A newer version already installed` | winget 버전 < 기존 설치 버전 | 무시해도 됨 (이미 설치됨) |
| N4 | PATH 미반영 | `node not found` (설치 후) | winget 설치 완료 후 PATH 미갱신 | `Refresh-Path` (이미 구현) → 그래도 안되면 터미널 재시작 |
| N5 | 프록시/방화벽 | winget 다운로드 실패 | 기업 프록시가 CDN 차단 | `winget settings` 에서 프록시 설정 또는 오프라인 설치 |
| N6 | SSL 인증서 검사 (MITM) | `certificate verify failed` | 기업 보안 솔루션이 SSL 가로채기 | 기업 인증서 신뢰 저장소 추가 |
| N7 | 디스크 공간 부족 | 설치 실패 | C: 드라이브 여유 공간 부족 | 공간 확보 후 재시도 |
| N8 | 바이러스 백신 차단 | 설치 파일 격리 | Norton, Kaspersky 등이 msi를 의심 | 일시적 AV 비활성화 또는 예외 추가 |
| N9 | ARM64 Windows | 호환성 문제 가능 | Node.js ARM64 빌드 확인 필요 | ARM64용 Node.js는 지원됨 (v18+) |

### 현재 코드의 대응 수준

```
현재: 설치 → PATH 갱신 → 확인 → 실패 시 "restart terminal" 안내
개선 필요:
  - nvm 존재 여부 검사 추가
  - `--scope user` fallback (관리자 권한 없을 때)
  - 기존 설치 감지 시 스킵 로직 강화
```

---

## 4. Git (Step 3)

> 현재 코드: `winget install Git.Git` → `Refresh-Path` → 확인

### 에러 케이스

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| G1 | PATH 미반영 | `git not found` (설치 후) | Git이 `C:\Program Files\Git\cmd`에 설치되나 PATH 미등록 | `Refresh-Path` + 수동 PATH 추가 |
| G2 | 기존 Git (다른 방식 설치) | 버전 충돌 | Chocolatey/Scoop/수동 설치 Git과 충돌 | 기존 설치 감지 후 스킵 |
| G3 | 기업 프록시 | Git clone/fetch 실패 (설치는 OK) | `https_proxy` 미설정 | `git config --global http.proxy` 설정 안내 |
| G4 | SSL 인증서 (기업) | `SSL certificate problem: unable to get local issuer certificate` | 기업 MITM 프록시 | `git config --global http.sslCAInfo <cert-path>` |
| G5 | 관리자 권한 없음 | 설치 실패 | Program Files에 쓰기 권한 없음 | `--scope user` 또는 portable Git 사용 |
| G6 | 긴 경로 (260자 초과) | `Filename too long` | Windows 기본 MAX_PATH=260 | `git config --global core.longpaths true` |
| G7 | 한글 파일명 | `UTF-8 encoding error` 또는 깨짐 | Git 기본 설정이 UTF-8 아닐 수 있음 | `git config --global core.quotepath false` |
| G8 | 실행 정책 (설치 후 스크립트) | Git Bash 관련 스크립트 차단 | PowerShell 실행 정책 | `Set-ExecutionPolicy` 이미 상위에서 처리 |

### 현재 코드의 대응 수준

```
현재: 설치 → PATH 갱신 → 확인 → 실패 시 "restart terminal" 안내
개선 필요:
  - 기업 환경 프록시/SSL 검사 안내 메시지
  - longpaths 자동 설정 고려
  - UTF-8 설정 자동 적용 고려
```

---

## 5. VS Code / Antigravity (Step 4)

> 현재 코드: 경로 직접 확인 → 없으면 winget 설치 → Claude 확장 설치

### 에러 케이스

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| V1 | VS Code Insiders 설치됨 | 감지 실패 (다른 경로) | Insiders 버전은 다른 경로에 설치 | Insiders 경로도 검사에 추가 |
| V2 | VS Code Portable 버전 | 감지 실패 | 임의 경로에 압축 해제하여 사용 | `code` 명령어로도 검사 |
| V3 | System 설치 vs User 설치 | 경로 불일치 | winget은 User 설치, 기존은 System 설치 | 두 경로 모두 검사 (이미 구현) |
| V4 | 확장 설치 실패 (오프라인) | `code --install-extension` 실패 | 확장 마켓플레이스 접근 불가 | 오프라인 `.vsix` 설치 방법 안내 |
| V5 | 기업 확장 제한 | 확장 설치 차단 | 기업 정책으로 특정 확장 차단 | IT 관리자에게 허용 요청 |
| V6 | `code` 명령 미등록 | `code not found` (확장 설치 불가) | VS Code PATH 등록 안됨 | VS Code 설정 > "Add to PATH" 또는 수동 등록 |
| V7 | 디스크 공간 부족 | 설치 실패 | VS Code + 확장 ~500MB 필요 | 공간 확보 후 재시도 |
| V8 | Antigravity winget ID 미등록 | `No package found` | Antigravity가 winget 카탈로그에 없을 수 있음 | 직접 다운로드 fallback 추가 |

### 5-2. Antigravity IDE (Gemini 선택 시)

> 현재 코드: `winget install Google.Antigravity` + 경로 직접 확인
> **winget ID**: `Google.Antigravity` (확인됨)
> **CLI 명령어**: `agy` (VS Code의 `code`에 해당)
> **확장 마켓플레이스**: OpenVSX (VS Code Marketplace 아님)

#### 🚨 스크립트 버그 발견: 설치 경로 오류

| 스크립트의 현재 경로 (틀림) | 실제 설치 경로 |
|---------------------------|--------------|
| `$env:LOCALAPPDATA\Programs\Antigravity\Antigravity.exe` | **존재하지 않음** |
| `$env:ProgramFiles\Antigravity\Antigravity.exe` | **존재하지 않음** |
| (없음) | `$env:ProgramFiles\Google\Antigravity\Antigravity.exe` (**실제 경로**) |

→ **결과**: 이미 설치된 Antigravity를 감지하지 못하고 매번 재설치 시도

#### 에러 케이스

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| AG1 | 경로 감지 버그 | (에러 없음 - 재설치 반복) | 스크립트 경로에 `Google\` 누락 | 경로를 `$env:ProgramFiles\Google\Antigravity\Antigravity.exe`로 수정 |
| AG2 | 관리자 권한 없음 | `The installer failed with exit code: 1` | Inno Setup이 `C:\Program Files\`에 설치 → 관리자 필요 | 관리자로 실행 |
| AG3 | winget 소스 미업데이트 | `No applicable installer found` | winget 소스가 오래됨 | `winget source update` 실행 |
| AG4 | `agy` PATH 미등록 | `'agy' is not recognized` | 설치 후 PATH 미갱신 | 터미널 재시작 또는 `Refresh-Path` |
| AG5 | SmartScreen 차단 | `Windows Defender SmartScreen prevented an unrecognized app` | 새 실행 파일 경고 | `-h` 플래그 사용 중이면 팝업이 차단될 수 있음 |
| AG6 | Google Workspace 계정 차단 | `Your current account is not eligible for Antigravity` | 관리자가 "Experimental AI" 비활성화 | 개인 @gmail.com 사용 또는 관리자가 활성화 |
| AG7 | 미지원 국가 (중국, 러시아 등) | `Your current account is not eligible` | 계정 국가가 미지원 지역 | Google 국가 연결 변경 (24-48시간 소요) |
| AG8 | 18세 미만 계정 | `not eligible` | Google AI 기능은 18세+ 필요 | 18세 이상 계정 사용 |
| AG9 | GitHub Copilot 확장 충돌 | Antigravity 로딩 화면에서 프리즈 | VS Code에서 가져온 Copilot 확장이 충돌 | Copilot 확장 비활성화 |
| AG10 | 버전 강제 업데이트 | `This version is no longer supported. Please update` | 구버전 하드 디프리케이션 | 최신 버전 클린 재설치 |
| AG11 | 확장 마켓플레이스 접근 | VS Code 확장 검색 안됨 | OpenVSX 사용, VS Code Marketplace 아님 | `agy --install-extension` 또는 수동 .vsix 설치 |
| AG12 | ARM64 아키텍처 불일치 | `No applicable installer found for the machine architecture` | 자동 감지 실패 | `winget install Google.Antigravity --architecture arm64` |
| AG13 | 무료 쿼타 초과 | `Model quota limit exceeded` | 무료 티어 한도 초과 | 쿼타 리셋 대기 (5시간) 또는 AI Pro 구독 |
| AG14 | 인증 토큰 손상 | 로그인 반복 실패 | 로컬 인증 토큰 손상 | `%APPDATA%\Antigravity\auth-tokens` 삭제 후 재시작 |

#### Gemini CLI 연동 에러

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| GM-AG1 | Gemini CLI가 Antigravity 미감지 | `No installer is available for IDE` | `agy` 바이너리 PATH 미등록 | PATH에 Antigravity bin 디렉토리 추가 |
| GM-AG2 | IDE Companion 확장 연결 실패 | `Failed to connect to IDE companion extension` | 환경 변수 미설정 | Antigravity에서 `/ide install` 실행 |
| GM-AG3 | GEMINI.md 설정 충돌 | Antigravity + Gemini CLI가 같은 파일 덮어씀 | 두 도구가 `~/.gemini/GEMINI.md` 공유 | 수동 병합 관리 |

### 현재 코드의 대응 수준

```
현재:
  VS Code: 경로 직접 확인 → winget 설치 → code 명령으로 확장 설치
  Antigravity: 경로 직접 확인 → winget 설치 (경로 버그!)

VS Code 개선 필요:
  - `code` 명령 PATH 등록 여부 확인
  - Insiders 버전 경로 추가
  - 확장 설치 실패 시 에러 핸들링 (현재 2>$null로 무시)

Antigravity 개선 필요 (Critical):
  - 🚨 설치 경로 수정 필수: Google\ 하위 폴더
  - `agy` CLI PATH 확인 추가
  - 확장은 `agy --install-extension` 사용 (code와 다름)
  - Google 계정/지역 제한 사전 안내
  - Copilot 충돌 경고
```

---

## 6. VS Code 확장 설치 (Step 4 부속)

> 현재 코드:
> - base: `code --install-extension anthropic.claude-code 2>$null`
> - pencil 모듈: `code --install-extension highagency.pencildev 2>$null`

### 6-1. `code` 명령어 문제

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| EX1 | VS Code 설치 시 "Add to PATH" 미체크 | `'code' is not recognized` (CMD) / `The term 'code' is not recognized` (PS) | VS Code `bin` 디렉토리가 PATH에 없음 | PATH에 수동 추가: `%LOCALAPPDATA%\Programs\Microsoft VS Code\bin` |
| EX2 | Microsoft Store에서 VS Code 설치 | `code` 명령어 미등록 | Store 버전은 PATH 등록 옵션이 없음 | 공식 installer로 재설치 (PATH 체크) |
| EX3 | VS Code Insiders만 설치됨 | `code` 없고 `code-insiders`만 있음 | Insiders는 별도 명령어 사용 | `code-insiders --install-extension` 사용 |
| EX4 | Portable VS Code (ZIP 압축 해제) | `code` 명령어 없음 | Portable 모드는 시스템 등록 안함 | 전체 경로로 실행: `<설치경로>\bin\code.cmd` |
| EX5 | System 설치 + User 설치 공존 | 잘못된 VS Code 버전에 확장 설치됨 | PATH 우선순위에 따라 다른 `code` 실행 | 하나 제거하거나 전체 경로 사용 |
| EX6 | Cursor IDE 사용 | `code` 명령어가 Cursor와 무관 | Cursor는 별도 확장 디렉토리 (`~/.cursor/extensions/`) 사용 | `cursor --install-extension` 사용 또는 Cursor 내에서 수동 설치 |

### 6-2. 네트워크/다운로드 문제

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| EX7 | 기업 프록시 | `XHR failed` / CLI 타임아웃 | 프록시가 `marketplace.visualstudio.com` 차단 | `"http.proxy"` 설정 + 도메인 화이트리스트 |
| EX8 | SSL MITM 검사 (zScaler 등) | `UNABLE_TO_GET_ISSUER_CERT_LOCALLY` / `SELF_SIGNED_CERT_IN_CHAIN` | VS Code는 자체 Node.js 인증서 스토어 사용 → 기업 CA 미인식 | `NODE_EXTRA_CA_CERTS` 환경변수 설정 또는 `"http.proxyStrictSSL": false` |
| EX9 | 방화벽 차단 | `net::ERR_CONNECTION_TIMED_OUT` | 필수 도메인 접근 불가 | 아래 도메인 목록 화이트리스트 |
| EX10 | 느린 네트워크 | `XHR timeout` / 설치 멈춤 | 대용량 확장 다운로드 타임아웃 | 재시도 또는 VSIX 수동 다운로드 |
| EX11 | DNS 오류 | `getaddrinfo ENOTFOUND` | DNS가 마켓플레이스 도메인 해석 불가 | DNS 변경 (8.8.8.8 등) |

**확장 마켓플레이스 필수 도메인:**

| 도메인 | 용도 |
|--------|------|
| `marketplace.visualstudio.com` | 마켓플레이스 API |
| `*.gallery.vsassets.io` | 확장 다운로드 |
| `*.gallerycdn.vsassets.io` | 확장 CDN |
| `*.vscode-unpkg.net` | 웹 확장 로딩 |
| `*.vscode-cdn.net` | VS Code CDN |
| `raw.githubusercontent.com` | 일부 확장이 GitHub 접근 |

### 6-3. 확장 자체 문제

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| EX12 | 잘못된 확장 ID | `Extension 'xxx' not found` → `Failed Installing Extensions` | 오타 또는 확장 삭제됨 | 마켓플레이스에서 정확한 ID 확인 |
| EX13 | VS Code 버전 호환성 | `Extension is not compatible with the current version` | 확장이 최신 VS Code API 버전 요구 | VS Code 업데이트 또는 구버전 확장 설치: `code --install-extension <id>@<version>` |
| EX14 | 서명 검증 실패 | `Cannot verify extension signature` / `PackageIntegrityCheckFailed` | 다운로드 손상, 프록시 변조, OSS VS Code 빌드 | 재시도 또는 `"extensions.verifySignature": false` 설정 |
| EX15 | 플랫폼별 확장 미지원 | 설치 실패 또는 무반응 | 확장이 특정 플랫폼(win32-x64)만 지원, ARM64 미제공 | 유니버설 VSIX 확인 또는 퍼블리셔에 요청 |
| EX16 | 폐기(deprecated) 확장 | 설치 차단 (Install 비활성) | 마켓플레이스에서 deprecated 마킹됨 | 대체 확장 설치 |
| EX17 | 이미 설치됨 | `already installed. Use '--force' to update.` | 정상 동작이지만 최신 아닐 수 있음 | `--force` 플래그로 최신 강제 설치 |

### 6-4. 권한/정책 문제

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| EX18 | 기업 Group Policy 확장 제한 | 설치 차단 또는 자동 비활성 | `AllowedExtensions` 정책으로 화이트리스트 관리 | IT 관리자에게 확장 허용 요청 |
| EX19 | 확장 디렉토리 권한 | `EPERM: operation not permitted` | `~/.vscode/extensions/` 쓰기 권한 없음 (AV 잠금, OneDrive 동기화) | AV 예외 추가, OneDrive 동기화 제외 |
| EX20 | 바이러스 백신이 확장 파일 격리 | `EPERM` 또는 파일 누락 | AV가 확장 DLL/바이너리를 의심 파일로 격리 | `~/.vscode/extensions/` AV 예외 추가 |
| EX21 | OneDrive 동기화 충돌 | `EPERM` / 충돌 복사본 생성 | OneDrive가 확장 파일 동기화하며 잠금 | `.vscode/extensions/` OneDrive 제외 설정 |
| EX22 | AppLocker 정책 | VS Code 자체 실행 차단 | Electron 앱 차단 또는 미승인 경로 | `"disable-chromium-sandbox": true` 또는 화이트리스트 추가 |

### 6-5. 사일런트 실패 (Silent Failures) ⚠️

> **매우 중요**: 현재 코드가 `2>$null`로 에러를 숨기고 있어서 이 케이스들이 특히 위험

| # | 환경/조건 | 증상 | 원인 | 해결 방법 |
|---|----------|------|------|----------|
| EX23 | 설치 실패인데 exit code 0 반환 | 스크립트는 성공으로 처리 | VS Code CLI 버그 — 실패해도 exit code 0 반환하는 경우 있음 | exit code 대신 stdout/stderr 텍스트 파싱 ("Failed" 문자열 검사) |
| EX24 | `2>$null`이 에러 메시지 삼킴 | 어떤 에러인지 알 수 없음 | stderr로 에러 출력되는데 무시됨 | `$output = code --install-extension <id> 2>&1` 로 캡처 후 파싱 |
| EX25 | 설치됐는데 활성화 안됨 | 확장 목록에 있지만 비활성 | 리로드 필요, 잘못된 프로필에 설치, 정책 비활성, workspace trust 미허용 | VS Code 재시작, 프로필 확인 |
| EX26 | 구버전 캐시로 설치됨 | 최신이 아닌 구버전 설치 | CDN 전파 지연 또는 로컬 캐시 | `--force` 플래그 사용 |

### 6-6. `anthropic.claude-code` 확장 특이 에러

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| CC1 | Claude CLI가 VSIX 자동 설치 시 | `ENOENT. Please restart your IDE` | Claude CLI v1.0.x가 번들 VSIX 경로 해석 실패 | 수동 설치: `code --install-extension ~/.local/lib/.../claude-code.vsix` |
| CC2 | `code` 미등록 + Claude CLI 무한 재시도 | `The command "code" is either misspelled or could not be found` (무한 루프) | Claude CLI가 VS Code 확장 자동 설치 시도하며 루프 | PATH에 `code` 추가하거나 마켓플레이스에서 수동 설치 |
| CC3 | VS Code 프로필 문제 | Default 프로필에만 설치되고 활성 프로필에는 없음 | 비기본 프로필 사용 시 CLI 설치가 기본 프로필에만 적용 | 활성 프로필의 Extensions 뷰에서 수동 설치 |
| CC4 | Windows ARM64 | 확장 v2.0.46에서 멈춤, 업데이트 불가 | ARM64용 빌드 미제공 또는 배포 지연 | ARM64 지원 대기 또는 x64 에뮬레이션 사용 |
| CC5 | Windows 11 크래시 | VS Code 확장 UI 로드 실패, CLI edit 동작 시 크래시 | Windows 특정 버전 호환성 이슈 | VS Code + 확장 모두 최신 업데이트 |
| CC6 | git-bash 에러 | git-bash 관련 에러로 확장 스폰 실패 | bash 설치되어 있어도 VS Code가 git-bash 경로 잘못 인식 | VS Code 터미널 설정에서 셸 경로 확인 |

### 6-7. `highagency.pencildev` 확장 특이 에러

| # | 환경/조건 | 에러 | 원인 | 해결 방법 |
|---|----------|------|------|----------|
| PC1 | Claude Code 미인증 상태 | Pencil 확장 기능 제한 | Pencil이 Claude Code 인증 의존 | Claude Code 먼저 로그인 |
| PC2 | Cursor IDE에서 설치 | VS Code 마켓플레이스 접근 제한 가능 | Cursor는 Open VSX 사용, MS 마켓플레이스 ToS 제한 | Open VSX에서 설치 (등록되어 있음) |

### 현재 코드의 대응 수준

```
현재:
  - `code --install-extension anthropic.claude-code 2>$null`
  - 에러 완전 무시, 성공 메시지만 출력
  - `code` 명령 존재 여부만 사전 체크 (Test-CommandExists "code")

심각한 문제:
  1. 2>$null이 모든 에러를 숨김 → 사용자가 실패를 알 수 없음
  2. exit code 0 반환 버그와 결합되면 완전한 사일런트 실패
  3. code 명령은 있지만 네트워크/정책 문제로 실패하는 경우 미대응
  4. 이미 설치된 경우 최신인지 확인 안함

개선 필요:
  - 출력 캡처 후 "Failed" 문자열 검사
  - 실패 시 구체적 원인 안내
  - --force 사용으로 항상 최신 보장
  - 기업 환경 감지 시 마켓플레이스 접근 가능 여부 사전 체크
  - Cursor/Insiders 사용자 대응
```

---

## 7. WSL (Step 5)

> 현재 코드: Docker 필요 시만 → `wsl --install --no-distribution`

### 에러 케이스

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| L1 | 관리자 권한 없음 | `wsl --install` 실패 | WSL 설치에 관리자 권한 필수 | 스크립트를 관리자로 실행 |
| L2 | 가상화 비활성 (BIOS) | `Please enable Virtual Machine Platform` | Intel VT-x / AMD-V 꺼져있음 | BIOS에서 가상화 활성화 |
| L3 | Hyper-V 비활성 | WSL2 실행 불가 | Windows Home은 Hyper-V 없음 (WSL2는 별도) | `Virtual Machine Platform` 기능 활성화 |
| L4 | Windows 10 1903 이전 | `wsl --install` 명령 미지원 | WSL2는 1903+ 필요, `--install`은 2004+ | Windows 업데이트 필요 |
| L5 | Windows 10 Home (구버전) | WSL1만 지원 | WSL2 기능 미포함 | Windows 업데이트 또는 WSL1 사용 |
| L6 | 기업 Hyper-V 비활성 GPO | 가상화 기능 차단 | Group Policy로 Hyper-V 관련 기능 차단 | IT 관리자에게 요청 |
| L7 | 재부팅 미수행 | WSL 사용 불가 | 설치 후 재부팅 필수 | 재부팅 안내 (이미 구현) |
| L8 | 기존 WSL1 → WSL2 전환 | 전환 실패 | 커널 업데이트 필요 | `wsl --update` 실행 (이미 구현) |
| L9 | VPN 소프트웨어 충돌 | WSL 네트워크 오류 | Cisco AnyConnect, GlobalProtect 등 | VPN 클라이언트 업데이트 또는 WSL 네트워크 설정 변경 |
| L10 | 안티바이러스 차단 | WSL 프로세스 차단 | Symantec, McAfee 등이 WSL 프로세스 차단 | AV 예외 추가 |
| L11 | ARM64 기기 | 호환성 문제 | Surface Pro X 등 ARM 기기 | WSL2는 ARM64 지원, 일부 배포판 미지원 |
| L12 | Windows Sandbox/하이퍼바이저 충돌 | 가상화 리소스 충돌 | VMware/VirtualBox 구버전과 충돌 | VMware 15.5.5+, VirtualBox 6+ 사용 |

### 현재 코드의 대응 수준

```
현재: wsl --version 확인 → 설치/업데이트 → 재부팅 안내
개선 필요:
  - 가상화 활성화 여부 사전 검사 (필수)
  - 관리자 권한 확인
  - VPN/AV 충돌 안내 메시지
  - Windows 버전 사전 검사
```

---

## 8. Docker Desktop (Step 6)

> 현재 코드: Docker 필요 시만 → `winget install Docker.DockerDesktop`

### 에러 케이스

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| D1 | BIOS 가상화 미활성 | `Hardware assisted virtualization and data execution protection must be enabled` | VT-x/AMD-V 비활성 | BIOS에서 활성화 |
| D2 | WSL2 미설치/미작동 | `WSL 2 installation is incomplete` | Docker WSL2 backend 사용 시 WSL2 필수 | WSL2 먼저 설치 (Step 5 의존) |
| D3 | Hyper-V 충돌 | Docker + VMware/VirtualBox 동시 사용 불가 | Hyper-V와 타 가상화 충돌 | Docker WSL2 backend 사용 권장 |
| D4 | Windows Home (구버전) | Hyper-V backend 사용 불가 | Home에는 Hyper-V 없음 | WSL2 backend 사용 (기본값) |
| D5 | 라이선스 (기업 250인+) | Docker Desktop 유료 | 250인 이상 기업은 유료 구독 필요 | Docker Desktop 라이선스 확인 또는 대안 사용 |
| D6 | 관리자 권한 없음 | 설치 실패 | Docker Desktop 설치에 관리자 권한 필요 | 관리자로 실행 |
| D7 | 재부팅 미수행 | Docker 실행 불가 | 첫 설치 후 재부팅 필요 | 재부팅 안내 (이미 구현) |
| D8 | Docker daemon 미시작 | `Cannot connect to the Docker daemon` | Docker Desktop 미실행 상태 | Docker Desktop 시작 후 대기 |
| D9 | 네트워크 모드 충돌 | `docker network` 오류 | VPN/방화벽이 Docker 네트워크 차단 | Docker 네트워크 설정 변경 |
| D10 | 디스크 공간 부족 | 설치 실패 | Docker Desktop 설치에 ~2GB, 이미지에 추가 공간 필요 | 공간 확보 |
| D11 | 기존 Docker 충돌 | `docker already installed` | Docker Toolbox 또는 다른 Docker 버전 존재 | 기존 버전 제거 후 재설치 |
| D12 | 방화벽에서 Docker Hub 차단 | `docker pull` 실패 | 기업 방화벽이 Docker Hub 차단 | 미러 레지스트리 설정 또는 방화벽 예외 |
| D13 | 그룹 정책 차단 | 서비스 설치 불가 | GPO로 서비스 설치 차단 | IT 관리자에게 요청 |

### 현재 코드의 대응 수준

```
현재: docker 명령 확인 → 없으면 winget 설치 → 재부팅 안내
개선 필요:
  - BIOS 가상화 사전 검사 (WSL과 공통)
  - Docker Desktop 라이선스 경고 (기업 환경)
  - 기존 Docker Toolbox 감지
  - Docker daemon 시작 대기 로직
```

---

## 9. Claude Code CLI / Gemini CLI (Step 7)

### 9-1. Claude Code CLI

> 현재 코드: `irm https://claude.ai/install.ps1 | iex` → PATH 수동 추가

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| C1 | PowerShell 실행 정책 | `scripts is disabled on this system` | `Restricted` 실행 정책 | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| C2 | 인터넷 차단 | `irm` 다운로드 실패 | 방화벽/프록시가 `claude.ai` 차단 | 프록시 설정 또는 오프라인 설치 |
| C3 | SSL 검사 (기업) | `certificate error` | MITM 프록시가 SSL 가로채기 | 기업 인증서 추가 |
| C4 | PATH 미등록 | `claude not found` | `~/.local/bin`이 PATH에 없음 | 수동 PATH 추가 (이미 구현) |
| C5 | 이전 버전 충돌 | 설치 실패 또는 버전 혼동 | npm 글로벌 설치 Claude CLI와 충돌 | 기존 npm 글로벌 버전 제거 |
| C6 | `~/.local/bin` 권한 문제 | 파일 쓰기 실패 | OneDrive 동기화 폴더 내에 있을 때 | OneDrive 동기화 제외 또는 설치 경로 변경 |
| C7 | Node.js 미설치 상태 | npm 관련 에러 (설치 스크립트 내부) | Claude CLI 설치 스크립트가 내부적으로 npm 사용 가능 | Node.js 먼저 설치 (Step 2 의존) |
| C8 | 프록시 인증 필요 | 407 Proxy Authentication Required | 기업 프록시가 인증 요구 | 프록시 인증 설정 |

### 9-2. Gemini CLI

> 현재 코드: `npm install -g @google/gemini-cli`

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| GM1 | npm 권한 문제 | `EACCES` / `permission denied` | 글로벌 설치 시 권한 부족 | `npm config set prefix` 사용자 디렉토리 설정 |
| GM2 | Node.js 미설치 | `npm not found` | Step 2 실패 시 | Node.js 먼저 설치 |
| GM3 | npm 레지스트리 차단 | `ETIMEDOUT` / `ECONNREFUSED` | 기업 방화벽이 `registry.npmjs.org` 차단 | npm 프록시 설정 또는 사내 레지스트리 |
| GM4 | 기존 설치 충돌 | 버전 문제 | 이전 글로벌 설치 존재 | `npm update -g @google/gemini-cli` |
| GM5 | Node.js 버전 호환성 | 설치 실패 | 너무 낮은 Node.js 버전 | Node.js LTS 업데이트 |

### 현재 코드의 대응 수준

```
현재:
  - Claude: irm 설치 → PATH 수동 추가 → 확인
  - Gemini: npm -g 설치 → PATH 갱신 → 확인
개선 필요:
  - 실행 정책 사전 검사
  - 기존 npm 글로벌 Claude CLI 감지
  - 프록시 환경 감지 및 안내
  - Node.js 의존성 확인 (Step 2 결과 참조)
```

---

## 10. bkit Plugin (Step 8)

> 현재 코드: `claude plugin marketplace add` → `claude plugin install` → 확인

### 에러 케이스

| # | 환경/조건 | 에러 메시지 | 원인 | 해결 방법 |
|---|----------|-----------|------|----------|
| B1 | Claude CLI 미설치 | `claude not found` | Step 7 실패 시 | Claude CLI 먼저 설치 |
| B2 | Claude CLI 미로그인 | 인증 오류 | 플러그인 설치에 로그인 필요할 수 있음 | `claude login` 먼저 실행 |
| B3 | 네트워크 차단 | 마켓플레이스 접근 불가 | 방화벽이 GitHub/마켓플레이스 차단 | 네트워크 예외 추가 |
| B4 | 플러그인 API 변경 | 명령어 구문 변경 | Claude CLI 업데이트로 플러그인 명령어 변경 | CLI 문서 확인 후 명령어 갱신 |
| B5 | Gemini 확장 설치 실패 | `extensions install` 실패 | Gemini CLI 확장 시스템 미성숙 | Gemini CLI 업데이트 후 재시도 |

### 현재 코드의 대응 수준

```
현재: 에러 무시 (SilentlyContinue) → 설치 확인 → "verify" 안내
개선 필요:
  - Claude CLI 존재 여부 사전 확인
  - 설치 실패 시 구체적 안내 (로그인 필요 등)
```

---

## 11. 공통 에러 (Cross-cutting)

모든 설치 단계에 영향을 미치는 공통 문제들:

### 11-1. PowerShell 관련

| # | 문제 | 영향 | 해결 |
|---|------|------|------|
| PS1 | 실행 정책 `Restricted` | 스크립트 자체 실행 불가 | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| PS2 | PowerShell 5.1 (구버전) | 일부 cmdlet 동작 차이 | PowerShell 7+ 사용 권장 |
| PS3 | Constrained Language Mode | `Add-Member` 등 제한 | 기업 AppLocker 정책 해제 필요 |
| PS4 | `$ErrorActionPreference` | 예상치 못한 에러 전파 | 각 섹션별 에러 처리 격리 |

### 11-2. 네트워크 관련

| # | 문제 | 영향 | 해결 |
|---|------|------|------|
| NET1 | 기업 프록시 | 모든 다운로드 실패 | 시스템 프록시 자동 감지 또는 수동 설정 |
| NET2 | SSL/TLS MITM 검사 | 인증서 오류 | 기업 루트 인증서 설치 |
| NET3 | 방화벽 포트 차단 | HTTPS(443) 차단 | 방화벽 예외 추가 |
| NET4 | DNS 차단 | 특정 도메인 접근 불가 | DNS 설정 변경 또는 호스트 파일 |
| NET5 | 오프라인 환경 | 모든 온라인 설치 불가 | 오프라인 설치 패키지 사전 준비 |

### 11-3. 권한 관련

| # | 문제 | 영향 | 해결 |
|---|------|------|------|
| AUTH1 | 비관리자 계정 | WSL, Docker 설치 불가 | 관리자로 실행 안내 |
| AUTH2 | UAC 프롬프트 차단 | 자동 설치 중단 | UAC 승인 필요 안내 |
| AUTH3 | Group Policy 제한 | 소프트웨어 설치 차단 | IT 관리자 승인 필요 |
| AUTH4 | AppLocker 정책 | 실행 차단 | 화이트리스트 추가 요청 |

### 11-4. PATH 관련

| # | 문제 | 영향 | 해결 |
|---|------|------|------|
| PATH1 | Refresh-Path 후에도 미반영 | 명령어 not found | 터미널 재시작 안내 |
| PATH2 | PATH 길이 초과 (Windows 제한) | 새 항목 추가 불가 | 불필요한 PATH 항목 정리 |
| PATH3 | User PATH vs System PATH 충돌 | 잘못된 버전 실행 | PATH 순서 확인 및 조정 |

---

## 12. Top 10 빈출 에러

실제 여러 컴퓨터에서 테스트 시 가장 자주 만나는 에러 순위:

| 순위 | 에러 | 빈도 | 영향 범위 | 현재 대응 |
|------|------|------|----------|----------|
| **1** | PATH 미반영 (`Refresh-Path` 부족) | ★★★★★ | Node, Git, `code` 명령, Claude CLI, Gemini | 부분 대응 (Refresh-Path) |
| **2** | 기업 프록시/방화벽 차단 | ★★★★☆ | 모든 다운로드 단계 + 확장 마켓플레이스 | **미대응** |
| **3** | SSL MITM 검사 (기업 보안) | ★★★★☆ | winget, npm, irm, git, VS Code 확장 | **미대응** |
| **4** | 비관리자 권한 | ★★★★☆ | WSL, Docker, 일부 winget | **미대응** |
| **5** | VS Code 확장 사일런트 실패 | ★★★★☆ | Claude 확장, Pencil 확장 | **미대응** (`2>$null`로 에러 숨김) |
| **6** | 기존 설치와 충돌 | ★★★☆☆ | Node(nvm), Git, Docker | **미대응** |
| **7** | BIOS 가상화 미활성 | ★★★☆☆ | WSL, Docker | **미대응** |
| **8** | 재부팅 필요 (WSL/Docker) | ★★★☆☆ | WSL, Docker | 대응 (안내) |
| **9** | 바이러스 백신 차단 | ★★☆☆☆ | 설치 파일, WSL 프로세스, 확장 파일 | **미대응** |
| **10** | Windows S Mode / LTSC | ★★☆☆☆ | winget 자체 사용 불가 | 부분 대응 (Store 링크) |

---

## 13. 환경별 위험도 매트릭스

각 환경 유형별로 어떤 에러가 발생할 확률이 높은지:

| 환경 | winget | Node.js | Git | VS Code | Antigravity | **확장** | WSL | Docker | Claude CLI | bkit |
|------|--------|---------|-----|---------|-------------|---------|-----|--------|-----------|------|
| **일반 가정 PC** | ✅ | ✅ | ✅ | ✅ | ⚠️ 계정/지역 | ✅ | ⚠️ BIOS | ⚠️ BIOS | ✅ | ✅ |
| **기업 (AD)** | ⚠️ GPO | ⚠️ 프록시 | ⚠️ SSL | ⚠️ 정책 | ❌ Workspace 차단 | ❌ 정책+SSL | ❌ GPO | ❌ 라이선스+GPO | ⚠️ 프록시 | ⚠️ 네트워크 |
| **교육기관** | ⚠️ 제한 | ⚠️ 권한 | ⚠️ 권한 | ✅ | ⚠️ 18세 제한 | ⚠️ 네트워크 | ❌ 권한 | ❌ 권한 | ⚠️ 권한 | ⚠️ |
| **Windows 10 (구)** | ⚠️ 버전 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ 버전 | ⚠️ | ✅ | ✅ |
| **LTSC/Server** | ❌ 미포함 | ❌ | ❌ | ❌ | ❌ | ❌ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| **S Mode** | ❌ 차단 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **ARM64 기기** | ✅ | ✅ | ✅ | ✅ | ✅ (지원) | ⚠️ 빌드 미제공 | ✅ | ⚠️ | ✅ | ✅ |

> ✅ = 정상 작동 예상 | ⚠️ = 문제 발생 가능 | ❌ = 높은 확률로 실패

---

## 부록: 필요한 네트워크 접근 목록

스크립트가 정상 동작하려면 아래 도메인에 HTTPS(443) 접근이 가능해야 함:

| 도메인 | 용도 | 단계 |
|--------|------|------|
| `cdn.winget.microsoft.com` | winget 패키지 소스 | 전체 |
| `winget.azureedge.net` | winget CDN | 전체 |
| `nodejs.org` / CDN | Node.js 다운로드 | Step 2 |
| `github.com` | Git, gh CLI, bkit | Step 3, 8 |
| `objects.githubusercontent.com` | GitHub releases | 다수 |
| `update.code.visualstudio.com` | VS Code 다운로드 | Step 4 |
| `marketplace.visualstudio.com` | VS Code 확장 | Step 4 |
| `desktop.docker.com` | Docker Desktop | Step 6 |
| `registry.npmjs.org` | npm 패키지 | Step 7 (Gemini) |
| `claude.ai` | Claude CLI 설치 스크립트 | Step 7 |

---

## 14. 구현 계획

### 14-1. 파일 구조

```
installer/modules/
├── shared/
│   ├── preflight.ps1     ← 신규: 환경 사전 검사 (설치 전 진단)
│   ├── preflight.sh      ← 신규: Mac/Linux용 환경 사전 검사
│   └── oauth-helper.ps1  (기존)
├── base/
│   ├── install.ps1       ← 수정: 에러 핸들링 강화
│   ├── install.sh        ← 수정: 에러 핸들링 강화
│   └── module.json       (변경 없음)
```

### 14-2. preflight.ps1 — 환경 사전 검사 (14개 검사)

> 목적: 설치 시작 전에 환경을 진단하고, 문제가 있으면 미리 경고/중단
> 호출: `install.ps1`에서 base 모듈 실행 전에 `. .\modules\shared\preflight.ps1` 로 호출
> 반환: `$preflight` 객체에 각 검사 결과 저장 → base/install.ps1에서 참조

#### 검사 1: Windows 버전/에디션

```powershell
# 감지 방법:
$osInfo = Get-CimInstance Win32_OperatingSystem
$buildNumber = [int]$osInfo.BuildNumber
$productType = $osInfo.ProductType  # 1=워크스테이션, 2=DC, 3=서버
$edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID

# S Mode 감지:
$ciPolicy = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -ErrorAction SilentlyContinue
$isSMode = $ciPolicy -and $ciPolicy.SkuPolicyRequired -eq 1

# LTSC 감지:
$isLTSC = $edition -like "*LTSC*" -or $edition -like "*Server*"

# 결과:
# - S Mode → ❌ 중단: "Windows S Mode에서는 설치 불가. S Mode 해제 후 재시도하세요"
# - LTSC/Server → ⚠️ 경고: "LTSC/Server에서는 winget이 기본 미포함. 수동 설치 필요할 수 있습니다"
# - Build < 17763 (1809 미만) → ❌ 중단: "Windows 10 1809 이상 필요"
```

#### 검사 2: 관리자 권한

```powershell
# 감지 방법:
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

# 결과:
# - 비관리자 + Docker 필요 → ⚠️ 경고: "WSL/Docker 설치에 관리자 권한 필요. 관리자로 다시 실행 권장"
# - 비관리자 + Docker 불필요 → ℹ️ 안내: "관리자 아님. 일부 프로그램은 --scope user로 설치됩니다"
```

#### 검사 3: PowerShell 실행 정책

```powershell
# 감지 방법:
$policy = Get-ExecutionPolicy -Scope CurrentUser

# 결과:
# - Restricted → 자동 수정 시도: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
# - 자동 수정 실패 → ⚠️ 경고: "실행 정책 변경 필요. 관리자 PowerShell에서 실행하세요"
# - Constrained Language Mode 감지:
$isConstrained = $ExecutionContext.SessionState.LanguageMode -eq "ConstrainedLanguage"
# → ❌ 중단: "Constrained Language Mode에서는 스크립트 실행 불가. IT 관리자에게 문의"
```

#### 검사 4: 인터넷 연결 (오프라인 감지)

```powershell
# 감지 방법:
$testUrls = @(
    "cdn.winget.microsoft.com",      # winget
    "marketplace.visualstudio.com",  # VS Code 확장
    "claude.ai"                       # Claude CLI
)
$online = $false
foreach ($url in $testUrls) {
    $result = Test-NetConnection -ComputerName $url -Port 443 -WarningAction SilentlyContinue
    if ($result.TcpTestSucceeded) { $online = $true; break }
}

# 결과:
# - 전부 실패 → ❌ 중단: "인터넷 연결 없음. 온라인 환경에서 실행하세요"
# - 일부만 실패 → ⚠️ 경고: "일부 서버 접근 불가. 방화벽 설정 확인 필요" + 실패 도메인 목록 표시
```

#### 검사 5: 프록시/방화벽 감지

```powershell
# 감지 방법:
# 1. 시스템 프록시 설정 확인
$proxySettings = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$hasProxy = $proxySettings.ProxyEnable -eq 1
$proxyServer = $proxySettings.ProxyServer

# 2. 환경변수 프록시 확인
$envProxy = $env:HTTP_PROXY -or $env:HTTPS_PROXY

# 결과:
# - 프록시 감지됨 → ⚠️ 경고: "프록시 감지됨 ($proxyServer). 설치 중 다운로드 실패 시 프록시 설정 확인"
# - winget 프록시 설정 안내: "winget settings에서 프록시 설정 필요할 수 있음"
# - npm 프록시 설정 안내: "npm config set proxy http://... 필요할 수 있음"
```

#### 검사 6: SSL MITM 감지

```powershell
# 감지 방법:
# known 도메인의 인증서 발급자를 확인해서 기업 MITM 프록시 감지
try {
    $request = [System.Net.HttpWebRequest]::Create("https://claude.ai")
    $request.Timeout = 5000
    $response = $request.GetResponse()
    $cert = $request.ServicePoint.Certificate
    $issuer = $cert.Issuer
    $response.Close()

    # 잘 알려진 CA가 아니면 MITM 가능성
    $knownCAs = @("DigiCert", "Let's Encrypt", "Cloudflare", "Amazon", "Google Trust")
    $isMITM = -not ($knownCAs | Where-Object { $issuer -like "*$_*" })
} catch {
    $isMITM = $false  # 연결 자체가 안되면 검사 4에서 처리
}

# 결과:
# - MITM 감지됨 → ⚠️ 경고:
#   "기업 SSL 검사 감지됨 (발급자: $issuer)"
#   "설치 중 인증서 오류 발생 시:"
#   "  - git: git config --global http.sslVerify false (임시)"
#   "  - npm: npm config set strict-ssl false (임시)"
#   "  - VS Code: NODE_EXTRA_CA_CERTS 환경변수 설정"
#   "  또는 IT 관리자에게 기업 인증서 설치 요청"
```

#### 검사 7: BIOS 가상화 활성 여부

```powershell
# 감지 방법:
# WSL/Docker 필요할 때만 검사
if ($script:needsDocker) {
    $vmEnabled = $false

    # 방법 1: Hyper-V 가상화 확인
    $computerInfo = Get-CimInstance Win32_ComputerSystem
    $vmEnabled = $computerInfo.HypervisorPresent

    # 방법 2: 프로세서 기능 확인 (fallback)
    if (-not $vmEnabled) {
        $proc = Get-CimInstance Win32_Processor
        $vmEnabled = $proc.VirtualizationFirmwareEnabled
    }
}

# 결과:
# - 비활성 → ⚠️ 경고:
#   "BIOS에서 가상화(VT-x/AMD-V)가 비활성화되어 있습니다"
#   "WSL과 Docker Desktop에 필요합니다"
#   "BIOS 설정에 들어가서 활성화하세요:"
#   "  Intel: VT-x 또는 Intel Virtualization Technology"
#   "  AMD: AMD-V 또는 SVM Mode"
```

#### 검사 8: 디스크 공간

```powershell
# 감지 방법:
$drive = (Get-Item $env:SystemDrive)
$freeGB = [math]::Round((Get-PSDrive C).Free / 1GB, 1)

# 필요 공간 추정:
# Node.js ~100MB, Git ~300MB, VS Code ~500MB, Docker ~2GB, 기타 ~500MB
$requiredGB = 1.5
if ($script:needsDocker) { $requiredGB = 4.0 }

# 결과:
# - 부족 → ⚠️ 경고: "C: 드라이브 여유 공간 ${freeGB}GB. 최소 ${requiredGB}GB 권장. 공간 확보 후 진행하세요"
```

#### 검사 9: OneDrive 동기화 경로 충돌

```powershell
# 감지 방법:
$userProfile = $env:USERPROFILE
$oneDrivePath = $env:OneDrive -or $env:OneDriveConsumer -or $env:OneDriveCommercial
$vscodeExtDir = "$userProfile\.vscode\extensions"

$isOneDriveSynced = $false
if ($oneDrivePath -and $userProfile -like "*OneDrive*") {
    $isOneDriveSynced = $true
}
# 또는 .vscode가 OneDrive 경로 내에 있는지 확인
if ($oneDrivePath -and (Test-Path $vscodeExtDir)) {
    $resolvedPath = (Resolve-Path $vscodeExtDir).Path
    if ($resolvedPath -like "*OneDrive*") { $isOneDriveSynced = $true }
}

# 결과:
# - 감지됨 → ⚠️ 경고:
#   "VS Code 확장 폴더가 OneDrive 동기화 경로 내에 있습니다"
#   "확장 설치 시 EPERM 오류가 발생할 수 있습니다"
#   "OneDrive 설정에서 .vscode 폴더를 동기화 제외하세요"
```

#### 검사 10: 기존 설치 충돌 감지

```powershell
# nvm 감지:
$hasNvm = Test-Path "$env:APPDATA\nvm\nvm.exe" -or (Test-CommandExists "nvm")

# Docker Toolbox 감지:
$hasDockerToolbox = Test-Path "$env:ProgramFiles\Docker Toolbox\docker.exe"

# 기존 npm 글로벌 Claude CLI 감지:
$hasNpmClaude = $false
if (Test-CommandExists "npm") {
    $npmGlobal = npm list -g @anthropic-ai/claude-code 2>$null
    if ($npmGlobal -and $npmGlobal -notlike "*empty*") { $hasNpmClaude = $true }
}

# VS Code Insiders 감지 (code-insiders만 있고 code 없을 때):
$hasInsiders = Test-CommandExists "code-insiders"
$hasCode = Test-CommandExists "code"

# 결과:
# - nvm 있음 → ℹ️ 안내: "nvm 감지됨. Node.js winget 설치를 스킵합니다 (nvm으로 관리)"
# - Docker Toolbox → ⚠️ 경고: "Docker Toolbox 감지됨. Docker Desktop과 충돌할 수 있습니다. 먼저 제거 권장"
# - npm Claude CLI → ⚠️ 경고: "npm 글로벌 Claude CLI 감지됨. 네이티브 설치와 충돌 가능. npm uninstall -g ... 권장"
# - Insiders만 → ℹ️ 안내: "VS Code Insiders 감지됨. 확장은 code-insiders로 설치합니다"
```

#### 검사 11: AV 소프트웨어 감지

```powershell
# 감지 방법:
$avProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntivirusProduct -ErrorAction SilentlyContinue
$avNames = $avProducts | Select-Object -ExpandProperty displayName

# 특히 문제 유발하는 AV 목록:
$problematicAVs = @("Norton", "Kaspersky", "McAfee", "Symantec", "Bitdefender", "Avast", "AVG")
$detectedProblematic = $avNames | Where-Object { $name = $_; $problematicAVs | Where-Object { $name -like "*$_*" } }

# 결과:
# - 감지됨 → ⚠️ 경고:
#   "바이러스 백신 감지: $($avNames -join ', ')"
#   "설치 중 파일 격리/차단 발생 시:"
#   "  - 일시적으로 실시간 보호 비활성화"
#   "  - 또는 설치 경로를 AV 예외에 추가:"
#   "    %LOCALAPPDATA%\Programs\"
#   "    %USERPROFILE%\.vscode\extensions\"
#   "    %USERPROFILE%\.local\bin\"
```

#### 검사 12: Group Policy / AppLocker 제한 감지

```powershell
# 감지 방법:
# 1. 소프트웨어 설치 제한 정책 확인
$gpRestriction = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer" -ErrorAction SilentlyContinue
$installRestricted = $gpRestriction -and $gpRestriction.DisableMSI

# 2. AppLocker 정책 확인
$appLockerPolicy = Get-AppLockerPolicy -Effective -ErrorAction SilentlyContinue
$hasAppLocker = $null -ne $appLockerPolicy -and ($appLockerPolicy.RuleCollections.Count -gt 0)

# 3. VS Code 확장 정책 확인
$vscodePolicies = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Visual Studio Code" -ErrorAction SilentlyContinue
$extensionRestricted = $vscodePolicies -and $vscodePolicies.AllowedExtensions

# 결과:
# - 설치 제한 → ⚠️ 경고: "Group Policy로 소프트웨어 설치가 제한되어 있습니다. IT 관리자에게 문의하세요"
# - AppLocker → ⚠️ 경고: "AppLocker 정책 감지됨. 일부 프로그램 실행이 차단될 수 있습니다"
# - 확장 제한 → ⚠️ 경고: "VS Code 확장 설치 정책 감지됨. IT 관리자에게 Claude/Pencil 확장 허용 요청 필요"
```

#### 검사 13: Docker 라이선스 경고

```powershell
# 감지 방법 (기업 규모 추정):
# - 도메인 조인 여부로 기업 환경 판단
$isDomainJoined = (Get-CimInstance Win32_ComputerSystem).PartOfDomain

# 결과:
# - Docker 필요 + 도메인 조인됨 → ⚠️ 경고:
#   "기업 환경 감지됨 (도메인: $((Get-CimInstance Win32_ComputerSystem).Domain))"
#   "Docker Desktop은 250명 이상 기업에서 유료 구독 필요 (Docker Business)"
#   "라이선스 확인: https://www.docker.com/pricing/"
```

#### 검사 14: Google 계정/지역 제한 안내 (Antigravity)

```powershell
# Gemini(Antigravity) 선택 시에만 표시
if ($env:CLI_TYPE -eq "gemini") {
    # 감지 방법: 시스템 로케일/지역으로 추정
    $region = (Get-WinSystemLocale).Name  # 예: "ko-KR", "zh-CN"
    $restrictedRegions = @("zh-CN", "ru-RU", "fa-IR", "cu-*", "kp-*", "sy-*")
    $isRestricted = $restrictedRegions | Where-Object { $region -like $_ }

    # 결과: (항상 안내 표시)
    # ℹ️ 안내:
    #   "Antigravity 사용 시 Google 계정 필요:"
    #   "  - 개인 @gmail.com 계정 권장 (Workspace 계정은 차단될 수 있음)"
    #   "  - 18세 이상 계정만 가능"
    #   "  - 일부 국가에서 접근 제한 (중국, 러시아, 이란 등)"
    # + 제한 지역 감지 시 추가 경고
}
```

#### preflight 실행 흐름 요약

```
preflight.ps1 실행
│
├─ [FATAL] S Mode / Build 미달 / 오프라인 / Constrained Language
│   └─ 즉시 중단 + 명확한 에러 메시지
│
├─ [WARNING] 경고 수집 (중단하지 않음)
│   ├─ 관리자 아님
│   ├─ 프록시 감지
│   ├─ SSL MITM 감지
│   ├─ 가상화 미활성
│   ├─ 디스크 부족
│   ├─ OneDrive 충돌
│   ├─ 기존 설치 충돌
│   ├─ AV 감지
│   ├─ GPO/AppLocker
│   ├─ Docker 라이선스
│   └─ Google 계정 제한
│
├─ 경고 요약 출력
│   "⚠️ N개 경고 감지됨:"
│   "  1. 프록시 감지됨 (proxy.company.com:8080)"
│   "  2. 바이러스 백신: Norton 감지됨"
│   "  ..."
│
└─ 사용자 확인 (경고 있을 때)
    "경고가 있지만 계속 진행하시겠습니까? (Y/N)"
    └─ Y → $preflight 객체 반환 (base/install.ps1에서 참조)
    └─ N → 중단
```

#### $preflight 객체 구조

```powershell
$preflight = @{
    isAdmin          = $true/$false
    isSMode          = $true/$false
    isLTSC           = $true/$false
    isOnline         = $true/$false
    hasProxy         = $true/$false
    proxyServer      = "proxy:8080"
    isMITM           = $true/$false
    isVirtualization = $true/$false
    freeSpaceGB      = 15.2
    isOneDriveSynced = $true/$false
    hasNvm           = $true/$false
    hasDockerToolbox = $true/$false
    hasNpmClaude     = $true/$false
    hasCodeInsiders  = $true/$false
    hasCode          = $true/$false
    hasAgy           = $true/$false
    isDomainJoined   = $true/$false
    avProducts       = @("Norton", "Windows Defender")
    hasGPRestriction = $true/$false
    hasAppLocker     = $true/$false
    warnings         = @("경고1", "경고2", ...)
    fatal            = $null  # null이면 계속 진행 가능
}
```

---

### 14-3. base/install.ps1 — 에러 핸들링 강화 (8개 수정)

> 목적: 기존 설치 로직 유지하면서, preflight 결과를 활용한 스마트한 에러 처리
> $preflight 객체를 참조하여 각 단계별 분기 처리

#### 수정 1: 🚨 Antigravity 경로 수정 (Critical Bug Fix)

```powershell
# 현재 (잘못됨):
$antigravityPaths = @(
    "$env:LOCALAPPDATA\Programs\Antigravity\Antigravity.exe",
    "$env:ProgramFiles\Antigravity\Antigravity.exe"
)

# 수정:
$antigravityPaths = @(
    "$env:ProgramFiles\Google\Antigravity\Antigravity.exe",
    "$env:LOCALAPPDATA\Programs\Google\Antigravity\Antigravity.exe",
    "$env:LOCALAPPDATA\Programs\Antigravity\Antigravity.exe"   # 레거시 호환
)
```

#### 수정 2: Antigravity `agy` CLI + OpenVSX 대응

```powershell
# 현재: Antigravity 선택 시 확장 설치 없음 (VS Code만 확장 설치)
# 수정: Antigravity에서도 Gemini Companion 확장 설치 + agy CLI 활용

# Antigravity 선택 시 추가:
if (Test-CommandExists "agy") {
    Write-Host "  Installing Gemini CLI companion extension..." -ForegroundColor Gray
    $extOutput = agy --install-extension google.gemini-cli-companion 2>&1
    if ($extOutput -like "*Failed*") {
        Write-Host "  Extension install failed. Install manually from Antigravity marketplace." -ForegroundColor Yellow
    } else {
        Write-Host "  Gemini companion extension installed" -ForegroundColor Green
    }
}
```

#### 수정 3: PATH 강화

```powershell
# 현재:
function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

# 수정: 특정 경로 직접 추가하는 헬퍼 추가
function Ensure-InPath {
    param([string]$Dir)
    if ((Test-Path $Dir) -and ($env:PATH -notlike "*$Dir*")) {
        $env:PATH = "$Dir;$env:PATH"
    }
}

# 각 설치 후:
Refresh-Path
# Git 수동 PATH (Refresh-Path로 안잡힐 때 fallback)
Ensure-InPath "$env:ProgramFiles\Git\cmd"
# Node.js 수동 PATH
Ensure-InPath "$env:ProgramFiles\nodejs"
# Antigravity 수동 PATH
Ensure-InPath "$env:ProgramFiles\Google\Antigravity\bin"
# Claude CLI 수동 PATH
Ensure-InPath "$env:USERPROFILE\.local\bin"
```

#### 수정 4: VS Code 확장 사일런트 실패 수정

```powershell
# 현재 (에러 숨김):
code --install-extension anthropic.claude-code 2>$null
Write-Host "  Claude extension installed" -ForegroundColor Green

# 수정 (출력 캡처 + 파싱):
function Install-VSCodeExtension {
    param(
        [string]$ExtensionId,
        [string]$DisplayName,
        [string]$Command = "code"  # "code" 또는 "code-insiders" 또는 "agy"
    )

    if (-not (Test-CommandExists $Command)) {
        Write-Host "  $Command not found in PATH. Skip $DisplayName extension." -ForegroundColor Yellow
        return $false
    }

    Write-Host "  Installing $DisplayName extension..." -ForegroundColor Gray
    $output = & $Command --install-extension $ExtensionId --force 2>&1 | Out-String

    if ($output -like "*Failed*" -or $output -like "*not found*" -or $output -like "*not compatible*") {
        Write-Host "  ⚠ $DisplayName extension install failed:" -ForegroundColor Yellow
        # 원인별 안내
        if ($output -like "*not found*") {
            Write-Host "    Extension ID '$ExtensionId' not found in marketplace." -ForegroundColor Yellow
        } elseif ($output -like "*not compatible*") {
            Write-Host "    Extension requires newer $Command version. Update your IDE." -ForegroundColor Yellow
        } elseif ($output -like "*signature*") {
            Write-Host "    Signature verification failed. Corporate proxy may be modifying downloads." -ForegroundColor Yellow
        } else {
            Write-Host "    $($output.Trim())" -ForegroundColor Gray
        }
        return $false
    } else {
        Write-Host "  $DisplayName extension OK" -ForegroundColor Green
        return $true
    }
}

# 사용:
$codeCmd = if ($preflight.hasCodeInsiders -and -not $preflight.hasCode) { "code-insiders" } else { "code" }
Install-VSCodeExtension -ExtensionId "anthropic.claude-code" -DisplayName "Claude Code" -Command $codeCmd
```

#### 수정 5: 확장 `--force` 사용

```powershell
# 수정 4의 Install-VSCodeExtension에 이미 --force 포함됨
# 항상 최신 버전 설치 보장
```

#### 수정 6: 각 단계별 try-catch + 구체적 에러 안내

```powershell
# 현재: 전체 스크립트에 try-catch 없음 (상위 install.ps1에만 있음)
# 수정: 각 설치 단계별 try-catch 래핑

# 예시 - Node.js 설치:
Write-Host "[2/8] Checking Node.js..." -ForegroundColor Yellow
try {
    if ($preflight.hasNvm) {
        Write-Host "  nvm detected. Skipping winget Node.js install (managed by nvm)." -ForegroundColor Gray
        Write-Host "  OK (via nvm)" -ForegroundColor Green
    } elseif (-not (Test-CommandExists "node")) {
        Write-Host "  Installing Node.js LTS..." -ForegroundColor Gray
        $installArgs = "install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements -h"
        if (-not $preflight.isAdmin) { $installArgs += " --scope user" }
        $result = Start-Process winget -ArgumentList $installArgs -Wait -PassThru
        Refresh-Path
        Ensure-InPath "$env:ProgramFiles\nodejs"

        if (-not (Test-CommandExists "node")) {
            Write-Host "  Installed (restart terminal to use)" -ForegroundColor Yellow
        } else {
            Write-Host "  OK - $(node --version)" -ForegroundColor Green
        }
    } else {
        Write-Host "  OK - $(node --version)" -ForegroundColor Green
    }
} catch {
    Write-Host "  Node.js install failed: $_" -ForegroundColor Red
    if ($preflight.hasProxy) {
        Write-Host "  Proxy detected. Check proxy settings for winget." -ForegroundColor Yellow
    }
    Write-Host "  Manual install: https://nodejs.org/" -ForegroundColor Cyan
}
```

#### 수정 7: 기존 설치 스킵 로직 개선

```powershell
# preflight 결과 활용:
# - $preflight.hasNvm → Node.js winget 스킵
# - $preflight.hasDockerToolbox → Docker 설치 전 경고 + 제거 안내
# - $preflight.hasNpmClaude → Claude CLI 설치 전 기존 npm 버전 제거 안내
# - $preflight.hasCodeInsiders → code-insiders 명령 사용

# Docker Toolbox 감지 시:
if ($preflight.hasDockerToolbox) {
    Write-Host "  ⚠ Docker Toolbox detected. May conflict with Docker Desktop." -ForegroundColor Yellow
    Write-Host "  Recommend: Uninstall Docker Toolbox first." -ForegroundColor Yellow
    Write-Host "  Continue anyway? (Y/N)" -ForegroundColor White
    $continue = Read-Host
    if ($continue -ne "Y") { throw "Cancelled by user" }
}

# npm Claude CLI 감지 시:
if ($preflight.hasNpmClaude) {
    Write-Host "  ⚠ npm global Claude CLI detected. Removing to avoid conflict..." -ForegroundColor Yellow
    npm uninstall -g @anthropic-ai/claude-code 2>$null
}
```

#### 수정 8: winget `--scope user` fallback

```powershell
# 관리자 아닐 때 user scope로 재시도하는 헬퍼:
function Install-WithWinget {
    param(
        [string]$PackageId,
        [string]$DisplayName
    )

    $baseArgs = "install $PackageId --accept-source-agreements --accept-package-agreements -h"

    # 첫 시도
    winget $baseArgs.Split(' ')
    Refresh-Path

    # 실패 + 비관리자면 --scope user로 재시도
    if ($LASTEXITCODE -ne 0 -and -not $preflight.isAdmin) {
        Write-Host "  Retrying with --scope user..." -ForegroundColor Gray
        winget ($baseArgs + " --scope user").Split(' ')
        Refresh-Path
    }
}
```

---

### 14-4. base/install.sh — Mac/Linux 동일 적용

> PS1과 동일한 로직을 bash로 구현
> preflight.sh + install.sh 에러 핸들링 강화

주요 차이점:

| 항목 | PowerShell | Bash |
|------|-----------|------|
| 관리자 검사 | `WindowsPrincipal` | `[ "$EUID" -eq 0 ]` |
| 프록시 검사 | 레지스트리 | `$HTTP_PROXY`, `$HTTPS_PROXY` 환경변수 |
| AV 검사 | `SecurityCenter2` WMI | 해당 없음 (Mac: `xprotect` 정도) |
| GPO 검사 | 레지스트리 | 해당 없음 |
| 디스크 검사 | `Get-PSDrive` | `df -h /` |
| S Mode/LTSC | 레지스트리 | 해당 없음 (macOS/Linux는 해당 없음) |
| OneDrive | 경로 확인 | 해당 없음 (Mac: iCloud Drive 유사 문제 가능) |
| 가상화 | `Win32_ComputerSystem` | Mac: `sysctl kern.hv_support`, Linux: `/proc/cpuinfo` |

---

### 14-5. 구현 우선순위

| 우선순위 | 항목 | 난이도 | 영향도 |
|---------|------|--------|--------|
| **P0** | Antigravity 경로 버그 수정 | 쉬움 | 높음 — 현재 버그 |
| **P0** | VS Code 확장 사일런트 실패 수정 | 보통 | 높음 — 에러 숨김 |
| **P1** | preflight 환경 검사 전체 | 보통 | 높음 — 사전 진단 |
| **P1** | PATH 강화 (Ensure-InPath) | 쉬움 | 높음 — 최빈출 에러 |
| **P1** | 각 단계 try-catch 에러 핸들링 | 보통 | 높음 — 에러 안내 개선 |
| **P2** | 기존 설치 충돌 스킵 로직 | 보통 | 중간 |
| **P2** | winget --scope user fallback | 쉬움 | 중간 |
| **P2** | Antigravity agy CLI 대응 | 보통 | 중간 |
| **P3** | install.sh 동일 적용 | 보통 | 낮음 (Windows 중심) |

### 14-6. 예상 작업 분량

| 파일 | 현재 줄수 | 예상 줄수 | 비고 |
|------|----------|----------|------|
| `shared/preflight.ps1` | 0 (신규) | ~250줄 | 14개 검사 + 요약 출력 |
| `shared/preflight.sh` | 0 (신규) | ~150줄 | Windows 전용 검사 제외 |
| `base/install.ps1` | 245줄 | ~350줄 | 에러 핸들링 + 헬퍼 함수 추가 |
| `base/install.sh` | ~270줄 | ~330줄 | 동일 패턴 적용 |
