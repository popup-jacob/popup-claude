# ADW 종합 테스트 계획서

**문서 버전**: v1.0
**작성일**: 2026-02-13
**프로젝트**: popup-claude (AI-Driven Work Installer + Google Workspace MCP Server)
**상태**: 초안

---

## 1. 개요

### 1.1 목적

본 문서는 ADW(AI-Driven Work) 프로젝트의 전체 코드베이스를 분석하여 도출한 종합 테스트 계획서이다. Windows, macOS, Linux 운영체제별로 모든 기능과 사용자 경험 관점의 테스트 항목을 체계적으로 정의한다.

테스트 대상은 크게 두 가지 컴포넌트로 구성된다.

1. **ADW Installer**: Bash/PowerShell 기반 모듈식 인스톨러 (7개 모듈, 6개 공유 유틸리티)
2. **Google Workspace MCP Server**: TypeScript 기반 MCP 서버 (6개 서비스, 71개 도구, Docker 컨테이너)

### 1.2 범위

| 구분 | 대상 | 비고 |
|------|------|------|
| ADW Installer (macOS/Linux) | `installer/install.sh` | Bash, 698줄 |
| ADW Installer (Windows) | `installer/install.ps1` | PowerShell, 424줄 |
| 모듈: Base | `modules/base/install.sh` | Homebrew, Node.js, Git, VS Code, Docker, Claude CLI, bkit |
| 모듈: Google | `modules/google/install.sh` | Docker 이미지, OAuth, MCP 설정 |
| 모듈: Atlassian | `modules/atlassian/install.sh` | Docker/Rovo 이중 모드 |
| 모듈: Figma | `modules/figma/install.sh` | Remote MCP, OAuth PKCE |
| 모듈: Notion | `modules/notion/install.sh` | Remote MCP, OAuth PKCE |
| 모듈: GitHub | `modules/github/install.sh` | gh CLI 설치 및 인증 |
| 모듈: Pencil | `modules/pencil/install.sh` | VS Code/Cursor 확장 |
| 공유 유틸리티 | `modules/shared/*.sh` | 6개 파일 (colors, docker-utils, mcp-config, browser-utils, package-manager, oauth-helper) |
| MCP Server | `google-workspace-mcp/src/` | TypeScript, Node.js 22 |
| OAuth 인증 | `src/auth/oauth.ts` | OAuth 2.0, CSRF, 뮤텍스, 캐싱 |
| Gmail 도구 | `src/tools/gmail.ts` | 15개 도구 |
| Drive 도구 | `src/tools/drive.ts` | 15개 도구 |
| Calendar 도구 | `src/tools/calendar.ts` | 10개 도구 |
| Docs 도구 | `src/tools/docs.ts` | 9개 도구 |
| Sheets 도구 | `src/tools/sheets.ts` | 13개 도구 |
| Slides 도구 | `src/tools/slides.ts` | 9개 도구 |
| 유틸리티 | `src/utils/*.ts` | 5개 파일 (sanitize, retry, mime, messages, time) |
| Docker | `Dockerfile` | Multi-stage, Node.js 22-slim, non-root |
| CI/CD | `.github/workflows/ci.yml` | lint, build, test, security-audit, shellcheck, docker-build, verify-checksums |

### 1.3 참조 문서

| 문서 | 경로 |
|------|------|
| 기능 계획서 | `docs/01-plan/features/adw-improvement.plan.md` |
| 설계 문서 | `docs/02-design/features/adw-improvement.design.md` |
| 보안 사양서 | `docs/02-design/security-spec.md` |
| 종합 분석 | `docs/03-analysis/adw-comprehensive.analysis.md` |
| 요구사항 추적 매트릭스 | `docs/03-analysis/adw-requirements-traceability-matrix.md` |
| 보안 검증 보고서 | `docs/03-analysis/security-verification-report.md` |
| 공유 유틸리티 설계 | `docs/03-analysis/shared-utilities-design.md` |

### 1.4 테스트 케이스 ID 체계

```
TC-{영역}-{OS}-{번호}

영역:
  INS = Installer (메인 인스톨러)
  BAS = Base 모듈
  GOG = Google 모듈
  ATL = Atlassian 모듈
  FIG = Figma 모듈
  NOT = Notion 모듈
  GIT = GitHub 모듈
  PEN = Pencil 모듈
  SHR = 공유 유틸리티
  AUT = OAuth 인증
  GML = Gmail 도구
  DRV = Drive 도구
  CAL = Calendar 도구
  DOC = Docs 도구
  SHT = Sheets 도구
  SLD = Slides 도구
  UTL = 유틸리티 (sanitize, retry, mime, messages, time)
  DOK = Docker
  SEC = 보안
  PER = 성능/안정성
  E2E = 사용자 시나리오 (End-to-End)
  REG = 회귀 테스트

OS:
  MAC = macOS
  WIN = Windows
  LNX = Linux
  WSL = WSL2
  ALL = 전체 OS
  DOK = Docker 환경

우선순위:
  P0 = Critical (반드시 통과해야 릴리스 가능)
  P1 = High (주요 기능, 릴리스 전 통과 권장)
  P2 = Medium (부가 기능, 다음 릴리스까지 허용)
  P3 = Low (엣지 케이스, 장기 추적)
```

---

## 2. 시스템 최소 사양

### 2.1 macOS

| 항목 | 최소 사양 | 권장 사양 | 근거 |
|------|-----------|-----------|------|
| **OS 버전** | macOS Ventura 13.0 | macOS Sonoma 14.0+ | Docker Desktop 4.42+는 macOS 14+ 필요 (`docker-utils.sh:148`) |
| **CPU** | Apple M1 / Intel Core i5 | Apple M1 Pro 이상 | Docker 이미지 빌드 및 MCP 서버 실행 |
| **RAM** | 8GB | 16GB | Docker Desktop 기본 메모리 할당 4GB + 호스트 OS |
| **디스크 공간** | 10GB 여유 | 20GB 여유 | Docker Desktop ~2GB + Docker 이미지 ~500MB + Node.js ~200MB + VS Code ~500MB + gcloud SDK ~500MB |
| **Homebrew** | 자동 설치 | - | `base/install.sh:24-33` 에서 미설치 시 자동 설치 |
| **Node.js** | v18+ (LTS) | v22 (LTS) | `package.json` 의존성, Dockerfile에서 node:22-slim 사용 |
| **Python 3** | v3.8+ | v3.10+ | Figma/Notion OAuth PKCE 흐름에 필요 (`figma/install.sh:36`, `notion/install.sh:32`) |
| **Docker Desktop** | v4.0+ | v4.41+ (Ventura) / v4.42+ (Sonoma+) | Google, Atlassian 모듈 필수 (`docker-utils.sh:131-155`) |
| **인터넷** | 필수 | 안정적 연결 | GitHub Raw, Docker Hub, npm, Homebrew, Google APIs |
| **관리자 권한** | Homebrew 설치 시 필요 | - | `base/install.sh:26` |

### 2.2 Windows

| 항목 | 최소 사양 | 권장 사양 | 근거 |
|------|-----------|-----------|------|
| **OS 버전** | Windows 10 21H2 | Windows 11 23H2+ | WSL2 지원 필요 (`install.ps1:213-218`) |
| **CPU** | Intel Core i5 / AMD Ryzen 5 | Intel Core i7 / AMD Ryzen 7 | WSL2 + Docker Desktop + MCP 서버 동시 실행 |
| **RAM** | 8GB | 16GB | WSL2 기본 메모리 50% + Docker Desktop |
| **디스크 공간** | 15GB 여유 | 25GB 여유 | WSL2 ~1GB + Docker Desktop ~3GB + 나머지 동일 |
| **WSL2** | 자동 설치 | 사전 설치 | Docker 모듈 사용 시 필수 (`install.ps1:213-218`) |
| **PowerShell** | v5.1+ | v7.0+ | `install.ps1` 실행 환경 |
| **Node.js** | v18+ | v22 | winget으로 자동 설치 |
| **Python 3** | v3.8+ | v3.10+ | Figma/Notion 모듈 사용 시 필요 |
| **Docker Desktop** | v4.0+ | 최신 | WSL2 백엔드 모드 |
| **관리자 권한** | 시스템 패키지 설치 시 필요 | - | `install.ps1:131-169` 조건부 권한 상승 |
| **실행 정책** | Bypass (설치 시) | RemoteSigned | `install.ps1` 실행을 위해 `Set-ExecutionPolicy Bypass` 필요 |

### 2.3 Linux

| 항목 | 최소 사양 | 권장 사양 | 근거 |
|------|-----------|-----------|------|
| **배포판** | Ubuntu 22.04 LTS | Ubuntu 24.04 LTS | `base/install.sh`에서 apt-get, dnf, pacman 지원 |
| **커널** | 5.10+ | 6.1+ | Docker 호환성 |
| **CPU** | x86_64 / aarch64 | - | Docker 이미지 아키텍처 |
| **RAM** | 4GB | 8GB | Docker 없이 사용 시 더 적은 메모리 가능 |
| **디스크 공간** | 5GB 여유 | 15GB 여유 | Docker 미사용 시 최소화 가능 |
| **패키지 관리자** | apt, dnf, pacman 중 하나 | apt (Ubuntu/Debian) | `package-manager.sh`에서 5개 매니저 지원 (brew, apt, dnf, yum, pacman) |
| **Node.js** | v18+ | v22 | NodeSource 스크립트로 자동 설치 (`base/install.sh:49-59`) |
| **Python 3** | v3.8+ | v3.10+ | Figma/Notion 모듈, parse_json 폴백 |
| **Docker Engine** | v20.10+ | 최신 | `curl -fsSL https://get.docker.com` 으로 자동 설치 |
| **sudo 권한** | 패키지 설치 시 필요 | - | apt-get, dnf 등 시스템 패키지 관리 |
| **curl** | 필수 | - | 원격 실행 및 다운로드 |
| **openssl** | 필수 | - | OAuth PKCE, SHA-256 체크섬 |
| **shasum 또는 sha256sum** | 필수 (둘 중 하나) | - | SHA-256 무결성 검증 (`install.sh:152-157`) |

#### 2.3.1 WSL2

| 항목 | 요구사항 | 근거 |
|------|----------|------|
| **WSL 버전** | WSL2 | Docker Desktop 백엔드 |
| **배포판** | Ubuntu 22.04+ | 기본 배포판 |
| **Windows 호스트** | Windows 10 21H2+ | WSL2 지원 |
| **브라우저 연동** | `cmd.exe /c start` 또는 `powershell.exe Start-Process` | `browser-utils.sh:24-25` |

#### 2.3.2 지원 배포판 매트릭스

| 배포판 | 패키지 관리자 | Node.js 설치 | Docker 설치 | VS Code 설치 | 지원 수준 |
|--------|-------------|-------------|-------------|-------------|-----------|
| Ubuntu 22.04/24.04 | apt | NodeSource | get.docker.com | snap | 전체 지원 |
| Debian 12+ | apt | NodeSource | get.docker.com | 수동 | 전체 지원 |
| Fedora 39+ | dnf | NodeSource | get.docker.com | 수동 | 전체 지원 |
| RHEL/CentOS Stream 9+ | dnf/yum | NodeSource | get.docker.com | 수동 | 부분 지원 |
| Arch Linux | pacman | pacman | pacman | AUR | 부분 지원 |
| openSUSE | zypper | 수동 | 수동 | 수동 | 미지원 (매니저 미포함) |

### 2.4 공통 요구사항

| 항목 | 요구사항 | 근거 |
|------|----------|------|
| **인터넷 연결** | 필수 (설치 시), 필수 (MCP 서버 운영 시) | GitHub Raw 다운로드, Docker Pull, Google API 호출 |
| **방화벽 포트** | 아웃바운드 443 (HTTPS), 로컬 3000 (OAuth 콜백, 동적), 3118 (MCP OAuth 콜백) | `oauth.ts:24`, `oauth-helper.sh:15` |
| **프록시** | 미지원 (명시적 프록시 설정 없음) | curl, docker pull, npm 모두 시스템 프록시 의존 |
| **DNS** | `raw.githubusercontent.com`, `ghcr.io`, `*.googleapis.com`, `registry.npmjs.org` 해석 가능 | 원격 설치 및 API 호출 |
| **Claude Code CLI** | v1.0+ | 모든 모듈의 전제 조건 (`base/install.sh:177-186`) |
| **bkit 플러그인** | 설치됨 | Base 모듈에서 자동 설치 (`base/install.sh:192-200`) |

---

## 3. 테스트 환경 구성

### 3.1 macOS 테스트 환경

#### 3.1.1 필수 환경

| 환경 ID | OS 버전 | 칩셋 | 용도 |
|---------|---------|------|------|
| MAC-ENV-01 | macOS Ventura 13.x | Intel | 하위 호환성 검증 |
| MAC-ENV-02 | macOS Sonoma 14.x | Apple M1/M2 | 주력 테스트 환경 |
| MAC-ENV-03 | macOS Sequoia 15.x | Apple M3/M4 | 최신 OS 호환성 |

#### 3.1.2 사전 조건 체크리스트

- [ ] Homebrew 미설치 상태에서 시작 (클린 테스트용)
- [ ] Homebrew 설치 상태에서 시작 (업데이트 테스트용)
- [ ] Docker Desktop 미설치 상태
- [ ] Docker Desktop 설치 + 미실행 상태
- [ ] Docker Desktop 설치 + 실행 상태
- [ ] Apple Silicon (M1+) PATH 설정 확인: `/opt/homebrew/bin/brew`
- [ ] Intel Mac PATH 설정 확인: `/usr/local/bin/brew`

### 3.2 Windows 테스트 환경

#### 3.2.1 필수 환경

| 환경 ID | OS 버전 | 용도 |
|---------|---------|------|
| WIN-ENV-01 | Windows 10 21H2 | 최소 지원 버전 |
| WIN-ENV-02 | Windows 10 22H2 | 현재 안정 버전 |
| WIN-ENV-03 | Windows 11 23H2+ | 최신 OS |

#### 3.2.2 사전 조건 체크리스트

- [ ] WSL2 미설치 상태
- [ ] WSL2 설치 + Ubuntu 배포판 존재
- [ ] PowerShell 5.1 (기본)
- [ ] PowerShell 7.x
- [ ] 관리자 권한 없는 일반 사용자 계정
- [ ] 관리자 권한 가진 계정
- [ ] Docker Desktop 미설치
- [ ] Docker Desktop 설치 (WSL2 백엔드)
- [ ] 실행 정책: Restricted (기본)
- [ ] 실행 정책: RemoteSigned

### 3.3 Linux 테스트 환경

#### 3.3.1 필수 환경

| 환경 ID | 배포판 | 패키지 관리자 | 용도 |
|---------|--------|-------------|------|
| LNX-ENV-01 | Ubuntu 22.04 LTS | apt | 주력 테스트 |
| LNX-ENV-02 | Ubuntu 24.04 LTS | apt | 최신 LTS |
| LNX-ENV-03 | Fedora 39+ | dnf | RPM 계열 |
| LNX-ENV-04 | Arch Linux | pacman | 롤링 릴리스 |
| LNX-ENV-05 | WSL2 Ubuntu 22.04 | apt | Windows 연동 |

#### 3.3.2 사전 조건 체크리스트

- [ ] sudo 접근 가능한 사용자
- [ ] curl 설치됨
- [ ] openssl 설치됨
- [ ] Node.js 미설치 상태 (클린 테스트)
- [ ] Node.js 사전 설치 상태 (기존 환경 테스트)
- [ ] Docker 미설치 상태
- [ ] Docker 설치 + docker 그룹 미추가
- [ ] Docker 설치 + docker 그룹 추가

### 3.4 Docker 테스트 환경

#### 3.4.1 필수 환경

| 환경 ID | Docker 버전 | 호스트 OS | 용도 |
|---------|------------|----------|------|
| DOK-ENV-01 | Docker Desktop 4.41 | macOS Ventura | 하위 호환성 |
| DOK-ENV-02 | Docker Desktop 최신 | macOS Sonoma+ | 주력 테스트 |
| DOK-ENV-03 | Docker Desktop 최신 | Windows 11 (WSL2) | Windows Docker |
| DOK-ENV-04 | Docker Engine 최신 | Ubuntu 22.04 | Linux Docker |

#### 3.4.2 Docker 이미지 검증 항목

- [ ] `ghcr.io/popup-jacob/google-workspace-mcp:latest` Pull 가능
- [ ] `ghcr.io/sooperset/mcp-atlassian:latest` Pull 가능
- [ ] Google MCP 이미지 크기 확인 (500MB 이하 권장)
- [ ] 이미지 내 Node.js 22 확인
- [ ] 이미지 내 non-root 사용자 (mcp:mcp) 확인 (UID 1001)
- [ ] VOLUME `/app/.google-workspace` 마운트 가능
- [ ] HEALTHCHECK 동작 확인

---

## 4. 기능 테스트

### 4.1 인스톨러 기능 테스트

#### 4.1.1 macOS 테스트 케이스

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-INS-MAC-001 | 인수 파싱: --modules 옵션 | install.sh 접근 가능 | `./install.sh --modules "google,atlassian"` 실행 | SELECTED_MODULES에 "google atlassian" 설정됨 | P0 |
| TC-INS-MAC-002 | 인수 파싱: --all 옵션 | install.sh 접근 가능 | `./install.sh --all` 실행 | required=true가 아닌 모든 모듈 선택 | P0 |
| TC-INS-MAC-003 | 인수 파싱: --list 옵션 | install.sh 접근 가능 | `./install.sh --list` 실행 | 모듈 목록 표시 후 exit 0 | P1 |
| TC-INS-MAC-004 | 인수 파싱: --skip-base 옵션 | install.sh 접근 가능 | `./install.sh --modules "google" --skip-base` 실행 | SKIP_BASE=true, base 모듈 건너뜀 | P1 |
| TC-INS-MAC-005 | 인수 파싱: 알 수 없는 옵션 | install.sh 접근 가능 | `./install.sh --unknown` 실행 | "Unknown option" 에러 메시지, exit 1 | P1 |
| TC-INS-MAC-006 | 모듈 스캔: 로컬 실행 | modules/ 폴더 존재 | 로컬에서 install.sh 실행 | USE_LOCAL=true, 7개 module.json 파싱 | P0 |
| TC-INS-MAC-007 | 모듈 스캔: 원격 실행 | 인터넷 연결 | `curl \| bash` 방식 실행 | USE_LOCAL=false, modules.json으로 모듈 목록 획득 | P0 |
| TC-INS-MAC-008 | 모듈 검증: 잘못된 모듈명 | install.sh 접근 가능 | `./install.sh --modules "nonexistent"` 실행 | "Unknown module" 에러, exit 1 | P1 |
| TC-INS-MAC-009 | 스마트 상태 감지 | 클린 환경 | install.sh 실행 | Node.js, Git, VS Code, Docker, Claude, bkit 상태 정확히 표시 | P0 |
| TC-INS-MAC-010 | Base 자동 스킵 | Node.js, Git, Claude, bkit 모두 설치됨 | `./install.sh --modules "google"` 실행 | "All base tools are already installed. Skipping base." 메시지 | P1 |
| TC-INS-MAC-011 | Docker 미실행 경고 | Docker 설치됨 + 미실행 | Docker 필요 모듈 선택 후 실행 | Docker Desktop 실행 안내 표시, 사용자 입력 대기 | P1 |
| TC-INS-MAC-012 | 모듈 실행 순서 | 여러 모듈 선택 | `./install.sh --modules "google,atlassian,github"` 실행 | MODULE_ORDERS 기준 정렬 (github:2 -> atlassian:5 -> google:6) | P1 |
| TC-INS-MAC-013 | MCP 설정 백업 | ~/.claude/mcp.json 존재 | 모듈 설치 시작 | mcp.json.bak.{timestamp} 백업 파일 생성 | P0 |
| TC-INS-MAC-014 | 모듈 실패 시 롤백 | MCP 설정 백업 완료 | 모듈 install.sh가 exit 1 반환 | "Rolling back MCP configuration" 메시지, 백업에서 복원 | P0 |
| TC-INS-MAC-015 | 설치 성공 시 백업 정리 | 모든 모듈 성공 | 전체 설치 완료 | 백업 파일 삭제, "Installation Complete!" 메시지 | P1 |
| TC-INS-MAC-016 | 설치 후 검증 | 모듈 설치 완료 | verify_module_installation 호출 | MCP config 등록 확인, Docker 이미지 존재 확인 | P1 |
| TC-INS-MAC-017 | parse_json: node 우선 | Node.js 설치됨 | JSON 파싱 실행 | node -e를 통한 stdin 기반 파싱 | P1 |
| TC-INS-MAC-018 | parse_json: python3 폴백 | Node.js 미설치, Python3 설치됨 | JSON 파싱 실행 | python3을 통한 stdin 기반 파싱 | P2 |
| TC-INS-MAC-019 | parse_json: osascript 폴백 | Node.js/Python3 미설치 (macOS) | JSON 파싱 실행 | osascript JavaScript를 통한 stdin 기반 파싱 | P3 |
| TC-INS-MAC-020 | SHA-256 체크섬 검증 | 원격 실행, checksums.json 가용 | download_and_verify 호출 | SHA-256 해시 일치 시 "Integrity verified" 메시지 | P0 |
| TC-INS-MAC-021 | SHA-256 체크섬 불일치 | 원격 실행, 변조된 파일 | download_and_verify 호출 | "[SECURITY] Integrity verification failed!" 메시지, 임시파일 삭제, return 1 | P0 |
| TC-INS-MAC-022 | checksums.json 불가 시 | 원격 실행, checksums.json 404 | download_and_verify 호출 | "[WARN] checksums.json not available" 경고, 설치 계속 진행 | P2 |
| TC-INS-MAC-023 | 공유 스크립트 원격 다운로드 | 원격 실행 | setup_shared_dir 호출 | SHARED_TMP에 colors.sh, browser-utils.sh, docker-utils.sh, mcp-config.sh 다운로드 | P1 |
| TC-INS-MAC-024 | 임시 파일 정리 (trap) | 원격 실행 | 설치 완료 또는 중단 | EXIT trap으로 SHARED_TMP 디렉토리 삭제 | P1 |
| TC-INS-MAC-025 | 환경변수 지원 | - | `MODULES="google" INSTALL_ALL=false ./install.sh` 실행 | 환경변수 값이 명령줄 인수처럼 적용 | P2 |
| TC-INS-MAC-026 | Apple Silicon Homebrew PATH | M1+ Mac | Homebrew 설치 후 | `/opt/homebrew/bin/brew` shellenv 적용됨 | P1 |

#### 4.1.2 Windows 테스트 케이스

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-INS-WIN-001 | 매개변수 파싱: -modules | install.ps1 접근 가능 | `.\install.ps1 -modules "google,atlassian"` 실행 | $selectedModules에 "google","atlassian" 설정 | P0 |
| TC-INS-WIN-002 | 매개변수 파싱: -all | install.ps1 접근 가능 | `.\install.ps1 -all` 실행 | required가 아닌 모든 모듈 선택 | P0 |
| TC-INS-WIN-003 | 매개변수 파싱: -list | install.ps1 접근 가능 | `.\install.ps1 -list` 실행 | 모듈 목록 표시 (관리자 권한 불필요) | P1 |
| TC-INS-WIN-004 | 환경변수 지원 | - | `$env:MODULES='google'; .\install.ps1` 실행 | $env:MODULES 값 적용 | P2 |
| TC-INS-WIN-005 | 관리자 권한 감지 | 비관리자 계정 | Node.js 미설치 상태에서 실행 | UAC 프롬프트로 관리자 권한 요청 | P0 |
| TC-INS-WIN-006 | 조건부 권한 상승 | 모든 기본 도구 설치됨 | `-modules "notion" -skipBase` 실행 | 관리자 권한 요청 없이 실행 | P1 |
| TC-INS-WIN-007 | 원격 실행 관리자 상승 | 비관리자, 원격 실행 | `irm .../install.ps1 \| iex` 실행 | scriptblock으로 원격 스크립트 재실행 | P1 |
| TC-INS-WIN-008 | 스마트 상태 감지 | 클린 환경 | install.ps1 실행 | Node.js, Git, VS Code, WSL, Docker, Claude, bkit 상태 표시 | P0 |
| TC-INS-WIN-009 | WSL 감지 | WSL2 설치됨 | install.ps1 실행 | `wsl --version` 성공, WSL: [OK] 표시 | P1 |
| TC-INS-WIN-010 | Docker 미실행 경고 | Docker 설치 + 미실행 | Docker 필요 모듈 선택 | "Docker Desktop is not running!" 경고, 사용자 입력 대기 | P1 |
| TC-INS-WIN-011 | 모듈 실행 순서 | 여러 모듈 선택 | `-modules "google,github"` 실행 | order 기준 정렬 (github:2, google:6) | P1 |
| TC-INS-WIN-012 | Base 자동 스킵 | 기본 도구 모두 설치됨 | `-modules "google"` 실행 | "All base tools are already installed. Skipping base." | P1 |
| TC-INS-WIN-013 | MCP 설정 경로 | 설치 완료 | MCP config 확인 | `$env:USERPROFILE\.claude\mcp.json` 경로 사용 | P0 |
| TC-INS-WIN-014 | Remote MCP 타입 표시 | 설치 완료 | 완료 요약 확인 | Remote MCP 서버는 "(Remote MCP)" 텍스트와 함께 표시 | P2 |
| TC-INS-WIN-015 | 로컬/원격 자동 감지 | - | $MyInvocation.MyCommand.Path 확인 | 로컬: $UseLocal=$true, 원격: $UseLocal=$false | P1 |
| TC-INS-WIN-016 | -installDocker 플래그 | Docker 미설치 | `.\install.ps1 -installDocker` 실행 | $script:needsDocker=$true, Docker 설치 진행 | P1 |

#### 4.1.3 Linux 테스트 케이스

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-INS-LNX-001 | apt 기반 설치 | Ubuntu/Debian | install.sh 실행 | apt-get으로 Node.js, Git 설치 | P0 |
| TC-INS-LNX-002 | dnf 기반 설치 | Fedora/RHEL | install.sh 실행 | dnf로 Node.js, Git 설치 | P1 |
| TC-INS-LNX-003 | pacman 기반 설치 | Arch Linux | install.sh 실행 | pacman으로 Node.js, Git 설치 | P2 |
| TC-INS-LNX-004 | Docker 그룹 추가 | Linux, Docker 설치 | base 모듈 Docker 설치 | `sudo usermod -aG docker $USER` 실행 | P1 |
| TC-INS-LNX-005 | SHA-256: sha256sum | sha256sum 있음, shasum 없음 | download_and_verify 호출 | sha256sum으로 해시 계산 | P1 |
| TC-INS-LNX-006 | SHA-256: shasum | shasum 있음, sha256sum 없음 | download_and_verify 호출 | shasum -a 256으로 해시 계산 | P2 |
| TC-INS-LNX-007 | VS Code snap 설치 | Ubuntu, snap 가능 | base 모듈 실행 | `sudo snap install code --classic` | P2 |
| TC-INS-LNX-008 | WSL2 브라우저 열기 | WSL2 환경 | browser_open() 호출 | `cmd.exe /c start` 또는 `powershell.exe Start-Process` | P1 |
| TC-INS-LNX-009 | xdg-open 폴백 | 일반 Linux (비WSL) | browser_open() 호출 | `xdg-open` 명령 사용 | P1 |
| TC-INS-LNX-010 | 미지원 패키지 관리자 | zypper 전용 시스템 | install.sh 실행 | "Unsupported package manager" 경고, 수동 설치 안내 | P3 |

### 4.2 Google Workspace MCP 기능 테스트

#### 4.2.1 인증 (OAuth 2.0)

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-AUT-ALL-001 | 최초 인증 흐름 | client_secret.json 존재, token.json 없음 | getAuthenticatedClient() 호출 | 브라우저 OAuth 흐름 시작, token.json 생성 (mode 0600) | P0 |
| TC-AUT-ALL-002 | 토큰 재사용 | 유효한 token.json 존재 | getAuthenticatedClient() 호출 | 브라우저 없이 캐시된 토큰 사용 | P0 |
| TC-AUT-ALL-003 | 토큰 만료 갱신 | token.json의 expiry_date < now + 5분 | getAuthenticatedClient() 호출 | refreshAccessToken() 자동 호출, 새 토큰 저장 | P0 |
| TC-AUT-ALL-004 | 토큰 갱신 실패 시 재인증 | refresh_token 무효화 | getAuthenticatedClient() 호출 | refreshAccessToken 실패 -> getTokenFromBrowser 실행 | P0 |
| TC-AUT-ALL-005 | refresh_token 누락 검증 | token.json에 refresh_token 없음 | loadToken() 호출 | null 반환, "[SECURITY] Missing refresh_token" 로그 | P1 |
| TC-AUT-ALL-006 | CSRF 방지: state 파라미터 | OAuth 흐름 진행 중 | 콜백에 잘못된 state 값 전송 | 403 응답, "State mismatch -- possible CSRF attack" 로그 | P0 |
| TC-AUT-ALL-007 | CSRF 방지: state 일치 | OAuth 흐름 진행 중 | 콜백에 올바른 state 값 전송 | 200 응답, 토큰 발급 | P0 |
| TC-AUT-ALL-008 | 인증 코드 미수신 | OAuth 콜백 | code 파라미터 없이 콜백 | 400 응답, "No authorization code" 에러 | P1 |
| TC-AUT-ALL-009 | 로그인 타임아웃 | OAuth 흐름 시작 | 5분 동안 로그인 미완료 | "Login timeout (5 minutes)" 에러 | P1 |
| TC-AUT-ALL-010 | 뮤텍스: 동시 인증 방지 | - | getAuthenticatedClient() 동시 2회 호출 | 두 번째 호출은 첫 번째 Promise 재사용 (authInProgress) | P0 |
| TC-AUT-ALL-011 | 서비스 캐싱 | 인증 완료 | getGoogleServices() 50분 내 2회 호출 | 두 번째 호출 시 캐시된 서비스 인스턴스 반환 | P1 |
| TC-AUT-ALL-012 | 서비스 캐시 만료 | 인증 완료, 50분 경과 | getGoogleServices() 호출 | 새 서비스 인스턴스 생성, 캐시 갱신 | P1 |
| TC-AUT-ALL-013 | clearServiceCache | 캐시 존재 | clearServiceCache() 호출 후 getGoogleServices() | 새 서비스 인스턴스 생성 | P2 |
| TC-AUT-ALL-014 | 설정 디렉토리 생성 | CONFIG_DIR 없음 | ensureConfigDir() 호출 | 디렉토리 생성 (mode 0700) | P0 |
| TC-AUT-ALL-015 | 설정 디렉토리 권한 수정 | CONFIG_DIR 권한 0755 | ensureConfigDir() 호출 | 0700으로 변경, security event 로그 | P1 |
| TC-AUT-ALL-016 | 동적 OAuth 스코프 | GOOGLE_SCOPES="gmail,drive" | resolveScopes() 호출 | gmail.modify + drive 스코프만 포함 | P1 |
| TC-AUT-ALL-017 | 기본 전체 스코프 | GOOGLE_SCOPES 미설정 | resolveScopes() 호출 | 6개 서비스 전체 스코프 반환 | P1 |
| TC-AUT-ALL-018 | 동적 OAuth 포트 | OAUTH_PORT=8080 | getTokenFromBrowser() 호출 | localhost:8080에서 콜백 서버 시작 | P2 |
| TC-AUT-ALL-019 | client_secret.json 미존재 | CONFIG_DIR에 파일 없음 | loadClientSecret() 호출 | 에러 메시지에 설치 가이드 포함 | P0 |
| TC-AUT-ALL-020 | installed 타입 클라이언트 | client_secret.json에 "installed" 키 | createOAuth2Client() 호출 | installed 자격 증명으로 클라이언트 생성 | P1 |
| TC-AUT-ALL-021 | web 타입 클라이언트 | client_secret.json에 "web" 키 | createOAuth2Client() 호출 | web 자격 증명으로 클라이언트 생성 | P2 |
| TC-AUT-ALL-022 | 보안 이벤트 로깅 | - | 각 보안 이벤트 발생 | stderr에 JSON 형식 로그 (timestamp, event_type, result, detail) | P1 |

#### 4.2.2 Gmail 도구

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-GML-ALL-001 | gmail_search: 기본 검색 | 인증 완료 | query="from:test@example.com", maxResults=5 | messages 배열 반환, id/from/subject/date/snippet 포함 | P0 |
| TC-GML-ALL-002 | gmail_search: 빈 결과 | 인증 완료 | 존재하지 않는 검색어 | total=0, messages=[] | P1 |
| TC-GML-ALL-003 | gmail_read: 전체 읽기 | 인증 완료, 메시지 ID 확보 | messageId로 호출 | id, from, to, cc, subject, date, body, attachments, labels 반환 | P0 |
| TC-GML-ALL-004 | gmail_read: MIME 파싱 | 멀티파트 이메일 존재 | messageId로 호출 | extractTextBody()로 text/plain 추출, text/html 폴백 | P1 |
| TC-GML-ALL-005 | gmail_read: 첨부파일 목록 | 첨부파일 포함 이메일 | messageId로 호출 | extractAttachments()로 filename, mimeType, attachmentId, size 반환 | P1 |
| TC-GML-ALL-006 | gmail_read: 본문 5000자 제한 | 긴 본문 이메일 | messageId로 호출 | body가 5000자로 truncate됨 | P2 |
| TC-GML-ALL-007 | gmail_send: 이메일 발송 | 인증 완료 | to, subject, body 설정 | success=true, messageId 반환 | P0 |
| TC-GML-ALL-008 | gmail_send: CC/BCC | 인증 완료 | cc, bcc 포함 발송 | CC/BCC 헤더 포함된 이메일 발송 | P1 |
| TC-GML-ALL-009 | gmail_send: UTF-8 제목 | 인증 완료 | 한글 제목 발송 | Subject: =?UTF-8?B?...?= Base64 인코딩 | P1 |
| TC-GML-ALL-010 | gmail_send: 헤더 인젝션 방지 | 인증 완료 | to="victim@test.com\r\nBcc: spy@evil.com" | sanitizeEmailHeader()로 CRLF 제거, spy@evil.com 미전송 | P0 |
| TC-GML-ALL-011 | gmail_draft_create | 인증 완료 | to, subject, body 설정 | draftId 반환, "Draft saved" 메시지 | P1 |
| TC-GML-ALL-012 | gmail_draft_list | 임시보관함에 드래프트 존재 | maxResults=5 호출 | total, drafts 배열 (draftId, to, subject, snippet) | P1 |
| TC-GML-ALL-013 | gmail_draft_send | 드래프트 존재 | draftId로 호출 | success=true, messageId 반환 | P1 |
| TC-GML-ALL-014 | gmail_draft_delete | 드래프트 존재 | draftId로 호출 | success=true, "Draft deleted" 메시지 | P2 |
| TC-GML-ALL-015 | gmail_labels_list | 인증 완료 | 호출 | labels 배열 (id, name, type) | P1 |
| TC-GML-ALL-016 | gmail_labels_add | 메시지 및 라벨 존재 | messageId, labelIds 설정 | "Label added" 메시지 | P2 |
| TC-GML-ALL-017 | gmail_labels_remove | 라벨 적용된 메시지 | messageId, labelIds 설정 | "Label removed" 메시지 | P2 |
| TC-GML-ALL-018 | gmail_attachment_get | 첨부파일 포함 메시지 | messageId, attachmentId 설정 | size, data (base64) 반환 | P1 |
| TC-GML-ALL-019 | gmail_trash | 메시지 존재 | messageId로 호출 | "Email moved to trash" 메시지 | P1 |
| TC-GML-ALL-020 | gmail_untrash | 휴지통 메시지 존재 | messageId로 호출 | "Email restored from trash" 메시지 | P2 |
| TC-GML-ALL-021 | gmail_mark_read | 읽지 않은 메시지 | messageId로 호출 | UNREAD 라벨 제거 | P1 |
| TC-GML-ALL-022 | gmail_mark_unread | 읽은 메시지 | messageId로 호출 | UNREAD 라벨 추가 | P2 |

#### 4.2.3 Drive 도구

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-DRV-ALL-001 | drive_search: 기본 검색 | 인증 완료 | query="test", maxResults=10 | files 배열, supportsAllDrives=true 사용 | P0 |
| TC-DRV-ALL-002 | drive_search: MIME 필터 | 인증 완료 | mimeType="application/pdf" | PDF만 반환 | P1 |
| TC-DRV-ALL-003 | drive_search: 쿼리 이스케이프 | 인증 완료 | query="test's file" | escapeDriveQuery()로 `'` 이스케이프 | P0 |
| TC-DRV-ALL-004 | drive_list: 루트 목록 | 인증 완료 | folderId="root" | root 폴더 파일 목록, isFolder 필드 포함 | P0 |
| TC-DRV-ALL-005 | drive_list: ID 검증 | 인증 완료 | folderId="invalid!@#" | validateDriveId() 에러: "Invalid folderId format" | P0 |
| TC-DRV-ALL-006 | drive_get_file | 파일 존재 | fileId로 호출 | 상세 정보 (id, name, type, owners, shared 등) | P1 |
| TC-DRV-ALL-007 | drive_create_folder | 인증 완료 | name="Test Folder" | folderId, name, link 반환 | P1 |
| TC-DRV-ALL-008 | drive_create_folder: 부모 지정 | 상위 폴더 존재 | name, parentId 설정 | 지정 폴더 내 생성 | P2 |
| TC-DRV-ALL-009 | drive_copy | 파일 존재 | fileId, newName 설정 | 복사본 생성, 새 fileId 반환 | P1 |
| TC-DRV-ALL-010 | drive_move | 파일과 대상 폴더 존재 | fileId, newParentId 설정 | previousParents 제거, newParentId 추가 | P1 |
| TC-DRV-ALL-011 | drive_rename | 파일 존재 | fileId, newName 설정 | 이름 변경 확인 | P2 |
| TC-DRV-ALL-012 | drive_delete | 파일 존재 | fileId로 호출 | trashed=true 설정, "File moved to trash" | P1 |
| TC-DRV-ALL-013 | drive_restore | 휴지통 파일 존재 | fileId로 호출 | trashed=false 설정, "File restored" | P2 |
| TC-DRV-ALL-014 | drive_share | 파일 존재 | fileId, email, role="writer" | 권한 생성, "Shared with email as editor" | P1 |
| TC-DRV-ALL-015 | drive_share_link | 파일 존재 | fileId, type="anyone" | 링크 공유 활성화, webViewLink 반환 | P1 |
| TC-DRV-ALL-016 | drive_unshare | 공유된 파일 | fileId, email | 권한 제거, "Sharing removed" | P2 |
| TC-DRV-ALL-017 | drive_unshare: 권한 미존재 | 미공유 파일 | 존재하지 않는 email | success=false, "No sharing permission found" | P2 |
| TC-DRV-ALL-018 | drive_list_permissions | 공유된 파일 | fileId로 호출 | permissions 배열 (id, type, role, email, name) | P2 |
| TC-DRV-ALL-019 | drive_get_storage_quota | 인증 완료 | 호출 | limit, usage, usageInDrive, usageInDriveTrash (GB 단위) | P2 |
| TC-DRV-ALL-020 | Shared Drive 지원 | Shared Drive 존재 | 모든 Drive 도구에서 corpora="allDrives" | Shared Drive 파일 포함 | P1 |

#### 4.2.4 Calendar 도구

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-CAL-ALL-001 | calendar_list_calendars | 인증 완료 | 호출 | calendars 배열 (id, name, primary, accessRole) | P0 |
| TC-CAL-ALL-002 | calendar_list_events: 기본 | 인증 완료 | calendarId="primary" | 현재~30일 후 이벤트 목록 | P0 |
| TC-CAL-ALL-003 | calendar_list_events: 범위 지정 | 인증 완료 | timeMin, timeMax 설정 | 지정 범위 이벤트만 반환 | P1 |
| TC-CAL-ALL-004 | calendar_get_event | 이벤트 존재 | eventId로 호출 | 상세 정보 (recurrence, reminders, conferenceData 포함) | P1 |
| TC-CAL-ALL-005 | calendar_create_event | 인증 완료 | title, startTime, endTime 설정 | eventId, link 반환, 동적 타임존 적용 | P0 |
| TC-CAL-ALL-006 | calendar_create_event: 참석자 | 인증 완료 | attendees 배열 포함 | 참석자에게 알림 발송 (sendUpdates="all") | P1 |
| TC-CAL-ALL-007 | calendar_create_event: 시간 파싱 | 인증 완료 | startTime="2026-03-01 10:00" | parseTime()으로 ISO 8601 변환 + UTC 오프셋 | P1 |
| TC-CAL-ALL-008 | calendar_create_all_day_event | 인증 완료 | date="2026-03-01" | 종일 이벤트 생성, date 필드 사용 | P1 |
| TC-CAL-ALL-009 | calendar_update_event | 이벤트 존재 | eventId, 수정할 필드 | 기존 값 유지 + 수정 값 반영 | P1 |
| TC-CAL-ALL-010 | calendar_delete_event | 이벤트 존재 | eventId, sendNotifications=true | 이벤트 삭제, 참석자 알림 | P1 |
| TC-CAL-ALL-011 | calendar_quick_add | 인증 완료 | text="Meeting tomorrow at 3pm" | 자연어 파싱으로 이벤트 생성 | P2 |
| TC-CAL-ALL-012 | calendar_find_free_time | 인증 완료 | timeMin, timeMax 설정 | freebusy 정보 반환 | P2 |
| TC-CAL-ALL-013 | calendar_respond_to_event | 초대 이벤트 존재 | response="accepted" | 자신의 responseStatus 변경 | P2 |
| TC-CAL-ALL-014 | 동적 타임존: 환경변수 | TIMEZONE="America/New_York" | calendar_create_event 호출 | America/New_York 타임존 적용 | P1 |
| TC-CAL-ALL-015 | 동적 타임존: 자동 감지 | TIMEZONE 미설정 | getTimezone() 호출 | Intl.DateTimeFormat().resolvedOptions().timeZone 반환 | P1 |

#### 4.2.5 Docs 도구

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-DOC-ALL-001 | docs_create: 빈 문서 | 인증 완료 | title만 설정 | documentId, title, link 반환 | P0 |
| TC-DOC-ALL-002 | docs_create: 내용 포함 | 인증 완료 | title, content 설정 | 문서 생성 후 batchUpdate로 텍스트 삽입 | P1 |
| TC-DOC-ALL-003 | docs_create: 폴더 지정 | 대상 폴더 존재 | folderId 설정 | 지정 폴더로 이동 | P2 |
| TC-DOC-ALL-004 | docs_read | 문서 존재 | documentId로 호출 | content (10000자 제한), title, revisionId 반환 | P0 |
| TC-DOC-ALL-005 | docs_read: 테이블 포함 | 테이블 있는 문서 | documentId로 호출 | "[table]" 텍스트로 테이블 표시 | P2 |
| TC-DOC-ALL-006 | docs_append | 문서 존재 | documentId, content 설정 | 문서 끝에 "\n" + content 삽입 | P1 |
| TC-DOC-ALL-007 | docs_prepend | 문서 존재 | documentId, content 설정 | 문서 시작(index 1)에 content + "\n" 삽입 | P1 |
| TC-DOC-ALL-008 | docs_replace_text | 문서 존재 | searchText, replaceText 설정 | occurrencesChanged 반환 | P1 |
| TC-DOC-ALL-009 | docs_replace_text: 대소문자 | 문서 존재 | matchCase=true | 대소문자 구분 검색 | P2 |
| TC-DOC-ALL-010 | docs_insert_heading | 문서 존재 | text, level=2 | HEADING_2 스타일 적용 | P2 |
| TC-DOC-ALL-011 | docs_insert_table | 문서 존재 | rows=3, columns=4 | 3x4 테이블 삽입 | P2 |
| TC-DOC-ALL-012 | docs_get_comments | 문서 존재 | documentId로 호출 | comments 배열 (id, content, author, resolved, replies) | P2 |
| TC-DOC-ALL-013 | docs_add_comment | 문서 존재 | content 설정 | commentId 반환 | P2 |

#### 4.2.6 Sheets 도구

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SHT-ALL-001 | sheets_create | 인증 완료 | title 설정 | spreadsheetId, link, sheets 반환 | P0 |
| TC-SHT-ALL-002 | sheets_create: 시트명 지정 | 인증 완료 | sheetNames=["Data","Summary"] | 2개 시트 포함 스프레드시트 생성 | P1 |
| TC-SHT-ALL-003 | sheets_get_info | 스프레드시트 존재 | spreadsheetId로 호출 | title, sheets (sheetId, title, rowCount, columnCount) | P1 |
| TC-SHT-ALL-004 | sheets_read | 데이터 존재 | spreadsheetId, range="Sheet1!A1:D10" | values 2D 배열, rowCount, columnCount | P0 |
| TC-SHT-ALL-005 | sheets_read_multiple | 데이터 존재 | ranges=["A1:B5","C1:D5"] | valueRanges 배열 | P2 |
| TC-SHT-ALL-006 | sheets_write | 스프레드시트 존재 | range, values 설정 | updatedCells, updatedRows 반환 | P0 |
| TC-SHT-ALL-007 | sheets_append | 데이터 존재 | range="Sheet1", values 설정 | INSERT_ROWS로 행 추가, updatedRows 반환 | P1 |
| TC-SHT-ALL-008 | sheets_clear | 데이터 존재 | range 설정 | 범위 데이터 삭제 | P1 |
| TC-SHT-ALL-009 | sheets_add_sheet | 스프레드시트 존재 | title 설정 | sheetId, title 반환 | P1 |
| TC-SHT-ALL-010 | sheets_delete_sheet | 시트 2개 이상 | sheetId 설정 | 시트 삭제 완료 | P2 |
| TC-SHT-ALL-011 | sheets_rename_sheet | 시트 존재 | sheetId, newTitle | 이름 변경 완료 | P2 |
| TC-SHT-ALL-012 | sheets_format_cells: 볼드 | 시트 존재 | bold=true, 범위 설정 | textFormat.bold 적용 | P2 |
| TC-SHT-ALL-013 | sheets_format_cells: 배경색 | 시트 존재 | backgroundColor="#FF0000" | RGB 변환 (1,0,0) 적용 | P2 |
| TC-SHT-ALL-014 | sheets_auto_resize | 시트 존재 | sheetId 설정 | COLUMNS 차원 자동 크기 조정 | P3 |

#### 4.2.7 Slides 도구

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SLD-ALL-001 | slides_create | 인증 완료 | title 설정 | presentationId, link, slideCount 반환 | P0 |
| TC-SLD-ALL-002 | slides_create: 폴더 지정 | 대상 폴더 존재 | folderId 설정 | 지정 폴더로 이동 | P2 |
| TC-SLD-ALL-003 | slides_get_info | 프레젠테이션 존재 | presentationId로 호출 | title, slideCount, pageSize, slides 배열 | P1 |
| TC-SLD-ALL-004 | slides_read | 프레젠테이션 존재 | presentationId로 호출 | 슬라이드별 텍스트 추출 (1000자 제한) | P0 |
| TC-SLD-ALL-005 | slides_add_slide: 제목+본문 | 프레젠테이션 존재 | title, body, layout="TITLE_AND_BODY" | 슬라이드 생성 + TITLE/BODY placeholder에 텍스트 삽입 | P1 |
| TC-SLD-ALL-006 | slides_add_slide: 빈 슬라이드 | 프레젠테이션 존재 | layout="BLANK" | 빈 슬라이드 생성 | P2 |
| TC-SLD-ALL-007 | slides_delete_slide | 슬라이드 존재 | slideId 설정 | 슬라이드 삭제 | P2 |
| TC-SLD-ALL-008 | slides_duplicate_slide | 슬라이드 존재 | slideId 설정 | 복제본 생성, newSlideId 반환 | P2 |
| TC-SLD-ALL-009 | slides_move_slide | 슬라이드 2개 이상 | slideId, insertionIndex=0 | 슬라이드 위치 변경 | P2 |
| TC-SLD-ALL-010 | slides_add_text | 슬라이드 존재 | slideId, text, 좌표 설정 | 텍스트 박스 생성 + 텍스트 삽입 | P1 |
| TC-SLD-ALL-011 | slides_replace_text | 텍스트 포함 프레젠테이션 | searchText, replaceText | occurrencesChanged 반환 | P2 |

### 4.3 모듈별 기능 테스트

#### 4.3.1 Atlassian MCP

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-ATL-ALL-001 | Docker 모드 선택 | Docker 설치 + 실행 | 역할 선택에서 1 (Local install) | Docker 이미지 pull + MCP 설정 등록 | P0 |
| TC-ATL-ALL-002 | Rovo 모드 선택 | Docker 미설치 | 역할 선택에서 1 (Simple install) | `claude mcp add --transport sse` 실행 | P0 |
| TC-ATL-ALL-003 | Docker 모드: 자격증명 저장 | Docker 설치 | URL, email, apiToken 입력 | `~/.atlassian-mcp/credentials.env` 생성 (권한 600) | P0 |
| TC-ATL-ALL-004 | Docker 모드: 디렉토리 권한 | Docker 설치 | credentials.env 저장 | `~/.atlassian-mcp/` 디렉토리 권한 700 | P1 |
| TC-ATL-ALL-005 | Docker 모드: MCP 설정 | Docker 모드 완료 | MCP 설정 파일 확인 | --env-file로 자격증명 전달, 인라인 환경변수 미사용 | P0 |
| TC-ATL-ALL-006 | URL 정규화 | Docker 모드 | URL 끝에 "/" 포함 입력 | 후행 "/" 제거됨 | P2 |
| TC-ATL-ALL-007 | Docker 없이 Docker 모드 선택 | Docker 미설치 | Docker 모드 강제 선택 | "Docker is not installed!" 에러, 설치 안내 URL | P1 |

#### 4.3.2 Figma MCP

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-FIG-ALL-001 | Claude CLI 확인 | claude 미설치 | figma 모듈 실행 | "Claude CLI is required" 에러, exit 1 | P0 |
| TC-FIG-ALL-002 | Python3 확인 | python3 미설치 | figma 모듈 실행 | "Python 3 is required for OAuth" 에러, exit 1 | P0 |
| TC-FIG-ALL-003 | Remote MCP 등록 | claude, python3 설치됨 | figma 모듈 실행 | `claude mcp add --transport http figma https://mcp.figma.com/mcp` 실행 | P0 |
| TC-FIG-ALL-004 | OAuth PKCE 흐름 | MCP 등록 완료 | mcp_oauth_flow 실행 | PKCE code_verifier/code_challenge 생성, 브라우저 OAuth | P1 |
| TC-FIG-ALL-005 | OAuth 메타데이터 획득 | 인터넷 연결 | well-known URL 호출 | authorization_endpoint, token_endpoint 파싱 | P1 |
| TC-FIG-ALL-006 | 토큰 저장 | OAuth 완료 | _save_tokens 호출 | `~/.claude/.credentials.json`에 mcpOAuth 엔트리 저장 | P1 |
| TC-FIG-ALL-007 | 기존 인증 재사용 | 유효한 토큰 존재 | figma 모듈 재실행 | "Already authenticated with figma!" 메시지, OAuth 건너뜀 | P2 |
| TC-FIG-ALL-008 | OAuth state 불일치 | OAuth 진행 중 | 잘못된 state로 콜백 | "State mismatch" 에러 | P1 |

#### 4.3.3 Notion MCP

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-NOT-ALL-001 | Claude CLI 확인 | claude 미설치 | notion 모듈 실행 | "Claude CLI is required" 에러 | P0 |
| TC-NOT-ALL-002 | Python3 확인 | python3 미설치 | notion 모듈 실행 | "Python 3 is required" 에러 | P0 |
| TC-NOT-ALL-003 | Remote MCP 등록 | 전제조건 충족 | notion 모듈 실행 | `claude mcp add --transport http notion https://mcp.notion.com/mcp` | P0 |
| TC-NOT-ALL-004 | OAuth PKCE 흐름 | MCP 등록 완료 | mcp_oauth_flow 실행 | Notion OAuth 완료, 토큰 저장 | P1 |

#### 4.3.4 GitHub CLI

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-GIT-MAC-001 | gh 설치 (macOS) | Homebrew 존재, gh 미설치 | github 모듈 실행 | `brew install gh` | P0 |
| TC-GIT-LNX-001 | gh 설치 (Ubuntu) | apt 사용 가능, gh 미설치 | github 모듈 실행 | GPG 키 추가 + apt 설치 | P0 |
| TC-GIT-LNX-002 | gh 설치 (Fedora) | dnf 사용 가능, gh 미설치 | github 모듈 실행 | `sudo dnf install gh -y` | P1 |
| TC-GIT-ALL-001 | gh 인증 | gh 설치됨, 미인증 | github 모듈 실행 | `gh auth login --hostname github.com --git-protocol https --web` | P0 |
| TC-GIT-ALL-002 | gh 이미 인증됨 | gh auth status 성공 | github 모듈 실행 | "Already logged in." 메시지, 인증 건너뜀 | P1 |
| TC-GIT-ALL-003 | gh 인증 실패 | 인증 취소 | github 모듈 실행 | "Authentication failed" 에러, exit 1 | P1 |
| TC-GIT-ALL-004 | MCP 미설정 확인 | 설치 완료 | MCP config 확인 | MCP 설정 없음 (gh는 Bash tool로 직접 사용) | P2 |

#### 4.3.5 Pencil

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-PEN-ALL-001 | IDE 미감지 | VS Code/Cursor 모두 미설치 | pencil 모듈 실행 | "VS Code or Cursor is required" 에러, exit 1 | P0 |
| TC-PEN-ALL-002 | VS Code 확장 설치 | VS Code 설치됨 | pencil 모듈 실행 | `code --install-extension highagency.pencildev` | P0 |
| TC-PEN-ALL-003 | Cursor 확장 설치 | Cursor 설치됨 | pencil 모듈 실행 | `cursor --install-extension highagency.pencildev` | P1 |
| TC-PEN-ALL-004 | 두 IDE 모두 설치 | VS Code + Cursor | pencil 모듈 실행 | 양쪽 모두에 확장 설치 | P2 |
| TC-PEN-MAC-001 | 데스크톱 앱 안내 | macOS | pencil 모듈 실행 | "Download from: https://www.pencil.dev/downloads" 안내 | P3 |

---

## 5. 사용자 시나리오 테스트

### 5.1 신규 설치 시나리오

| ID | 시나리오 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|---------|---------|------------|-----------|---------|
| TC-E2E-MAC-001 | macOS 클린 설치 전체 | macOS Sonoma, 개발 도구 없음 | 1. `curl -sSL .../install.sh \| bash -s -- --all` 실행 2. 각 모듈 프롬프트에 응답 3. Google OAuth 완료 4. Atlassian 자격증명 입력 | Homebrew -> Node.js -> Git -> VS Code -> Docker -> Claude -> bkit -> 모든 모듈 순서대로 설치, ~/.claude/mcp.json에 서버 등록 | P0 |
| TC-E2E-WIN-001 | Windows 클린 설치 전체 | Windows 11, 개발 도구 없음 | 1. PowerShell에서 install.ps1 원격 실행 (Step 1: -installDocker) 2. Docker Desktop 시작 3. install.ps1 재실행 (Step 2: -modules "google" -skipBase) | UAC 프롬프트 -> Node.js, Git, VS Code, WSL2, Docker 설치 -> Docker 시작 후 Google MCP 설치 | P0 |
| TC-E2E-LNX-001 | Ubuntu 클린 설치 전체 | Ubuntu 24.04, 최소 설치 | 1. `curl -sSL .../install.sh \| bash -s -- --all` 실행 2. sudo 비밀번호 입력 3. 각 모듈 프롬프트 응답 | NodeSource -> Node.js -> Git -> VS Code(snap) -> Docker -> Claude -> bkit -> 모듈 설치 | P0 |
| TC-E2E-WSL-001 | WSL2 클린 설치 | WSL2 Ubuntu, 최소 설치 | 1. install.sh 로컬 실행 2. 브라우저 열기 시 Windows 브라우저 사용 확인 | cmd.exe/powershell.exe로 브라우저 열기, Docker는 Windows 호스트 Docker 사용 | P1 |

### 5.2 업데이트/추가 설치 시나리오

| ID | 시나리오 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|---------|---------|------------|-----------|---------|
| TC-E2E-ALL-010 | 모듈 추가 설치 | Base + Google 설치됨 | `./install.sh --modules "atlassian,github" --skip-base` | Base 건너뜀, Atlassian과 GitHub만 설치, 기존 MCP 설정 유지 | P0 |
| TC-E2E-ALL-011 | 이미 설치된 모듈 재설치 | Google 모듈 설치됨 | `./install.sh --modules "google" --skip-base` | Docker 이미지 재pull, MCP 설정 덮어쓰기, OAuth 재인증 | P1 |
| TC-E2E-ALL-012 | Base 도구 업데이트 | 이전 Node.js 버전 | `./install.sh --modules "google"` (Base 자동 스킵 안됨) | Node.js 버전 업데이트, 기존 모듈 영향 없음 | P2 |

### 5.3 마이그레이션 시나리오

| ID | 시나리오 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|---------|---------|------------|-----------|---------|
| TC-E2E-ALL-020 | 레거시 MCP 설정 마이그레이션 | ~/.mcp.json 존재, ~/.claude/mcp.json 없음 | 모듈 설치 실행 | ~/.mcp.json을 ~/.claude/mcp.json으로 복사, 이후 새 경로 사용 | P0 |
| TC-E2E-ALL-021 | 양쪽 설정 모두 존재 | ~/.mcp.json과 ~/.claude/mcp.json 모두 존재 | 모듈 설치 실행 | ~/.claude/mcp.json만 사용, 레거시 파일 무시 | P1 |
| TC-E2E-WIN-020 | Windows MCP 경로 마이그레이션 | %USERPROFILE%\.mcp.json 존재 | install.ps1 실행 | %USERPROFILE%\.claude\mcp.json으로 마이그레이션 | P1 |

### 5.4 오류 복구 시나리오

| ID | 시나리오 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|---------|---------|------------|-----------|---------|
| TC-E2E-ALL-030 | 네트워크 단절 시 설치 | 인터넷 끊김 | install.sh 원격 실행 시도 | curl 실패, 적절한 에러 메시지 | P1 |
| TC-E2E-ALL-031 | Docker 이미지 Pull 실패 | Docker 실행 중, ghcr.io 접근 불가 | Google 모듈 실행 | docker pull 실패 에러, 설치 중단 | P1 |
| TC-E2E-ALL-032 | OAuth 타임아웃 | Google 모듈 실행, 로그인 미완료 | 5분 대기 | "Auth timed out after 300s" 메시지, 컨테이너 정리 | P1 |
| TC-E2E-ALL-033 | 모듈 실패 후 재시도 | 이전 설치에서 Google 모듈 실패 | 동일 명령어 재실행 | 백업에서 MCP 설정 복원 후 재설치 성공 | P0 |
| TC-E2E-ALL-034 | 부분 설치 상태 복구 | 3개 모듈 중 2번째에서 실패 | 3번째 모듈부터 재시도 | `--skip-base --modules "third_module"` 으로 이어서 가능 | P1 |
| TC-E2E-ALL-035 | client_secret.json 미제공 | Google 모듈 실행, 파일 없음 | client_secret.json 프롬프트에서 Enter | "client_secret.json not found" 에러, exit 1 | P1 |
| TC-E2E-ALL-036 | 포트 충돌 | OAuth 포트(3000) 사용 중 | Google 모듈 OAuth 실행 | 동적 포트 할당으로 충돌 회피 (python3 socket.bind) | P1 |

### 5.5 일상 업무 시나리오

| ID | 시나리오 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|---------|---------|------------|-----------|---------|
| TC-E2E-ALL-040 | 이메일 검색 및 읽기 | MCP 서버 실행 중 | 1. gmail_search "from:boss" 2. gmail_read (첫 번째 결과 ID) | 이메일 목록 표시 -> 본문 내용 표시 | P0 |
| TC-E2E-ALL-041 | 이메일 작성 및 발송 | MCP 서버 실행 중 | 1. gmail_send (to, subject, body) 2. gmail_search로 확인 | 이메일 발송 완료, 보낸 편지함에서 확인 | P0 |
| TC-E2E-ALL-042 | 일정 생성 및 조회 | MCP 서버 실행 중 | 1. calendar_create_event (title, time) 2. calendar_list_events | 이벤트 생성 -> 목록에서 확인 | P0 |
| TC-E2E-ALL-043 | 파일 검색 및 공유 | MCP 서버 실행 중, Drive 파일 존재 | 1. drive_search "보고서" 2. drive_share (email, role) | 파일 검색 -> 공유 설정 완료 | P0 |
| TC-E2E-ALL-044 | 문서 생성 및 편집 | MCP 서버 실행 중 | 1. docs_create (title, content) 2. docs_append 3. docs_read | 문서 생성 -> 내용 추가 -> 전체 내용 확인 | P1 |
| TC-E2E-ALL-045 | 스프레드시트 데이터 입력 | MCP 서버 실행 중 | 1. sheets_create 2. sheets_write 3. sheets_read | 시트 생성 -> 데이터 입력 -> 읽기 확인 | P1 |
| TC-E2E-ALL-046 | 프레젠테이션 제작 | MCP 서버 실행 중 | 1. slides_create 2. slides_add_slide (x3) 3. slides_read | 프레젠테이션 생성 -> 슬라이드 추가 -> 내용 확인 | P1 |
| TC-E2E-ALL-047 | 복합 워크플로 | MCP 서버 실행 중 | 1. gmail_search 2. docs_create (이메일 내용 기반) 3. drive_share | 이메일 -> 문서화 -> 공유 파이프라인 | P2 |

### 5.6 고급 사용 시나리오

| ID | 시나리오 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|---------|---------|------------|-----------|---------|
| TC-E2E-ALL-050 | 스코프 제한 사용 | GOOGLE_SCOPES="gmail,calendar" 설정 | MCP 서버 시작 후 drive_search 호출 | Drive API 권한 부족 에러 | P2 |
| TC-E2E-ALL-051 | 타임존 변경 사용 | TIMEZONE="UTC" 설정 | calendar_create_event 호출 | UTC 기준 시간으로 이벤트 생성 | P2 |
| TC-E2E-ALL-052 | Docker 볼륨 영속성 | 컨테이너 재시작 | 1. OAuth 인증 2. 컨테이너 중지/재시작 3. API 호출 | token.json이 볼륨에 유지, 재인증 불필요 | P1 |
| TC-E2E-ALL-053 | 동시 MCP 세션 | 2개 Claude 세션 | 동시에 Gmail API 호출 | 뮤텍스로 인증 충돌 방지, 양쪽 모두 정상 응답 | P2 |

---

## 6. 크로스 플랫폼 호환성 테스트

### 6.1 OS 버전별 호환성 매트릭스

#### 6.1.1 인스톨러 호환성

| 기능 | macOS 13 | macOS 14 | macOS 15 | Win10 21H2 | Win10 22H2 | Win11 23H2 | Ubuntu 22.04 | Ubuntu 24.04 | Fedora 39 | Arch |
|------|:--------:|:--------:|:--------:|:----------:|:----------:|:----------:|:------------:|:------------:|:---------:|:----:|
| Base 모듈 | O | O | O | O | O | O | O | O | O | O |
| Google 모듈 | O* | O | O | O | O | O | O | O | O | O |
| Atlassian (Docker) | O* | O | O | O | O | O | O | O | O | O |
| Atlassian (Rovo) | O | O | O | O | O | O | O | O | O | O |
| Figma 모듈 | O | O | O | - | - | - | O | O | O | O |
| Notion 모듈 | O | O | O | - | - | - | O | O | O | O |
| GitHub 모듈 | O | O | O | - | - | - | O | O | O | - |
| Pencil 모듈 | O | O | O | - | - | - | O | O | - | - |

*O = 지원, O* = Docker Desktop 버전 주의 (4.41 이하 권장), - = Windows PowerShell 버전 없음 (Bash 전용)*

#### 6.1.2 MCP 서버 호환성 (Docker 기반)

| 기능 | Docker Desktop macOS | Docker Desktop Win (WSL2) | Docker Engine Linux |
|------|:-------------------:|:------------------------:|:------------------:|
| 이미지 빌드 | O | O | O |
| 컨테이너 실행 | O | O | O |
| 볼륨 마운트 | O | O | O |
| 포트 매핑 | O | O | O |
| HEALTHCHECK | O | O | O |
| non-root 사용자 | O | O | O |
| stdio 통신 | O | O | O |

### 6.2 패키지 관리자별 테스트

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SHR-ALL-001 | pkg_detect_manager: brew | macOS | pkg_detect_manager() 호출 | "brew" 반환 | P1 |
| TC-SHR-ALL-002 | pkg_detect_manager: apt | Ubuntu/Debian | pkg_detect_manager() 호출 | "apt" 반환 | P1 |
| TC-SHR-ALL-003 | pkg_detect_manager: dnf | Fedora/RHEL | pkg_detect_manager() 호출 | "dnf" 반환 | P1 |
| TC-SHR-ALL-004 | pkg_detect_manager: yum | CentOS | pkg_detect_manager() 호출 | "yum" 반환 | P2 |
| TC-SHR-ALL-005 | pkg_detect_manager: pacman | Arch | pkg_detect_manager() 호출 | "pacman" 반환 | P2 |
| TC-SHR-ALL-006 | pkg_detect_manager: none | 미지원 OS | pkg_detect_manager() 호출 | "none" 반환 | P3 |
| TC-SHR-ALL-007 | pkg_install: brew | macOS | pkg_install "jq" | `brew install jq` 실행 | P1 |
| TC-SHR-ALL-008 | pkg_install: apt | Ubuntu | pkg_install "jq" | `sudo apt-get install -y jq` 실행 | P1 |
| TC-SHR-ALL-009 | pkg_ensure_installed: 이미 설치 | jq 설치됨 | pkg_ensure_installed "jq" | "jq is already installed" 메시지 | P2 |
| TC-SHR-ALL-010 | pkg_install_cask: macOS | macOS | pkg_install_cask "docker" | `brew install --cask docker` | P2 |

### 6.3 쉘 환경별 테스트

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SHR-ALL-020 | Bash 4.x 호환 | Bash 4.x | install.sh 실행 | declare -a 배열 정상 동작 | P1 |
| TC-SHR-ALL-021 | Bash 5.x 호환 | Bash 5.x | install.sh 실행 | 전체 기능 정상 | P0 |
| TC-SHR-ALL-022 | Zsh 호환 | macOS 기본 Zsh | source install.sh | 주의: install.sh는 #!/bin/bash 명시, 직접 실행 시 bash 사용 | P2 |
| TC-SHR-WIN-001 | PowerShell 5.1 호환 | Windows 10 기본 | install.ps1 실행 | ConvertFrom-Json, irm 정상 동작 | P0 |
| TC-SHR-WIN-002 | PowerShell 7.x 호환 | PS7 설치됨 | install.ps1 실행 | 전체 기능 정상 | P1 |
| TC-SHR-WIN-003 | ExecutionPolicy Restricted | 기본 정책 | install.ps1 실행 시도 | 실행 차단, Bypass 안내 필요 | P1 |

### 6.4 Docker Desktop 호환성

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-DOK-ALL-001 | Docker Desktop 4.41 + macOS 13 | Ventura + DD 4.41 | docker_check_compatibility() 호출 | 경고 없이 통과 | P1 |
| TC-DOK-ALL-002 | Docker Desktop 4.42+ + macOS 13 | Ventura + DD 4.42+ | docker_check_compatibility() 호출 | "Docker Desktop may not support macOS" 경고 | P1 |
| TC-DOK-ALL-003 | Docker Desktop 4.42+ + macOS 14+ | Sonoma + DD 4.42+ | docker_check_compatibility() 호출 | 경고 없이 통과 | P0 |
| TC-DOK-ALL-004 | Docker 미설치 상태 진단 | Docker 없음 | docker_get_status() 호출 | "not_installed" 반환 | P1 |
| TC-DOK-ALL-005 | Docker 미실행 상태 진단 | Docker 있음 + 미실행 | docker_get_status() 호출 | "not_running" 반환 | P1 |
| TC-DOK-ALL-006 | Docker 실행 대기 | Docker 시작 중 | docker_wait_for_start 60 | 60초 내 docker info 성공 시 return 0 | P2 |
| TC-DOK-ALL-007 | 컨테이너 정리 | 이전 Google MCP 컨테이너 실행 중 | docker_cleanup_container 호출 | 기존 컨테이너 stop + rm | P2 |

---

## 7. 보안 테스트

### 7.1 OWASP Top 10 검증

#### 7.1.1 A01: Broken Access Control

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-001 | 토큰 파일 권한 | token.json 존재 | `stat -c %a token.json` (Linux) 또는 `stat -f %Lp` (macOS) | 파일 권한 0600 (소유자만 읽기/쓰기) | P0 |
| TC-SEC-ALL-002 | 설정 디렉토리 권한 | .google-workspace/ 존재 | 디렉토리 권한 확인 | 디렉토리 권한 0700 (소유자만 접근) | P0 |
| TC-SEC-ALL-003 | MCP 설정 파일 권한 | ~/.claude/mcp.json 존재 | 파일 권한 확인 | 파일 권한 0600 | P0 |
| TC-SEC-ALL-004 | Atlassian 자격증명 파일 권한 | ~/.atlassian-mcp/ 존재 | 파일/디렉토리 권한 확인 | 디렉토리 700, credentials.env 600 | P0 |
| TC-SEC-ALL-005 | Docker non-root 실행 | Google MCP 컨테이너 | `docker exec <id> id -u` | UID != 0 (non-root mcp 사용자) | P0 |
| TC-SEC-ALL-006 | 권한 자동 복구 | token.json 권한 0644로 변경 | saveToken() 호출 | chmodSync로 0600 복원, security event 로그 | P1 |

#### 7.1.2 A02: Cryptographic Failures

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-010 | OAuth state 엔트로피 | - | state 생성 반복 (100회) | 32바이트 (64 hex chars) 랜덤, 충돌 없음 | P0 |
| TC-SEC-ALL-011 | PKCE code_verifier 엔트로피 | - | code_verifier 생성 | openssl rand -base64 32, base64url 인코딩 | P1 |
| TC-SEC-ALL-012 | PKCE code_challenge | code_verifier 존재 | SHA-256 해시 검증 | S256 방식 정확히 구현 | P1 |
| TC-SEC-ALL-013 | SHA-256 체크섬 무결성 | 원격 설치 | 정상 파일 다운로드 후 검증 | shasum/sha256sum 일치 | P0 |
| TC-SEC-ALL-014 | SHA-256 변조 감지 | 원격 설치 | 파일 1바이트 변조 | "[SECURITY] Integrity verification failed!" | P0 |

#### 7.1.3 A03: Injection

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-020 | Drive 쿼리 인젝션 방지 | 인증 완료 | drive_search query="' OR 1=1 --" | escapeDriveQuery()로 `'` 이스케이프, 쿼리 인젝션 실패 | P0 |
| TC-SEC-ALL-021 | Drive 쿼리 백슬래시 이스케이프 | 인증 완료 | drive_search query="test\\injection" | 백슬래시 이중 이스케이프 | P1 |
| TC-SEC-ALL-022 | Drive ID 인젝션 방지 | 인증 완료 | drive_list folderId="1234' OR name='hack" | validateDriveId()로 [a-zA-Z0-9_-] 패턴 불일치, 에러 | P0 |
| TC-SEC-ALL-023 | Gmail 헤더 인젝션 방지 | 인증 완료 | gmail_send to="a@b.com\r\nBcc: spy@c.com" | sanitizeEmailHeader()로 CR/LF 제거 | P0 |
| TC-SEC-ALL-024 | JSON 파싱 인젝션 방지 | 원격 설치 | module.json에 쉘 메타문자 포함 | stdin 기반 파싱으로 쉘 interpolation 방지 | P0 |
| TC-SEC-ALL-025 | Atlassian 자격증명 인젝션 방지 | Docker 모드 | API 토큰에 쉘 특수문자 포함 | --env-file 방식으로 쉘 확장 없이 전달 | P0 |

#### 7.1.4 A04: Insecure Design (해당 없음 - 설계 수준 검증)

해당 항목은 설계 문서 리뷰 단계에서 검증되었으며, 코드 수준 테스트에서는 다루지 않는다.

#### 7.1.5 A05: Security Misconfiguration

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-030 | npm ci (결정적 빌드) | Dockerfile | Docker 빌드 | `npm ci` 사용 (npm install 아님) | P1 |
| TC-SEC-ALL-031 | production 의존성만 | Dockerfile 프로덕션 스테이지 | 이미지 검사 | `npm ci --omit=dev`, devDependencies 미포함 | P1 |
| TC-SEC-ALL-032 | NODE_ENV=production | 프로덕션 이미지 | 환경변수 확인 | NODE_ENV=production 설정됨 | P1 |

#### 7.1.6 A06: Vulnerable Components

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-040 | npm audit | google-workspace-mcp/ | `npm audit --audit-level=high` | high/critical 취약점 0건 | P0 |
| TC-SEC-ALL-041 | Node.js 22 사용 | Dockerfile 확인 | `FROM node:22-slim` 확인 | Node.js 20 EOL(2026-04-30) 전 마이그레이션 완료 | P1 |
| TC-SEC-ALL-042 | 의존성 버전 고정 | package.json | 주요 의존성 확인 | @modelcontextprotocol/sdk ^1.0, googleapis ^140.0, zod ^3.22 | P2 |

#### 7.1.7 A07: Authentication Failures

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-050 | refresh_token 필수 검증 | token.json에 refresh_token 없음 | loadToken() 호출 | null 반환, 재인증 유도 | P0 |
| TC-SEC-ALL-051 | 토큰 만료 버퍼 | expiry_date가 현재+3분 | getAuthenticatedClient() | 5분 버퍼로 사전 갱신 | P1 |
| TC-SEC-ALL-052 | access_type=offline | OAuth URL 생성 | authUrl 확인 | access_type=offline, prompt=consent 포함 | P1 |

#### 7.1.8 A08: Software and Data Integrity

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-060 | checksums.json 무결성 | CI 환경 | `generate-checksums.sh` 재실행 후 diff | checksums.json과 일치 | P0 |
| TC-SEC-ALL-061 | 원격 스크립트 검증 | 원격 설치 | download_and_verify로 모든 파일 검증 | 모든 파일 SHA-256 일치 | P0 |

### 7.2 인증/인가 테스트

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-070 | OAuth CSRF 방지 | OAuth 흐름 중 | 잘못된 state로 콜백 | 403 응답, "CSRF attack" 로그 | P0 |
| TC-SEC-ALL-071 | PKCE 코드 교환 | OAuth 흐름 중 | code_verifier 없이 토큰 교환 | 토큰 교환 실패 | P1 |
| TC-SEC-ALL-072 | 동시 인증 뮤텍스 | - | 동시에 3회 getAuthenticatedClient() | 첫 번째만 실제 실행, 나머지는 대기 | P1 |
| TC-SEC-ALL-073 | 보안 이벤트 로그 형식 | 인증 이벤트 발생 | stderr 출력 확인 | `[SECURITY] {"timestamp":"...","event_type":"...","result":"..."}` | P2 |

### 7.3 입력 검증 테스트

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-080 | escapeDriveQuery: 작은따옴표 | - | escapeDriveQuery("test's") | "test\\'s" 반환 | P0 |
| TC-SEC-ALL-081 | escapeDriveQuery: 백슬래시 | - | escapeDriveQuery("test\\path") | "test\\\\path" 반환 | P0 |
| TC-SEC-ALL-082 | validateDriveId: 정상 ID | - | validateDriveId("abc123_-XYZ") | 에러 없음 | P0 |
| TC-SEC-ALL-083 | validateDriveId: "root" 허용 | - | validateDriveId("root") | 에러 없음 | P1 |
| TC-SEC-ALL-084 | validateDriveId: 특수문자 | - | validateDriveId("id!@#$%") | 에러 발생 | P0 |
| TC-SEC-ALL-085 | sanitizeEmailHeader: CRLF | - | sanitizeEmailHeader("a@b.com\r\nBcc: spy") | "a@b.comBcc: spy" (개행 제거) | P0 |
| TC-SEC-ALL-086 | validateEmail: 정상 | - | validateEmail("user@example.com") | true | P1 |
| TC-SEC-ALL-087 | validateEmail: 길이 초과 | - | validateEmail("a".repeat(255) + "@b.com") | false (254자 초과) | P2 |
| TC-SEC-ALL-088 | sanitizeFilename: 경로 순회 | - | sanitizeFilename("../../../etc/passwd") | "_.._.._.._etc_passwd" (위험 문자 치환) | P1 |
| TC-SEC-ALL-089 | sanitizeFilename: 널 바이트 | - | sanitizeFilename("file\x00.txt") | "file_.txt" (제어문자 치환) | P1 |
| TC-SEC-ALL-090 | sanitizeRange: 정상 A1 표기 | - | sanitizeRange("Sheet1!A1:B10") | "Sheet1!A1:B10" 반환 | P1 |
| TC-SEC-ALL-091 | sanitizeRange: 비정상 입력 | - | sanitizeRange("DROP TABLE users;") | null 반환 | P1 |
| TC-SEC-ALL-092 | validateMaxLength | - | validateMaxLength("a".repeat(1000), 500) | 500자로 자르기 | P2 |

### 7.4 파일 시스템 보안 테스트

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-100 | 설정 디렉토리 자동 생성 | CONFIG_DIR 없음 | ensureConfigDir() | 0700 권한으로 생성 | P0 |
| TC-SEC-ALL-101 | 설정 디렉토리 권한 자동 복구 | CONFIG_DIR 권한 0755 | ensureConfigDir() | 0700으로 복구 + security event | P0 |
| TC-SEC-ALL-102 | 토큰 파일 저장 권한 | - | saveToken() | 0600 권한으로 저장 + 방어적 chmodSync | P0 |
| TC-SEC-ALL-103 | Windows 권한 처리 | Windows 환경 | ensureConfigDir() / saveToken() | chmodSync 실패 시 정상 처리 (try-catch, Windows ACL 의존) | P1 |
| TC-SEC-ALL-104 | 임시 파일 정리 | 원격 설치 | EXIT trap 발동 | SHARED_TMP, 다운로드 임시 파일 모두 삭제 | P1 |
| TC-SEC-ALL-105 | 체크섬 실패 시 임시 파일 삭제 | 원격 설치 | SHA-256 불일치 | tmpfile 즉시 삭제 (`rm -f "$tmpfile"`) | P0 |

### 7.5 네트워크 보안 테스트

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-SEC-ALL-110 | HTTPS 전용 통신 | 인터넷 연결 | 모든 외부 API 호출 모니터링 | googleapis.com, github.com 등 HTTPS만 사용 | P0 |
| TC-SEC-ALL-111 | OAuth 콜백 로컬 전용 | OAuth 흐름 중 | 콜백 서버 바인딩 확인 | localhost (127.0.0.1)에서만 수신 | P0 |
| TC-SEC-ALL-112 | Docker 네트워크 격리 | 컨테이너 실행 중 | `docker run -i --rm` 옵션 | --rm으로 종료 시 자동 삭제, 불필요한 포트 미노출 | P1 |
| TC-SEC-ALL-113 | curl 무결성 | 원격 설치 | curl 옵션 확인 | -sSL 사용 (silent, SSL 필수, 리다이렉트 따라감) | P1 |

---

## 8. 성능/안정성 테스트

### 8.1 Rate Limiting 테스트

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-PER-ALL-001 | withRetry: 429 재시도 | - | 429 응답을 반환하는 모의 함수 | 3회까지 재시도, 지수 백오프 (1s -> 2s -> 4s) | P0 |
| TC-PER-ALL-002 | withRetry: 500 재시도 | - | 500 응답을 반환하는 모의 함수 | 3회까지 재시도 | P0 |
| TC-PER-ALL-003 | withRetry: 502/503/504 재시도 | - | 각 상태 코드 모의 | 모두 재시도 대상 | P1 |
| TC-PER-ALL-004 | withRetry: 400 미재시도 | - | 400 응답 | 즉시 에러 throw (재시도 없음) | P1 |
| TC-PER-ALL-005 | withRetry: 403 미재시도 | - | 403 응답 | 즉시 에러 throw (재시도 없음) | P1 |
| TC-PER-ALL-006 | withRetry: 네트워크 에러 | - | ECONNRESET 에러 | 재시도 실행 | P1 |
| TC-PER-ALL-007 | withRetry: ETIMEDOUT | - | ETIMEDOUT 에러 | 재시도 실행 | P1 |
| TC-PER-ALL-008 | withRetry: ECONNREFUSED | - | ECONNREFUSED 에러 | 재시도 실행 | P2 |
| TC-PER-ALL-009 | withRetry: 최대 지연 제한 | - | maxDelay=10000 설정 | 지연이 10000ms를 초과하지 않음 | P2 |
| TC-PER-ALL-010 | withRetry: 커스텀 옵션 | - | maxAttempts=5, initialDelay=500 | 5회 재시도, 500ms 시작 | P2 |
| TC-PER-ALL-011 | withRetry: 첫 시도 성공 | - | 정상 응답 | 재시도 없이 즉시 반환 | P0 |

### 8.2 대량 데이터 처리 테스트

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-PER-ALL-020 | gmail_search: 대량 결과 | 수백 개 이메일 | maxResults=100 검색 | 상위 10개만 상세 조회 (Promise.all), 메모리 안정 | P1 |
| TC-PER-ALL-021 | drive_search: 대량 파일 | 수천 개 파일 | maxResults=50 검색 | pageSize 제한 동작 확인 | P1 |
| TC-PER-ALL-022 | gmail_read: 큰 첨부파일 | 10MB+ 첨부파일 이메일 | messageId로 읽기 | body 5000자 truncate, 첨부파일 메타데이터만 반환 | P2 |
| TC-PER-ALL-023 | gmail_attachment_get: 대용량 | 25MB 첨부파일 | attachmentId로 다운로드 | base64 인코딩 데이터 정상 반환 | P2 |
| TC-PER-ALL-024 | docs_read: 긴 문서 | 10000자+ 문서 | documentId로 읽기 | content 10000자로 truncate | P2 |
| TC-PER-ALL-025 | sheets_write: 대량 셀 | 1000행 x 26열 데이터 | values 배열 전송 | USER_ENTERED 모드로 모든 셀 업데이트 | P2 |

### 8.3 동시성 테스트

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-PER-ALL-030 | 동시 인증 뮤텍스 | 인증 미완료 | getAuthenticatedClient() 3회 동시 호출 | authInProgress Promise 공유, 인증 1회만 실행 | P0 |
| TC-PER-ALL-031 | 뮤텍스 해제 | 인증 완료 | authInProgress 확인 | null로 리셋, 다음 호출 시 새 인증 가능 | P1 |
| TC-PER-ALL-032 | 서비스 캐시 동시 접근 | 캐시 만료 직전 | getGoogleServices() 동시 호출 | 하나만 서비스 생성, 나머지는 캐시 사용 | P2 |
| TC-PER-ALL-033 | 동시 API 호출 | 인증 완료 | gmail_search + drive_search 동시 | 각각 독립적으로 withRetry 동작, 간섭 없음 | P1 |

### 8.4 장시간 운영 테스트

| ID | 테스트 케이스 | 전제조건 | 테스트 절차 | 기대 결과 | 우선순위 |
|----|-------------|---------|------------|-----------|---------|
| TC-PER-ALL-040 | 50분 캐시 갱신 | 서비스 캐시 활성 | 50분 경과 후 API 호출 | 캐시 만료 -> 새 서비스 인스턴스 생성 -> 정상 응답 | P1 |
| TC-PER-ALL-041 | 토큰 자동 갱신 | access_token 만료 예정 | 장시간 후 API 호출 | 5분 버퍼로 자동 refresh, 서비스 중단 없음 | P0 |
| TC-PER-ALL-042 | refresh_token 만료 | refresh_token 무효화 | 장시간 후 API 호출 | 자동 재인증 흐름 (브라우저 OAuth) | P1 |
| TC-PER-ALL-043 | 메모리 누수 검증 | MCP 서버 장시간 실행 | 24시간 주기적 API 호출 | RSS 메모리 안정적 유지 (500MB 이하) | P2 |
| TC-PER-ALL-044 | Docker 컨테이너 안정성 | Docker 기반 실행 | 24시간 운영 | 컨테이너 HEALTHCHECK 통과, OOM 없음 | P2 |

---

## 9. 회귀 테스트

### 9.1 자동화 테스트 (CI)

#### 9.1.1 현재 CI 파이프라인 (`ci.yml`)

| CI Job | 실행 환경 | 테스트 내용 | 대응 테스트 케이스 |
|--------|----------|------------|-------------------|
| `lint` | ubuntu-latest, Node.js 22 | ESLint + Prettier 검증 | TC-REG-ALL-001 |
| `build` | ubuntu-latest, Node.js 22 | TypeScript 컴파일 | TC-REG-ALL-002 |
| `test` | ubuntu-latest, Node.js 22 | vitest 전체 실행 + 커버리지 | TC-REG-ALL-003 |
| `smoke-tests` | ubuntu-latest, macos-latest | module.json 검증 + install.sh 문법 | TC-REG-ALL-004 |
| `security-audit` | ubuntu-latest, Node.js 22 | npm audit --audit-level=high | TC-REG-ALL-005 |
| `shellcheck` | ubuntu-latest | ShellCheck -S warning 전체 | TC-REG-ALL-006 |
| `docker-build` | ubuntu-latest | Docker 이미지 빌드 + non-root 확인 | TC-REG-ALL-007 |
| `verify-checksums` | ubuntu-latest | checksums.json 최신 여부 확인 | TC-REG-ALL-008 |

#### 9.1.2 CI 회귀 테스트 케이스

| ID | 테스트 케이스 | 자동화 | 트리거 | 기대 결과 | 우선순위 |
|----|-------------|--------|--------|-----------|---------|
| TC-REG-ALL-001 | ESLint 규칙 위반 없음 | CI 자동 | push/PR | lint 에러 0건 | P0 |
| TC-REG-ALL-002 | TypeScript 컴파일 성공 | CI 자동 | push/PR | tsc 에러 0건, dist/ 생성 | P0 |
| TC-REG-ALL-003 | vitest 전체 통과 | CI 자동 | push/PR | 6개 테스트 파일 전체 통과 | P0 |
| TC-REG-ALL-004 | module.json 유효성 | CI 자동 | push/PR | 7개 모듈 JSON 파싱 성공, 필수 필드 존재 | P0 |
| TC-REG-ALL-005 | npm 보안 감사 통과 | CI 자동 | push/PR | high/critical 취약점 0건 | P0 |
| TC-REG-ALL-006 | ShellCheck 경고 없음 | CI 자동 | push/PR | installer/ 내 모든 .sh 파일 warning 없음 | P1 |
| TC-REG-ALL-007 | Docker 이미지 빌드 성공 | CI 자동 | push/PR | 이미지 빌드 + `node -e "console.log('OK')"` 성공 + UID 1001 확인 | P0 |
| TC-REG-ALL-008 | checksums.json 최신 | CI 자동 | push/PR | generate-checksums.sh 재실행 결과와 일치 | P0 |
| TC-REG-ALL-009 | install.sh 문법 검증 | CI 자동 | push/PR | bash -n 통과 (macOS + Ubuntu) | P1 |
| TC-REG-ALL-010 | 모듈 실행 순서 검증 | CI 자동 | push/PR | order 필드 기준 정렬 확인 | P2 |

#### 9.1.3 수동 CI 워크플로 (`test-installer.yml`)

| 트리거 | 입력 | 실행 내용 |
|--------|------|----------|
| workflow_dispatch | os: all/windows/macos | Windows/macOS 실제 설치 테스트 |
| workflow_dispatch | module: base/github/notion/figma | 특정 모듈 설치 테스트 |

### 9.2 수동 회귀 체크리스트

릴리스 전 수동으로 확인해야 하는 항목이다.

#### 9.2.1 인스톨러 회귀

- [ ] macOS (Sonoma): `./install.sh --all` 전체 설치 성공
- [ ] macOS: `./install.sh --list` 7개 모듈 표시
- [ ] macOS: `./install.sh --modules "google" --skip-base` 단독 실행 성공
- [ ] macOS: Docker 미실행 시 경고 + 대기 동작
- [ ] macOS: 모듈 실패 시 MCP 설정 롤백 동작
- [ ] Windows: `.\install.ps1 -all` 전체 설치 성공
- [ ] Windows: UAC 관리자 권한 상승 동작
- [ ] Windows: `-list` 목록 표시 (관리자 불필요)
- [ ] Linux (Ubuntu): 클린 설치 전체 모듈 성공
- [ ] Linux (Fedora): dnf 기반 설치 성공

#### 9.2.2 MCP 서버 회귀

- [ ] OAuth 최초 인증 흐름 (브라우저 -> 콜백 -> 토큰 저장)
- [ ] 토큰 자동 갱신 (만료 5분 전)
- [ ] gmail_search + gmail_read 연쇄 호출
- [ ] gmail_send 이메일 발송 (UTF-8 제목)
- [ ] drive_search + drive_share 연쇄 호출
- [ ] calendar_create_event (동적 타임존)
- [ ] docs_create + docs_append + docs_read
- [ ] sheets_create + sheets_write + sheets_read
- [ ] slides_create + slides_add_slide

#### 9.2.3 보안 회귀

- [ ] token.json 파일 권한 0600
- [ ] .google-workspace/ 디렉토리 권한 0700
- [ ] MCP 설정 파일 권한 0600
- [ ] Atlassian credentials.env 권한 600
- [ ] Docker 컨테이너 non-root 실행
- [ ] Drive 쿼리 이스케이프 동작
- [ ] Gmail 헤더 인젝션 방지 동작

---

## 10. 테스트 실행 계획

### 10.1 우선순위별 실행 순서

#### Phase 1: P0 Critical (릴리스 차단)

**목표**: 핵심 기능 동작 확인, 보안 취약점 0건

| 순서 | 영역 | 테스트 수 | 예상 소요 |
|------|------|----------|----------|
| 1 | CI 자동화 (REG) | 8건 | 자동 (10분) |
| 2 | OAuth 인증 (AUT) | 11건 | 30분 |
| 3 | 보안 핵심 (SEC) | 22건 | 1시간 |
| 4 | 인스톨러 핵심 (INS) | 14건 | 1시간 |
| 5 | Gmail/Drive/Calendar 핵심 (GML,DRV,CAL) | 10건 | 1시간 |
| 6 | E2E 클린 설치 (E2E) | 4건 | 2시간 |

**소계**: 69건, 약 5.5시간

#### Phase 2: P1 High (릴리스 전 권장)

**목표**: 주요 기능 안정성 확인, 크로스 플랫폼 검증

| 순서 | 영역 | 테스트 수 | 예상 소요 |
|------|------|----------|----------|
| 1 | 인스톨러 부가 (INS) | 20건 | 1시간 |
| 2 | MCP 도구 주요 (GML,DRV,CAL,DOC,SHT,SLD) | 35건 | 2시간 |
| 3 | 모듈 기능 (ATL,FIG,NOT,GIT,PEN) | 15건 | 1시간 |
| 4 | 성능/동시성 (PER) | 10건 | 1시간 |
| 5 | 크로스 플랫폼 (SHR,DOK) | 12건 | 1시간 |
| 6 | E2E 시나리오 (E2E) | 8건 | 2시간 |

**소계**: 100건, 약 8시간

#### Phase 3: P2-P3 Medium/Low (다음 릴리스까지 허용)

| 순서 | 영역 | 테스트 수 | 예상 소요 |
|------|------|----------|----------|
| 1 | MCP 도구 부가 | 30건 | 2시간 |
| 2 | 엣지 케이스 | 15건 | 1시간 |
| 3 | 성능 스트레스 | 8건 | 3시간 |
| 4 | 장시간 운영 | 4건 | 24시간 |

**소계**: 57건, 약 30시간

### 10.2 테스트 환경 준비 체크리스트

#### 10.2.1 공통 준비사항

- [ ] Google Cloud 프로젝트 생성 (테스트용)
- [ ] OAuth 클라이언트 ID 발급 (Desktop 타입)
- [ ] client_secret.json 준비
- [ ] 테스트용 Google 계정 (Gmail, Drive, Calendar 데이터 포함)
- [ ] Atlassian 테스트 인스턴스 + API 토큰
- [ ] GitHub 테스트 계정 + PAT
- [ ] Figma 테스트 계정
- [ ] Notion 테스트 워크스페이스

#### 10.2.2 macOS 환경 준비

- [ ] macOS Sonoma 14.x + Apple Silicon VM/물리 머신
- [ ] Homebrew 미설치 클린 사용자 계정
- [ ] Docker Desktop 설치 + 미실행 상태 스냅샷
- [ ] 네트워크 접근 확인 (ghcr.io, raw.githubusercontent.com, googleapis.com)

#### 10.2.3 Windows 환경 준비

- [ ] Windows 11 23H2 VM/물리 머신
- [ ] WSL2 미설치 클린 상태 스냅샷
- [ ] 일반 사용자 계정 + 관리자 계정
- [ ] PowerShell 5.1 환경 + PowerShell 7 환경

#### 10.2.4 Linux 환경 준비

- [ ] Ubuntu 24.04 LTS VM (apt 테스트)
- [ ] Fedora 39+ VM (dnf 테스트)
- [ ] WSL2 Ubuntu 22.04 (Windows 연동 테스트)
- [ ] sudo 가능 사용자 계정

#### 10.2.5 Docker 환경 준비

- [ ] Docker Desktop/Engine 최신 버전
- [ ] ghcr.io 접근 가능 (이미지 pull 테스트)
- [ ] 충분한 디스크 공간 (10GB+)
- [ ] docker 그룹 멤버십 확인 (Linux)

### 10.3 결과 기록 양식

#### 10.3.1 테스트 실행 기록

```markdown
## 테스트 실행 기록

- 실행일: YYYY-MM-DD
- 실행자:
- 환경: (환경 ID)
- 빌드 버전: (git commit hash)

| TC ID | 결과 | 비고 |
|-------|------|------|
| TC-XXX-YYY-NNN | PASS / FAIL / SKIP / BLOCK | 상세 내용 |
```

#### 10.3.2 결함 보고서

```markdown
## 결함 보고서

- 결함 ID: BUG-YYYY-NNNN
- 관련 TC: TC-XXX-YYY-NNN
- 심각도: Critical / Major / Minor / Trivial
- 환경: (환경 ID)
- 발견일: YYYY-MM-DD

### 재현 절차
1. ...
2. ...

### 기대 결과
...

### 실제 결과
...

### 스크린샷/로그
...
```

---

## 부록

### A. 테스트 케이스 전체 목록

#### A.1 테스트 케이스 통계

| 영역 | P0 | P1 | P2 | P3 | 합계 |
|------|:--:|:--:|:--:|:--:|:----:|
| INS (인스톨러) | 14 | 22 | 6 | 2 | 44 |
| AUT (OAuth 인증) | 11 | 9 | 2 | 0 | 22 |
| GML (Gmail) | 3 | 10 | 9 | 0 | 22 |
| DRV (Drive) | 4 | 8 | 8 | 0 | 20 |
| CAL (Calendar) | 3 | 6 | 6 | 0 | 15 |
| DOC (Docs) | 2 | 4 | 7 | 0 | 13 |
| SHT (Sheets) | 3 | 4 | 6 | 1 | 14 |
| SLD (Slides) | 2 | 3 | 6 | 0 | 11 |
| ATL (Atlassian) | 3 | 2 | 2 | 0 | 7 |
| FIG (Figma) | 3 | 3 | 2 | 0 | 8 |
| NOT (Notion) | 3 | 1 | 0 | 0 | 4 |
| GIT (GitHub) | 2 | 3 | 1 | 0 | 6 |
| PEN (Pencil) | 2 | 1 | 1 | 1 | 5 |
| SHR (공유 유틸리티) | 1 | 11 | 6 | 2 | 20 |
| DOK (Docker) | 1 | 4 | 2 | 0 | 7 |
| SEC (보안) | 22 | 12 | 4 | 0 | 38 |
| PER (성능) | 4 | 10 | 11 | 0 | 25 |
| E2E (시나리오) | 5 | 8 | 6 | 0 | 19 |
| REG (회귀) | 6 | 3 | 1 | 0 | 10 |
| **합계** | **94** | **124** | **84** | **6** | **310** |

#### A.2 전체 테스트 케이스 ID 색인

```
TC-INS-MAC-001 ~ TC-INS-MAC-026  (26건)
TC-INS-WIN-001 ~ TC-INS-WIN-016  (16건)
TC-INS-LNX-001 ~ TC-INS-LNX-010  (10건)
TC-AUT-ALL-001 ~ TC-AUT-ALL-022  (22건)
TC-GML-ALL-001 ~ TC-GML-ALL-022  (22건)
TC-DRV-ALL-001 ~ TC-DRV-ALL-020  (20건)
TC-CAL-ALL-001 ~ TC-CAL-ALL-015  (15건)
TC-DOC-ALL-001 ~ TC-DOC-ALL-013  (13건)
TC-SHT-ALL-001 ~ TC-SHT-ALL-014  (14건)
TC-SLD-ALL-001 ~ TC-SLD-ALL-011  (11건)
TC-ATL-ALL-001 ~ TC-ATL-ALL-007  (7건)
TC-FIG-ALL-001 ~ TC-FIG-ALL-008  (8건)
TC-NOT-ALL-001 ~ TC-NOT-ALL-004  (4건)
TC-GIT-MAC-001, TC-GIT-LNX-001 ~ 002, TC-GIT-ALL-001 ~ 004  (6건)
TC-PEN-ALL-001 ~ TC-PEN-ALL-004, TC-PEN-MAC-001  (5건)
TC-SHR-ALL-001 ~ TC-SHR-ALL-010  (10건)
TC-SHR-ALL-020 ~ TC-SHR-ALL-022  (3건)
TC-SHR-WIN-001 ~ TC-SHR-WIN-003  (3건)
TC-DOK-ALL-001 ~ TC-DOK-ALL-007  (7건)
TC-SEC-ALL-001 ~ TC-SEC-ALL-113  (38건)
TC-PER-ALL-001 ~ TC-PER-ALL-044  (25건)
TC-E2E-MAC-001, TC-E2E-WIN-001, TC-E2E-LNX-001, TC-E2E-WSL-001  (4건)
TC-E2E-ALL-010 ~ TC-E2E-ALL-053  (15건)
TC-REG-ALL-001 ~ TC-REG-ALL-010  (10건)
```

### B. OS별 상세 호환성 매트릭스

#### B.1 MCP 도구별 OS 호환성

모든 MCP 도구는 Docker 컨테이너 내에서 실행되므로 OS 독립적이다. 아래는 인스톨러 모듈의 OS별 경로 차이를 정리한 것이다.

| 항목 | macOS | Windows | Linux | WSL2 |
|------|-------|---------|-------|------|
| MCP 설정 경로 | `~/.claude/mcp.json` | `%USERPROFILE%\.claude\mcp.json` | `~/.claude/mcp.json` | `~/.claude/mcp.json` |
| 레거시 MCP 경로 | `~/.mcp.json` | `%USERPROFILE%\.mcp.json` | `~/.mcp.json` | `~/.mcp.json` |
| Google 설정 | `~/.google-workspace/` | `%USERPROFILE%\.google-workspace\` | `~/.google-workspace/` | `~/.google-workspace/` |
| Atlassian 설정 | `~/.atlassian-mcp/` | - (Docker 모드 미지원*) | `~/.atlassian-mcp/` | `~/.atlassian-mcp/` |
| Claude 자격증명 | `~/.claude/.credentials.json` | `%USERPROFILE%\.claude\.credentials.json` | `~/.claude/.credentials.json` | `~/.claude/.credentials.json` |
| Node.js 설치 방법 | Homebrew | winget/직접 설치 | NodeSource | apt (WSL) |
| Docker 실행 방식 | Docker Desktop | Docker Desktop (WSL2 백엔드) | Docker Engine | Windows Docker 공유 |
| 브라우저 열기 | `open` | `Start-Process` | `xdg-open` | `cmd.exe /c start` |
| 패키지 관리자 | brew | winget/choco | apt/dnf/pacman | apt |
| 쉘 | bash (Zsh 기본이나 bash 명시) | PowerShell | bash | bash |

*Windows Atlassian Docker 모드는 install.ps1에 별도 구현 필요

#### B.2 파일 권한 매트릭스

| 파일/디렉토리 | Unix 권한 | Windows 동작 | 코드 위치 |
|---------------|-----------|-------------|-----------|
| `~/.google-workspace/` | 0700 | ACL 상속 | `oauth.ts:117` |
| `token.json` | 0600 | ACL 상속 | `oauth.ts:202-209` |
| `~/.claude/mcp.json` | 0600 | - | `mcp-config.sh:75` |
| `~/.atlassian-mcp/` | 0700 | - | `atlassian/install.sh:141` |
| `credentials.env` | 0600 | - | `atlassian/install.sh:152` |

### C. 테스트 도구 목록

| 도구 | 용도 | 설치 명령 |
|------|------|----------|
| **vitest** | TypeScript 유닛 테스트 (MCP 서버) | `cd google-workspace-mcp && npm ci` |
| **@vitest/coverage-v8** | 코드 커버리지 측정 | 위와 동일 |
| **@vitest/ui** | 테스트 UI 대시보드 | 위와 동일 |
| **ESLint** | TypeScript 정적 분석 | 위와 동일 |
| **Prettier** | 코드 포맷 검증 | 위와 동일 |
| **ShellCheck** | Shell 스크립트 정적 분석 | `sudo apt-get install shellcheck` / `brew install shellcheck` |
| **Docker** | 컨테이너 빌드/실행 테스트 | Docker Desktop / Docker Engine |
| **curl** | HTTP 요청 테스트 | 기본 설치 |
| **jq** | JSON 파싱 (결과 검증용) | `brew install jq` / `apt install jq` |
| **bash -n** | Shell 스크립트 문법 검증 | 기본 설치 |
| **npm audit** | 의존성 보안 감사 | Node.js 기본 포함 |
| **openssl** | SHA-256 해시, PKCE 랜덤 생성 | 기본 설치 |
| **python3** | OAuth PKCE 콜백 서버, JSON 파싱 | 기본 설치 / `brew install python3` |
| **gh** | GitHub Actions 수동 트리거 | `brew install gh` |
| **VM/Container** | 크로스 플랫폼 테스트 환경 | UTM (macOS), Hyper-V (Windows), Docker |

---

*문서 끝*
