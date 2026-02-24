# ADW (AI-Driven Work) 종합 분석 보고서

> PDCA Check Phase | 분석일: 2026-02-12
> 분석팀: CTO Team (8 에이전트 병렬 분석)
> 대상: popup-jacob/popup-claude (master branch, commit 7b16685)

---

## 1. 분석 개요

### 1.1 분석 목적
Anthropic CTO 관점에서 ADW 코드베이스가 "원클릭 설치로 Claude Code CLI + bkit 플러그인 + MCP 환경을 구축하여 AI Native 업무 환경을 달성"하는 목적에 충분한지 평가하고, 보안/권한제어를 포함한 개선사항을 도출한다.

### 1.2 분석 범위
| 영역 | 파일/디렉토리 | 분석 에이전트 |
|------|-------------|-------------|
| 인스톨러 모듈 | `installer/` (install.sh, install.ps1, 7개 모듈) | installer-analyzer |
| Google MCP 서버 | `google-workspace-mcp/` (TypeScript, 71 도구) | google-mcp-analyzer |
| 보안/권한 | 전체 코드베이스 | security-analyzer |
| OS 호환성 | 모듈 요구사항, Docker, Node.js | os-compat-analyzer |
| 외부 MCP 모듈 | Atlassian, Notion, Figma, GitHub, Pencil | external-mcp-analyzer |
| 코드 품질 | 아키텍처, 테스트, CI/CD | quality-analyzer |
| AI Native 달성도 | UX, 온보딩, 확장성 | cto-evaluator |

### 1.3 분석 결과 요약

| 구분 | 점수 | 평가 |
|------|------|------|
| **기능 완성도** | 75/100 | 핵심 기능 구현 완료, 일부 엣지케이스 미처리 |
| **보안** | 55/100 | 다수 High/Critical 취약점 발견 |
| **코드 품질** | 65/100 | 합리적 구조, 테스트/에러핸들링 부족 |
| **OS 호환성** | 70/100 | Windows/Mac 지원, Linux 부분적 |
| **사용자 경험** | 70/100 | 원클릭 달성, 수동 단계 다수 |
| **AI Native 달성도** | 72/100 | 목적 대부분 달성, 엔터프라이즈 미흡 |
| **종합 점수** | **68/100** | 양호 (개선 필요) |

---

## 2. 인스톨러 모듈 구조 분석

### 2.1 아키텍처 평가

**강점:**
- 모듈러 플러그인 아키텍처로 확장성 확보 (module.json 기반)
- 크로스 플랫폼 지원 (Windows PowerShell + Mac/Linux Bash)
- 스마트 상태 감지로 이미 설치된 도구 자동 스킵
- 원격/로컬 실행 모드 자동 전환
- Docker 필요 모듈의 2단계 설치 지원

**발견된 문제:**

| ID | 심각도 | 문제 | 위치 | 설명 |
|----|--------|------|------|------|
| INS-01 | High | JSON 파서 macOS 전용 | `install.sh:29-39` | `osascript -l JavaScript`는 macOS에서만 동작. Linux에서 모듈 로딩 불가 |
| INS-02 | Medium | MCP 설정 경로 불일치 | `install.sh:406` vs `install.ps1:387` | Mac은 `~/.mcp.json`, Windows는 `~/.claude/mcp.json` 사용 |
| INS-03 | Medium | 롤백 메커니즘 부재 | 전체 | 설치 실패 시 부분 설치된 상태로 남음. 복구 불가 |
| INS-04 | Low | 모듈 정렬 미적용 | `install.sh:376` | Mac 버전에서 선택된 모듈이 order 순이 아닌 입력 순으로 실행 |
| INS-05 | Medium | Linux 패키지 관리자 제한 | `base/install.sh:48,91` | apt-get/snap만 지원. Fedora(dnf), Arch(pacman) 미지원 |
| INS-06 | Low | ARCHITECTURE.md 미동기화 | `ARCHITECTURE.md:107-111` | pencil 모듈, shared/ 디렉토리가 ARCHITECTURE.md에 미반영 |
| INS-07 | **High** | Notion/Figma 원격실행 불가 | `notion/install.sh:54`, `figma/install.sh:58` | `source "$SCRIPT_DIR/../shared/oauth-helper.sh"` — 원격 `curl\|bash` 실행 시 oauth-helper.sh 미다운로드로 실패 |
| INS-08 | Medium | Figma module.json 불일치 | `figma/module.json` | `type: "mcp"`, `requirements.node: true` 이지만 실제 구현은 `claude mcp add --transport http` (remote-mcp) |
| INS-09 | Medium | Atlassian module.json Docker 표기 오류 | `atlassian/module.json:15` | `docker: false`이지만 Docker 모드 존재. 메인 인스톨러가 Docker 상태 미표시 |
| INS-10 | Low | Docker wait 무한 대기 | `google/install.sh:315` | `docker wait` 에 타임아웃 없음. 인증 실패 시 무한 대기 가능 |

### 2.2 모듈별 상세 분석

#### Base 모듈 (`installer/modules/base/`)
- 7단계 순차 설치: Homebrew → Node.js → Git → VS Code → Docker → Claude CLI → bkit
- Claude CLI는 네이티브 방식 설치 (`curl -fsSL https://claude.ai/install.sh | bash`)
- bkit 플러그인은 marketplace를 통한 설치: `claude plugin marketplace add`
- **문제**: VS Code 설치 후 `code` CLI가 PATH에 없을 수 있으나 에러 처리 없이 통과

#### Google 모듈 (`installer/modules/google/`)
- Admin/Employee 역할 분리 플로우 구현
- gcloud CLI 자동 설치 + Google Cloud 프로젝트 생성 자동화
- OAuth 동의화면은 수동 단계 (자동화 불가 영역)
- Docker 기반 인증 + .mcp.json 설정 자동화
- **문제**: OAuth 콜백 포트 할당에 python3 의존 (`install.sh:274`)

#### Atlassian 모듈 (`installer/modules/atlassian/`)
- Docker (mcp-atlassian) / Rovo MCP (SSE) 듀얼 모드 지원
- Docker 유무에 따라 추천 방식 자동 전환
- **문제**: API 토큰이 .mcp.json에 평문 저장됨 (보안 위험)
- **문제**: module.json에 `docker: false`로 표기되어 있으나 Docker 모드 존재

---

## 3. Google Workspace MCP 서버 분석

### 3.1 구현 현황

| 서비스 | 도구 수 | 구현 상태 | 비고 |
|--------|---------|----------|------|
| Gmail | 15 | 완전 | search, read, send, draft CRUD, labels, trash, mark read/unread, attachment |
| Calendar | 10 | 완전 | list calendars, events, create, update, delete, find free time, respond, quick add |
| Drive | 14 | 완전 | search, list, copy, move, share, permissions, shared drives, quota |
| Docs | 9 | 완전 | create, read, append, prepend, replace, headings, tables, comments |
| Sheets | 13 | 완전 | create, read, write, append, clear, format, add/delete/rename sheet, auto-resize |
| Slides | 10 | 양호 | create, read, add/delete/duplicate/move slides, add/replace text |
| **합계** | **71** | **양호** | |

### 3.2 아키텍처 품질

**강점:**
- TypeScript strict 모드로 타입 안정성 확보
- Zod 스키마 검증으로 입력값 안전성
- 모든 도구의 일관된 에러 핸들링 패턴
- Multi-stage Docker 빌드로 이미지 최적화

**발견된 문제:**

| ID | 심각도 | 문제 | 위치 | 설명 |
|----|--------|------|------|------|
| GWS-01 | Medium | 토큰 만료 체크 불완전 | `oauth.ts:200` | `expiry_date`만 체크하고 refresh_token 유효성 미검증 |
| GWS-02 | Medium | Rate Limiting 미구현 | 전체 tools/ | Google API 할당량 초과 시 재시도 로직 없음 |
| GWS-03 | Low | 에러 메시지 한국어 혼재 | `index.ts:48`, `oauth.ts:207` | `오류:`, `서버 시작 실패:` 등 한국어 에러 메시지 |
| GWS-04 | Low | `any` 타입 사용 | `index.ts:32` | `async (params: any)` — strict 모드의 의미 약화 |
| GWS-05 | Medium | 동시 인증 요청 미처리 | `oauth.ts:113-182` | 여러 도구가 동시에 인증 요청 시 경쟁 조건 가능 |
| GWS-06 | Low | package.json 버전 0.1.0 | `package.json:3` | 프로덕션 배포 중이나 버전이 0.1.0 |
| GWS-07 | **High** | Drive API 쿼리 인젝션 | `drive.ts:18,59` | `name contains '${query}'` — 사용자 입력 미이스케이핑으로 쿼리 조작 가능 |
| GWS-08 | Medium | Email 헤더 인젝션 | `gmail.ts` | `gmail_send`에서 `to` 필드에 개행문자로 숨은 수신자 추가 가능 |
| GWS-09 | Medium | Calendar 타임존 하드코딩 | `calendar.ts:161,170,175` | `+09:00` (KST) 하드코딩. 한국 외 사용자에게 잘못된 시간 |
| GWS-10 | Medium | Gmail 중첩 MIME 미처리 | `gmail.ts:70-75` | 중첩 multipart 이메일 본문 추출 시 1단계만 파싱. 첨부파일 포함 메일 본문 누락 |
| GWS-11 | Low | 첨부파일 1000자 절삭 | `gmail.ts:358` | 첨부파일 데이터가 1000자로 잘려 실질적 다운로드 불가 |
| GWS-12 | Low | .dockerignore 미존재 | `google-workspace-mcp/` | `.google-workspace/` 디렉토리가 빌드 컨텍스트에 포함될 위험 |

---

## 4. 보안 및 권한 제어 분석

### 4.1 Critical 취약점

| ID | 심각도 | 카테고리 | 문제 | 영향 |
|----|--------|---------|------|------|
| SEC-01 | **Critical** | 공급망 보안 | `curl \| bash` 및 `irm \| iex` 설치 패턴 | MITM 공격 시 임의 코드 실행 가능. HTTPS를 사용하지만 스크립트 무결성 검증(체크섬/서명) 없음 |
| SEC-02 | **Critical** | 자격증명 노출 | Atlassian API 토큰이 `.mcp.json`에 평문 저장 | `atlassian/install.sh:157-168` — API 토큰이 JSON 설정 파일에 평문으로 기록됨 |
| SEC-03 | **Critical** | 자격증명 노출 | Figma 토큰이 환경변수로 MCP 설정에 노출 | `figma/module.json:24` — `FIGMA_PERSONAL_ACCESS_TOKEN`이 설정 파일에 기록 |

### 4.2 High 취약점

| ID | 심각도 | 카테고리 | 문제 | 영향 |
|----|--------|---------|------|------|
| SEC-04 | High | OAuth 토큰 저장 | `token.json`이 파일 시스템에 평문 저장 | `oauth.ts:107` — 암호화 없이 JSON 파일로 저장. 파일 권한(600) 미설정 |
| SEC-05 | High | Docker 보안 | Dockerfile에서 non-root 사용자 미사용 | `Dockerfile` — 컨테이너가 root로 실행됨 |
| SEC-06 | High | 관리자 권한 | Windows 설치 시 무조건 관리자 권한 요구 | `install.ps1:130-153` — base 설치가 아닌 경우에도 관리자 권한 요청 |
| SEC-07 | High | OAuth 스코프 | gmail.modify 등 과도한 권한 요청 | `oauth.ts:18-25` — 최소 권한 원칙 미준수. 사용하지 않는 서비스 스코프도 항상 요청 |
| SEC-08 | High | 네트워크 보안 | Google MCP OAuth 콜백에 state 파라미터 미사용 | `oauth.ts:114-118` — CSRF 위험. 단, `shared/oauth-helper.sh`의 PKCE+state 검증은 양호 |
| SEC-08a | High | 코드 인젝션 | osascript 템플릿 리터럴 인젝션 | `install.sh:32-38` — 원격 JSON이 백틱/`${}`를 포함하면 임의 JavaScript 실행 가능 |

### 4.3 Medium 취약점

| ID | 심각도 | 카테고리 | 문제 | 영향 |
|----|--------|---------|------|------|
| SEC-09 | Medium | 입력 검증 | 인스톨러에서 사용자 입력 미검증 | `atlassian/install.sh:125-134` — URL, 이메일, API 토큰에 대한 형식 검증 없음 |
| SEC-10 | Medium | .gitignore | `client_secret.json` 미등록 | `.gitignore` — Google OAuth 클라이언트 시크릿 파일이 .gitignore에 없음 |
| SEC-11 | Medium | Docker 이미지 | 외부 Docker 이미지 무검증 사용 | `ghcr.io/sooperset/mcp-atlassian:latest` — 서드파티 이미지를 latest 태그로 사용 |
| SEC-12 | Medium | 코드 주입 | install.sh에서 변수 이스케이핑 미흡 | `atlassian/install.sh:147-172` — Node.js `-e` 플래그에 사용자 입력 직접 삽입 |
| SEC-13 | Medium | 프로세스 노출 | API 토큰이 Docker 프로세스 인자에 노출 | `atlassian/module.json:23-31` — `docker inspect`, `ps aux`에서 토큰 확인 가능 |
| SEC-14 | Medium | 설정 디렉토리 권한 | 설정 디렉토리 생성 시 제한적 권한 미설정 | `oauth.ts:52-55` — `mkdir` 시 `mode: 0o700` 미지정 |

### 4.5 양호 사항 (Good Practices)

| ID | 카테고리 | 내용 |
|----|---------|------|
| GOOD-01 | HTTPS | 모든 원격 URL이 HTTPS 사용 |
| GOOD-02 | PKCE | `shared/oauth-helper.sh`에서 PKCE(S256) + state 파라미터 검증 구현 |
| GOOD-03 | 소스코드 | 소스코드에 하드코딩된 시크릿 없음 |
| GOOD-04 | .gitignore | `client_secret.json`, `token.json`, `credentials.json` 적절히 제외 |
| GOOD-05 | 입력검증 | Zod 스키마로 MCP 도구 입력값 검증 |

### 4.4 보안 권고사항

1. **스크립트 무결성 검증 도입** — SHA256 체크섬 또는 GPG 서명 검증 추가
2. **자격증명 암호화 저장** — OS 키체인(macOS Keychain, Windows Credential Manager) 활용
3. **OAuth 최소 권한** — 사용자가 선택한 서비스만 스코프 요청
4. **Docker non-root 실행** — Dockerfile에 `USER node` 추가
5. **CSRF 방지** — OAuth state 파라미터 구현
6. **토큰 파일 권한 설정** — `chmod 600 token.json`

---

## 5. OS 호환성 및 리소스 요구사항

### 5.1 호환성 매트릭스

| 컴포넌트 | Windows 10/11 | macOS 14+ | macOS 13 | Ubuntu 22.04+ | Fedora/Arch | WSL2 |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|
| Base 설치 | ✅ | ✅ | ✅ | ⚠️ | ❌ | ✅ |
| Claude CLI | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| bkit Plugin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Docker Desktop | ✅ | ✅ | ❌* | ✅ | ⚠️ | ✅ |
| Google MCP | ✅ | ✅ | ❌* | ✅ | ⚠️ | ✅ |
| Atlassian MCP | ✅ | ✅ | ⚠️ | ✅ | ⚠️ | ✅ |
| Notion MCP | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| GitHub CLI | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Figma MCP | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Pencil | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |

**범례**: ✅ 완전 지원, ⚠️ 부분 지원/수동 설정 필요, ❌ 미지원
*Docker Desktop 4.53+가 macOS 13(Ventura) 지원 중단. 인스톨러가 버전 미체크하여 설치 실패

### 5.2 최소 리소스 요구사항

| 구성 | RAM | 디스크 | CPU | 네트워크 |
|------|-----|-------|-----|---------|
| Base Only | 4GB | 2GB | 2코어 | 인터넷 필수 |
| Base + 비-Docker MCP | 4GB | 3GB | 2코어 | 인터넷 필수 |
| Base + Docker MCP | **8GB** | **10GB** | 4코어 | 인터넷 필수 |
| 전체 모듈 | **8GB** | **15GB** | 4코어 | 인터넷 필수 |

### 5.3 주요 호환성 문제

| ID | 심각도 | 문제 | 설명 |
|----|--------|------|------|
| OS-01 | **High** | Linux JSON 파싱 불가 | `install.sh`의 `parse_json()`이 macOS `osascript` 사용. Linux에서 모듈 로딩 실패 |
| OS-02 | Medium | Linux 패키지 관리자 | apt/snap만 지원. dnf, pacman, zypper 미지원 |
| OS-03 | Medium | Docker Desktop 버전 | 최소 Docker Desktop 4.x 필요하나 버전 체크 없음 |
| OS-04 | Low | Node.js 버전 | LTS 설치 시 버전 미지정. Node 18/20/22 호환성 미검증 |
| OS-05 | Medium | WSL 의존성 | Windows Docker 모듈이 WSL2 필요. Windows 10 1903+(build 18362+) 이상, BIOS 가상화 필수 |
| OS-06 | **High** | macOS Ventura Docker 비호환 | Docker Desktop 4.53+가 macOS 13(Ventura) 지원 중단. `brew install --cask docker`가 최신버전 설치하여 실패 |
| OS-07 | Medium | Python 3 미문서화 의존성 | Notion/Figma OAuth 헬퍼 스크립트에 Python 3 필요하나 `module.json`에 미표기 |
| OS-08 | Medium | Node.js 20 EOL 임박 | Docker 이미지 `node:20-slim` 사용. Node.js 20 LTS 2026-04-30 종료. Node 22 마이그레이션 필요 |
| OS-09 | Low | Docker 멀티아키텍처 미지정 | Google MCP Dockerfile에 멀티아키텍처 빌드 미설정. Apple Silicon에서 x86 에뮬레이션 |
| OS-10 | Low | 오프라인 설치 미지원 | 모든 모듈이 인터넷 필수. 에어갭/제한 네트워크 환경 미지원 |

---

## 6. 외부 MCP 모듈 분석

### 6.1 Atlassian MCP (`mcp-atlassian`)

- **소스**: `ghcr.io/sooperset/mcp-atlassian` (서드파티)
- **기능**: Jira (이슈 CRUD, 검색, 스프린트, 워크로그) + Confluence (페이지 CRUD, 검색)
- **인증**: API Token (Basic Auth)
- **제한**: 토큰이 설정 파일에 평문 저장
- **대안**: Rovo MCP (SSE 방식, `mcp.atlassian.com`) — 설치 스크립트에서 이미 지원
- **평가**: ✅ 양호 — Docker/Rovo 듀얼 모드 구현 잘됨

### 6.2 Notion MCP

- **소스**: `https://mcp.notion.com/mcp` (Notion 공식 Remote MCP)
- **타입**: HTTP Remote MCP (Docker 불필요)
- **인증**: Notion OAuth (브라우저 기반)
- **기능**: 페이지/DB 읽기, 검색
- **평가**: ✅ 우수 — 공식 서버 사용, 설정 간단

### 6.3 Figma MCP

- **소스**: `@anthropic/mcp-figma` (Anthropic 공식 npx)
- **인증**: Personal Access Token (환경변수)
- **기능**: 디자인 파일 읽기, 컴포넌트 검사, 디자인 토큰 추출
- **제한**: 토큰이 MCP 설정에 평문 노출
- **평가**: ⚠️ 양호 — 토큰 보안 개선 필요

### 6.4 GitHub CLI

- **소스**: `gh` CLI (GitHub 공식)
- **타입**: CLI 설치 (MCP가 아닌 직접 도구)
- **인증**: `gh auth login` (브라우저 기반 OAuth)
- **제한**: MCP 서버가 아닌 CLI 도구로, Claude가 직접 활용하려면 Bash 도구 의존
- **평가**: ⚠️ 보통 — MCP 서버 방식으로 전환 검토 필요

### 6.5 Pencil

- **소스**: VS Code Extension (`pencil.dev`)
- **타입**: IDE 확장 (MCP가 아님)
- **기능**: AI 디자인 캔버스, 코드 생성
- **제한**: VS Code 필수, Claude Code CLI와 직접 연동 아님
- **평가**: ✅ 양호 — 보완적 도구로 적합

---

## 7. 코드 품질 및 아키텍처 분석

### 7.1 아키텍처 일치도

| 항목 | ARCHITECTURE.md | 실제 구현 | 일치 |
|------|----------------|---------|------|
| 모듈 동적 로딩 | ✅ | ✅ | ✅ |
| Docker/CLI 모듈 분류 | ✅ | ✅ | ✅ |
| 원격/로컬 실행 | ✅ | ✅ | ✅ |
| Pencil 모듈 | ❌ (미기재) | ✅ (구현) | ❌ |
| Remote MCP 타입 | ❌ (미기재) | ✅ (Notion) | ❌ |
| 2단계 설치 | ✅ | ✅ | ✅ |

### 7.2 코드 품질 지표

| 지표 | 현황 | 평가 |
|------|------|------|
| 테스트 커버리지 | **0%** — 유닛/통합 테스트 없음 | ❌ Critical |
| CI/CD | 수동 트리거만 (workflow_dispatch) | ⚠️ |
| CI 테스트 범위 | base, github, notion, figma만 | ⚠️ (google, atlassian 미포함) |
| 에러 핸들링 | 기본적 try/catch 존재 | ⚠️ |
| 로깅 | console.error 기반 | ⚠️ |
| 코드 중복 | 모듈 간 컬러 정의, Docker 체크 중복 | ⚠️ |
| 타입 안정성 | TypeScript strict (GWS), 스크립트는 N/A | ✅/N/A |
| 문서화 | ARCHITECTURE.md, SETUP.md, README.md | ✅ |
| 버전 관리 | modules.json v1.0.0, GWS v0.1.0 | ⚠️ |

### 7.3 코드 품질 문제

| ID | 심각도 | 문제 | 설명 |
|----|--------|------|------|
| QA-01 | **Critical** | 테스트 부재 | 유닛 테스트, 통합 테스트 완전 부재. 설치 스크립트 변경 시 회귀 위험 |
| QA-02 | High | CI 자동 트리거 미설정 | PR/push 시 자동 테스트 없음. 수동 dispatch만 |
| QA-03 | Medium | 공유 유틸리티 미분리 | 컬러 정의, Docker 체크 로직이 모든 모듈에 중복 |
| QA-04 | Medium | 에러 복구 미흡 | 중간 단계 실패 시 이전 상태로 복원 불가 |
| QA-05 | Low | 구조적 로깅 부재 | 디버깅을 위한 구조화된 로그 레벨 시스템 없음 |
| QA-06 | Medium | 대규모 코드 중복 | 컬러 정의 10회, MCP 설정 업데이트 4회, Notion/Figma 스크립트 90% 동일 |
| QA-07 | Medium | Google 서비스 매호출 재생성 | `getGoogleServices()` 71회 호출 — 싱글톤/캐싱 없음 |
| QA-08 | Low | ESLint/Prettier 미설정 | TypeScript 코드에 린터/포매터 설정 없음 |
| QA-09 | Low | CHANGELOG 미존재 | 릴리스 노트, 변경 이력 추적 없음 |

---

## 8. AI Native 업무환경 목적 달성도 평가

### 8.1 CTO 관점 평가

#### 원클릭 설치 목표 달성도: 75%

**달성된 부분:**
- 랜딩페이지 → 명령어 생성 → 터미널 실행의 3단계 플로우 구현 완료
- 모듈 선택 기반의 유연한 설치 구성
- Claude Code CLI + bkit 플러그인 핵심 스택 자동 설치
- Docker 기반 MCP 서버 자동 구성

**미달성 부분:**
- Google 모듈 설치 시 6단계 수동 작업 필요 (Google Cloud Console)
- Atlassian Docker 모드 시 API 토큰 수동 생성/입력 필요
- Docker Desktop 설치 후 재시작 → 2단계 설치 필요
- 설치 완료 후 각 MCP 서버의 정상 동작 자동 검증 미구현

#### AI Native 환경 구성 완성도: 72%

| 구성요소 | 중요도 | 구현 | 평가 |
|---------|--------|------|------|
| Claude Code CLI 설치 | 필수 | ✅ | 네이티브 설치 완벽 |
| bkit 플러그인 설치 | 필수 | ✅ | marketplace 통해 설치 |
| MCP 서버 설정 | 핵심 | ✅ | .mcp.json 자동 구성 |
| Google Workspace 연동 | 핵심 | ⚠️ | 수동 단계 다수 |
| 프로젝트 관리 (Jira) | 중요 | ✅ | Docker/Rovo 듀얼 모드 |
| 지식베이스 (Confluence) | 중요 | ✅ | Atlassian 모듈에 포함 |
| 문서 (Notion) | 중요 | ✅ | 공식 Remote MCP |
| 디자인 (Figma) | 부가 | ✅ | Anthropic 공식 MCP |
| 코드 관리 (GitHub) | 중요 | ⚠️ | CLI만, MCP 미구현 |
| 설치 후 검증 | 중요 | ❌ | 자동 검증 없음 |
| 업데이트 메커니즘 | 중요 | ❌ | 업데이트/업그레이드 미구현 |
| 제거(Uninstall) | 부가 | ❌ | 제거 기능 없음 |

### 8.2 경쟁력 분석

| 비교 항목 | ADW | Cursor | Windsurf | Cline |
|----------|-----|--------|----------|-------|
| AI 코딩 어시스턴트 | Claude Code CLI | 내장 | 내장 | VS Code 확장 |
| MCP 통합 | ✅ 7개 모듈 | ❌ | ❌ | 제한적 |
| 원클릭 설치 | ✅ | ✅ | ✅ | ⚠️ |
| 업무도구 연동 | ✅ 포괄적 | ❌ | ❌ | ❌ |
| 엔터프라이즈 | ❌ | ⚠️ | ⚠️ | ❌ |

**ADW의 차별적 가치**: AI 코딩 도구 + 업무 도구(Google, Jira, Notion, Figma)의 통합 자동 설치는 경쟁사에 없는 고유 가치.

---

## 9. 개선 권고사항 (우선순위순)

### Priority 1 — Critical (즉시 수정)

| # | 권고사항 | 대상 | 예상 효과 |
|---|---------|------|----------|
| R-01 | **Linux JSON 파서 교체** — `osascript` 대신 `node -e` 또는 `python3 -c`를 사용하여 크로스 플랫폼 JSON 파싱 구현 | `install.sh:29-39` | Linux 지원 완성 |
| R-02 | **자격증명 암호화 저장** — Atlassian API 토큰, Figma 토큰을 OS 키체인에 저장하거나 환경변수 참조 방식으로 변경 | `atlassian/install.sh`, `figma/module.json` | 보안 취약점 해소 |
| R-03 | **OAuth state 파라미터 추가** — CSRF 방지를 위한 state 토큰 생성/검증 구현 | `oauth.ts:113-118` | CSRF 공격 방지 |
| R-04 | **테스트 프레임워크 도입** — 최소한 Google MCP 서버에 대한 유닛 테스트 작성. 인스톨러 스크립트에 대한 smoke 테스트 추가 | 신규 | 회귀 방지 |

### Priority 2 — High (1~2주 내)

| # | 권고사항 | 대상 | 예상 효과 |
|---|---------|------|----------|
| R-05 | **Docker non-root 사용자** — Dockerfile에 `RUN adduser --system app` + `USER app` 추가 | `Dockerfile` | 컨테이너 보안 강화 |
| R-06 | **토큰 파일 권한 설정** — `token.json` 저장 시 `chmod 600` 적용 | `oauth.ts:107` | 토큰 파일 보호 |
| R-07 | **CI 자동 트리거** — PR/push 시 자동 실행되는 CI 워크플로우 추가 | `.github/workflows/` | 품질 게이트 확보 |
| R-08 | **OAuth 스코프 동적 설정** — 사용 서비스만 스코프 요청하도록 변경 | `oauth.ts:18-25` | 최소 권한 원칙 |
| R-09 | **Google API Rate Limiting** — 지수 백오프 재시도 로직 추가 | `google-workspace-mcp/src/tools/` | 안정성 향상 |
| R-10 | **MCP 설정 경로 통일** — Mac/Windows 모두 `~/.claude/mcp.json` 사용 | `installer/modules/google/install.sh:328` | 경로 일관성 |

### Priority 3 — Medium (1개월 내)

| # | 권고사항 | 대상 | 예상 효과 |
|---|---------|------|----------|
| R-11 | **스크립트 무결성 검증** — 다운로드 스크립트에 SHA256 체크섬 검증 추가 | `install.sh`, `install.ps1` | 공급망 보안 |
| R-12 | **설치 후 자동 검증** — 각 모듈 설치 후 MCP 서버 연결 테스트 실행 | 신규 | 사용자 신뢰 |
| R-13 | **롤백 메커니즘** — 설치 실패 시 변경사항 되돌리기 지원 | 인스톨러 전체 | 안전한 설치 |
| R-14 | **업데이트 명령어** — `--update` 플래그로 기존 설치 업데이트 지원 | 인스톨러 전체 | 유지보수성 |
| R-15 | **공유 유틸리티 모듈화** — 컬러, Docker 체크, JSON 파싱을 `shared/` 모듈로 분리 | `installer/modules/shared/` | 코드 중복 제거 |
| R-16 | **Linux 패키지 관리자 확장** — dnf, pacman, zypper 지원 추가 | `base/install.sh` | Linux 호환성 확장 |
| R-17 | **GitHub MCP 서버 도입** — `gh` CLI 대신 GitHub MCP 서버 설정으로 전환 | `github/` 모듈 | Claude 직접 연동 |

### Priority 4 — Low (장기)

| # | 권고사항 | 대상 | 예상 효과 |
|---|---------|------|----------|
| R-18 | **엔터프라이즈 관리 기능** — 조직 단위 설정 배포, 중앙 관리 콘솔 | 신규 | 엔터프라이즈 시장 |
| R-19 | **제거(Uninstall) 기능** — 설치된 MCP 설정/Docker 이미지 정리 | 신규 | 사용자 경험 |
| R-20 | **텔레메트리/분석** — 익명 설치 통계 수집 (opt-in) | 신규 | 제품 개선 데이터 |
| R-21 | **ARCHITECTURE.md 동기화** — Pencil, Remote MCP 타입 추가 | `ARCHITECTURE.md` | 문서 정확성 |

---

## 10. 종합 결론

### 10.1 현재 상태 평가

ADW는 **"AI Native 업무 환경 원클릭 구축"이라는 핵심 목적을 70% 이상 달성**하고 있다. 특히 다음 영역에서 강점을 보인다:

1. **모듈러 아키텍처** — 새 MCP 모듈 추가가 `module.json` + 설치 스크립트만으로 가능
2. **포괄적 도구 연동** — Google Workspace + Jira + Confluence + Notion + Figma를 하나의 설치로 통합
3. **Google MCP 서버** — 68개 이상의 도구로 구현 완성도 높음
4. **크로스 플랫폼** — Windows(PowerShell), Mac(Homebrew), Linux(apt) 지원

### 10.2 핵심 개선 영역

1. **보안 (가장 시급)** — 자격증명 평문 저장, CSRF 미방지, Docker root 실행 등 Multiple Critical/High 취약점
2. **테스트 (두 번째)** — 테스트 0%는 프로덕션 코드에 허용 불가
3. **Linux 호환성** — osascript 의존으로 Linux에서 모듈 로딩 불가
4. **설치 후 검증** — 설치 완료를 확인하는 자동화된 건강 검사 필요

### 10.3 Match Rate

| 영역 | 설계 의도 달성 | 가중치 | 점수 |
|------|-------------|--------|------|
| 원클릭 설치 | 72% | 25% | 18.00 |
| MCP 통합 | 82% | 20% | 16.40 |
| 보안 | 50% | 20% | 10.00 |
| 크로스 플랫폼 | 60% | 15% | 9.00 |
| 코드 품질 | 46% | 10% | 4.60 |
| 문서화 | 75% | 10% | 7.50 |
| **종합** | | **100%** | **65.50%** |

> **종합 Match Rate: 65.5%** — PDCA 기준 90% 미달, 개선 반복(Act Phase) 필요

### 10.4 에이전트별 세부 점수

| 에이전트 | 평가 영역 | 점수 | 핵심 발견 |
|---------|----------|------|----------|
| installer-analyzer | 인스톨러 구조 | 6/10 | 버그 10건, Linux JSON 파서 불가, Notion/Figma 원격실행 불가 |
| google-mcp-analyzer | Google MCP | 7/10 | 71 도구 양호, Drive 쿼리 인젝션(HIGH), 타임존 하드코딩 |
| security-analyzer | 보안 | 5/10 | 31건 (1 Critical, 8 High, 14 Medium, 5 Low, 5 Good) |
| quality-analyzer | 코드 품질 | 4.6/10 | 테스트 0%, CI 수동, 코드 중복 심각, `any` 타입 다수 |
| cto-evaluator | AI Native 달성 | 6.7/10 | 엔터프라이즈 4/10, 확장성 8/10, 온보딩 6.5/10 |

---

## 부록

### A. 분석에 사용된 파일 목록

```
installer/install.sh (416 lines)
installer/install.ps1 (407 lines)
installer/ARCHITECTURE.md (246 lines)
installer/modules.json
installer/modules/base/module.json, install.sh
installer/modules/google/module.json, install.sh
installer/modules/atlassian/module.json, install.sh
installer/modules/notion/module.json
installer/modules/github/module.json
installer/modules/figma/module.json
installer/modules/pencil/module.json
google-workspace-mcp/package.json
google-workspace-mcp/tsconfig.json
google-workspace-mcp/Dockerfile
google-workspace-mcp/src/index.ts
google-workspace-mcp/src/auth/oauth.ts
google-workspace-mcp/src/tools/gmail.ts
google-workspace-mcp/src/tools/calendar.ts
google-workspace-mcp/src/tools/drive.ts
google-workspace-mcp/src/tools/docs.ts
google-workspace-mcp/src/tools/sheets.ts
google-workspace-mcp/src/tools/slides.ts
.github/workflows/test-installer.yml
.gitignore
README.md
```

### B. 분석 팀 구성

| 역할 | 에이전트 타입 | 분석 영역 |
|------|-------------|----------|
| CTO Lead | team-lead (opus) | 종합 오케스트레이션 |
| installer-analyzer | code-analyzer | 인스톨러 모듈 구조 |
| google-mcp-analyzer | code-analyzer | Google MCP 서버 |
| security-analyzer | security-architect | 보안 및 권한 |
| os-compat-analyzer | general-purpose | OS 호환성/리소스 |
| external-mcp-analyzer | general-purpose | 외부 MCP 모듈 |
| quality-analyzer | code-analyzer | 코드 품질/아키텍처 |
| cto-evaluator | enterprise-expert | AI Native 달성도 |
