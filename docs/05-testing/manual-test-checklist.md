# Manual Test Checklist — ADW Improvement

> **Version**: 1.1
> **Date**: 2026-02-20
> **Target**: installer (macOS / Windows / Linux)
> **Automated Tests**: 226 unit tests (97.46% coverage) — 이 문서는 자동화 불가한 수동 테스트만 다룸
> **Note**: Google Workspace MCP 관련 테스트는 자동 테스트로 커버됨 (수동 테스트 제외)

---

## How to Use

- [ ] 각 시나리오를 순서대로 실행
- [ ] Pass/Fail 체크 후 비고란에 이슈 기록
- [ ] 실패 시 GitHub Issue 생성

**범례**: P0 = 반드시 통과, P1 = 중요, P2 = 권장

---

## 1. Installer — macOS

### TC-INS-MAC-01: 클린 설치 (P0)

**사전 조건**: macOS 12+, 인터넷 연결, 터미널

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 1 | `curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.sh \| bash` | 스크립트 다운로드 및 실행 시작 | |
| 2 | 시스템 요구사항 체크 출력 확인 | RAM >= 8GB, CPU >= 4, Disk >= 40GB 표시 | |
| 3 | 모듈 목록 표시 확인 | 7개 모듈 (base + 6 optional) 목록 표시 | |
| 4 | base 모듈만 선택하여 설치 | Node.js, Git, VS Code, Docker, Claude CLI, bkit 설치 완료 | |
| 5 | `node --version` | v18+ 출력 | |
| 6 | `git --version` | 버전 출력 | |
| 7 | `docker --version` | 버전 출력 | |
| 8 | `claude --version` | Claude CLI 버전 출력 | |

**비고**: _______________________________________________

### TC-INS-MAC-02: 전체 모듈 설치 (P1)

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 1 | `./install.sh --all` | 7개 모듈 순차 설치 시작 | |
| 2 | Notion 모듈 설치 | MCP 설정에 notion 서버 추가 확인 | |
| 3 | GitHub 모듈 설치 | `gh --version` 정상 출력 | |
| 4 | Figma 모듈 설치 | Figma 토큰 입력 프롬프트 표시 | |
| 5 | Pencil 모듈 설치 | VS Code extension 설치 메시지 | |
| 6 | Atlassian 모듈 설치 | Jira/Confluence URL + API 토큰 입력 프롬프트 | |
| 7 | Claude Code MCP 설정 확인 | `~/.claude/claude_desktop_config.json`에 서버 등록 확인 | |

**비고**: _______________________________________________

### TC-INS-MAC-03: Homebrew 없는 환경 (P1)

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 1 | Homebrew 미설치 상태에서 install.sh 실행 | Homebrew 자동 설치 시도 | |
| 2 | sudo 비밀번호 프롬프트 | 비밀번호 입력 창 표시 (curl\|bash 모드에서도) | |
| 3 | Homebrew 설치 완료 후 계속 진행 | base 모듈 설치 정상 진행 | |

**비고**: _______________________________________________

---

## 2. Installer — Windows

### TC-INS-WIN-01: PowerShell 클린 설치 (P0)

**사전 조건**: Windows 10/11, PowerShell 5.1+, 관리자 권한

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 1 | PowerShell(관리자)에서 `irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.ps1 \| iex` | 스크립트 다운로드 및 실행 | |
| 2 | 시스템 요구사항 체크 | RAM, CPU, Disk 체크 결과 표시 | |
| 3 | base 모듈 설치 | Node.js, Git, VS Code, Docker Desktop 설치 | |
| 4 | `node --version` (새 터미널) | v18+ 출력 | |
| 5 | `docker --version` | Docker Desktop 버전 출력 | |
| 6 | `claude --version` | Claude CLI 버전 출력 | |

**비고**: _______________________________________________

### TC-INS-WIN-02: 모듈별 선택 설치 (P1)

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 1 | `.\install.ps1 -Modules "github,notion"` | github + notion 모듈만 설치 | |
| 2 | GitHub CLI 확인 | `gh auth status` 정상 | |
| 3 | Notion MCP 확인 | MCP 설정에 notion 서버 등록 | |

**비고**: _______________________________________________

---

## 3. Installer — Linux

### TC-INS-LNX-01: Ubuntu/Debian 설치 (P1)

**사전 조건**: Ubuntu 22.04+, sudo 권한

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 1 | `curl -fsSL .../install.sh \| bash` | apt 패키지매니저 자동 감지 | |
| 2 | base 모듈 설치 | `apt install` 으로 Node.js, Git, Docker 설치 | |
| 3 | 설치 완료 확인 | 모든 CLI 도구 버전 확인 가능 | |

### TC-INS-LNX-02: Fedora/RHEL 설치 (P2)

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 1 | `curl -fsSL .../install.sh \| bash` | dnf 패키지매니저 자동 감지 | |
| 2 | base 모듈 설치 | `dnf install`으로 설치 진행 | |

**비고**: _______________________________________________

---

## 4. Security Verification

### TC-SEC-01: Checksum 검증 (P1)

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 1 | 원격 설치 시 checksums.json 다운로드 | 체크섬 파일 정상 다운로드 | |
| 2 | 모듈 파일 무결성 검증 | SHA-256 해시 일치 확인 | |
| 3 | 모듈 파일 변조 후 설치 시도 | 체크섬 불일치 경고 + 설치 중단 | |

**비고**: _______________________________________________

---

## Test Execution Summary

| Category | Total TCs | P0 | P1 | P2 | Pass | Fail |
|----------|:---------:|:--:|:--:|:--:|:----:|:----:|
| Installer macOS | 3 | 1 | 2 | 0 | | |
| Installer Windows | 2 | 1 | 1 | 0 | | |
| Installer Linux | 2 | 0 | 1 | 1 | | |
| Security | 1 | 0 | 1 | 0 | | |
| **Total** | **8** | **2** | **5** | **1** | | |

**Tested By**: _______________
**Date**: _______________
**Environment**: _______________
**Overall Result**: Pass / Fail
