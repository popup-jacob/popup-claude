# ADW Comprehensive Improvement Plan

> **Summary**: ADW 종합 분석(65.5%) 기반 보안/품질/호환성 전면 개선으로 Match Rate 90%+ 달성
>
> **Project**: popup-claude (AI-Driven Work Installer)
> **Version**: 2.2 (현재 master branch, commit 7b16685)
> **Author**: CTO Team (8 에이전트 병렬 분석 + 코드 전수 검증)
> **Date**: 2026-02-13
> **Status**: Draft
> **References**:
> - `docs/03-analysis/adw-comprehensive.analysis.md` (종합 분석)
> - `docs/03-analysis/security-verification-report.md` (보안 검증 보고서)
> - `docs/03-analysis/shared-utilities-design.md` (공유 유틸리티 상세 설계)
> - `docs/03-analysis/adw-requirements-traceability-matrix.md` (요구사항 추적 매트릭스)
> - `docs/03-analysis/gap-security-verification.md` (보안 검증 갭 분석)
> - `docs/03-analysis/gap-shared-utilities.md` (공유 유틸리티 갭 분석)
> - `docs/03-analysis/gap-requirements-traceability.md` (요구사항 추적 갭 분석)

---

## 1. Overview

### 1.1 Purpose

ADW 종합 분석 보고서(Match Rate 65.5%)에서 도출된 **3건 Critical, 8건 High, 14건 Medium, 5건 Low 총 30건의 이슈**와 **9건의 코드 품질 문제**, **10건의 OS 호환성 문제**를 체계적으로 해결하여, "원클릭 AI Native 업무환경 구축"이라는 핵심 목표의 달성도를 90% 이상으로 끌어올린다.

### 1.2 Background

**현재 상태 (65.5%)**:
| 영역 | 현재 점수 | 목표 점수 | 갭 |
|------|:--------:|:--------:|:---:|
| 원클릭 설치 | 72% | 92% | +20% |
| MCP 통합 | 82% | 95% | +13% |
| 보안 | 50% | 90% | **+40%** |
| 크로스 플랫폼 | 60% | 85% | +25% |
| 코드 품질 | 46% | 85% | **+39%** |
| 문서화 | 75% | 90% | +15% |

**핵심 문제 3가지**:
1. **보안 취약점 다수** — 자격증명 평문 저장(Critical), OAuth CSRF 미방지(High), Drive 쿼리 인젝션(High)
2. **테스트 0%** — 유닛/통합 테스트 완전 부재, CI 수동 트리거만 존재
3. **Linux 미지원** — `osascript` 의존 JSON 파서로 Linux에서 모듈 로딩 불가

### 1.3 Related Documents

- Analysis (Core): `docs/03-analysis/adw-comprehensive.analysis.md`
- Security Verification: `docs/03-analysis/security-verification-report.md`
- Shared Utilities Design: `docs/03-analysis/shared-utilities-design.md`
- Requirements Traceability: `docs/03-analysis/adw-requirements-traceability-matrix.md`
- Gap Analysis (Security): `docs/03-analysis/gap-security-verification.md`
- Gap Analysis (Shared Utils): `docs/03-analysis/gap-shared-utilities.md`
- Gap Analysis (Traceability): `docs/03-analysis/gap-requirements-traceability.md`
- Architecture: `installer/ARCHITECTURE.md`
- Google MCP: `google-workspace-mcp/package.json`

---

## 2. Scope

### 2.1 In Scope

- [x] **Sprint 1 (Critical Security)**: 자격증명 보안, 코드 인젝션 방지, CSRF 방지
- [x] **Sprint 2 (Platform & Stability)**: Linux 호환성, 인스톨러 버그 수정, 원격 실행 수정
- [x] **Sprint 3 (Quality & Testing)**: 테스트 프레임워크 도입, CI 자동화, 코드 품질 개선
- [x] **Sprint 4 (Google MCP Hardening)**: Rate limiting, 타임존 동적화, 서비스 캐싱, MIME 처리
- [x] **Sprint 5 (UX & Documentation)**: 설치 후 검증, 업데이트/제거 기능, 문서 동기화

### 2.2 Out of Scope

- 엔터프라이즈 관리 기능 (조직 단위 배포, 중앙 관리 콘솔)
- 텔레메트리/익명 분석 수집 시스템
- GitHub MCP 서버 신규 개발 (CLI→MCP 전환)
- 오프라인/에어갭 설치 지원
- GPG 서명 기반 스크립트 무결성 검증 — 인프라 별도 구축 필요 (SHA-256 체크섬 검증은 **In Scope**, FR-S1-11)
- 서드파티 Docker 이미지 검증 (SEC-11) — 공급망 보안은 인프라 레벨
- 구조적 로깅 프레임워크 (QA-05) — 단, **보안 이벤트 로깅**은 FR-S3-10으로 In Scope
- CHANGELOG 자동 생성 (QA-09) — Sprint 5 이후 검토

### 2.3 v2.2 변경사항 (v2.1 대비 In Scope 전환)

> v2.1에서 Out of Scope이었으나 갭 분석을 통해 In Scope으로 전환된 항목:
> - SHA-256 체크섬 기반 원격 스크립트 무결성 검증 (FR-S1-11) ← SEC-01 대응
> - 입력 검증 레이어 횡단 관심사 (FR-S1-12) ← OWASP A03 횡단 대응
> - npm audit CI 통합 (FR-S3-09) ← 의존성 보안 자동 검증
> - 보안 이벤트 로깅 (FR-S3-10) ← OWASP A09 대응
> - Docker Desktop 버전 호환성 체크 (FR-S2-11) ← OS-06 대응

---

## 3. Requirements

### 3.1 Functional Requirements

#### Sprint 1 — Critical Security (즉시)

| ID | Requirement | Priority | 공수(h) | 대상 파일 | 분석 근거 |
|----|-------------|:--------:|:-------:|----------|----------|
| FR-S1-01 | **OAuth state 파라미터 추가** — `generateAuthUrl()`에 `state` 토큰 생성, 콜백에서 state 검증 로직 구현 | **Critical** | 1-2 | `oauth.ts:113-118` | SEC-08: CSRF 공격 방지. `shared/oauth-helper.sh`는 이미 PKCE+state 구현 완료이므로 패턴 참조 가능 |
| FR-S1-02 | **Drive API 쿼리 이스케이핑** — `drive_search`, `drive_list` 핸들러에서 사용자 입력의 작은따옴표 이스케이프 처리 | **Critical** | 2-3 | `drive.ts:18,59` | GWS-07: `name contains '${query}'` — 입력값에 `'`가 포함되면 쿼리 조작 가능. `query.replace(/'/g, "\\'")` 적용 |
| FR-S1-03 | **osascript 템플릿 인젝션 방지** — `parse_json()` 함수에서 backtick 사용 대신 stdin 파이프 방식으로 변경 | **Critical** | 3-4 | `install.sh:29-39` | SEC-08a: 원격 JSON에 backtick/`${}` 포함 시 임의 JavaScript 실행. `echo "$json" \| osascript -l JavaScript -e "..."` 방식으로 변경 |
| FR-S1-04 | **Atlassian API 토큰 보안 저장** — `.mcp.json`에 평문 대신 환경변수 참조 방식으로 변경 | **Critical** | 4-6 | `atlassian/install.sh:147-172` | SEC-02(Critical): `docker -e JIRA_API_TOKEN=$apiToken`이 설정 파일에 평문 기록됨. `.env` 파일 분리 + `.gitignore` 추가. 검증보고서에서 Critical 확인(3순위), Appendix A.1과 정합성 일치. `gap-security-verification.md` P-02 반영: 검증보고서 원본 위험도 Critical 유지 |
| FR-S1-05 | **Figma 토큰 보안 저장** — `module.json`의 env 참조를 실제 환경변수에서 읽도록 변경, 설치 스크립트에서 `.env` 파일 생성 | **Low** | 0.5 | `figma/module.json:24`, `figma/install.sh` | SEC-03: ~~Critical~~ → **Informational** (CTO팀 검증 결과: `{accessToken}`은 템플릿 플레이스홀더이며 실제 토큰이 디스크에 기록되지 않음. 실제 install.sh는 Remote MCP 방식으로 전환 완료) |
| FR-S1-06 | **Docker non-root 사용자 추가** — Dockerfile에 `RUN addgroup --system app && adduser --system --ingroup app app` + `USER app` 추가 | **High** | 2-3 | `google-workspace-mcp/Dockerfile` | SEC-05: 컨테이너 root 실행은 컨테이너 탈출 시 호스트 권한 획득 위험 |
| FR-S1-07 | **token.json 파일 권한 설정** — `saveToken()` 함수에서 `fs.writeFileSync()` 후 `fs.chmodSync(TOKEN_PATH, 0o600)` 추가 | **High** | 1 | `oauth.ts:105-108` | SEC-04: 토큰 파일이 기본 권한(644)으로 생성되어 다른 사용자 읽기 가능 |
| FR-S1-08 | **설정 디렉토리 권한 설정** — `ensureConfigDir()`에서 `fs.mkdirSync(CONFIG_DIR, { recursive: true, mode: 0o700 })` 적용 | **High** | 0.5 | `oauth.ts:51-55` | SEC-14: 설정 디렉토리가 기본 권한으로 생성됨 |
| FR-S1-09 | **Atlassian install.sh 변수 이스케이핑** — Node.js `-e` 블록에 사용자 입력을 환경변수로 전달 (`node -e "..." 대신 `URL=... node -e "process.env.URL"`) | **High** | 3-4 | `atlassian/install.sh:147-172` | SEC-12: 사용자 입력(URL, email, token)이 Node.js 코드 문자열에 직접 삽입되어 코드 인젝션 가능 |
| FR-S1-10 | **Gmail 이메일 헤더 인젝션 방지** — `gmail_send` 핸들러에서 `to`, `cc`, `bcc` 필드의 개행문자(`\r\n`) 제거 | **Medium** | 2 | `gmail.ts` (send 핸들러) | GWS-08: 개행문자로 숨은 수신자 추가 가능 |
| FR-S1-11 | **원격 스크립트 다운로드 무결성 검증** — `curl\|bash` 패턴을 `curl -o tmpfile + SHA-256 체크섬 검증 + source` 방식으로 변경. GitHub 리포지토리에 `checksums.json` 매니페스트 발행, `download_and_verify()` 함수 구현. install.sh 3곳 + install.ps1 1곳 대응. GPG 서명은 Out of Scope 유지 | **Critical** | 6-8 | `install.sh:101-117,350-351`, `install.ps1:336` | SEC-01(Critical): MITM 시 원격 코드 실행 가능. 보안 검증 보고서 1순위 대응 |
| FR-S1-12 | **입력 검증 레이어 구축** — `src/utils/sanitize.ts` 공유 유틸리티 생성. `escapeDriveQuery()`, `sanitizeEmailHeader()`, `validateEmail()`, `validateDriveId()`, `validateMaxLength()` 등 횡단 관심사로 입력 검증 통합. FR-S1-02, FR-S1-10의 개별 검증을 재사용 가능한 유틸리티로 구조화 | **High** | 2-3 | `google-workspace-mcp/src/utils/sanitize.ts` (신규) | 설계서(security-spec.md Section 9.2)에만 존재하고 계획서에 명시적 FR 없음. OWASP A03(Injection) 횡단 대응 |
| | | | **합계: 28-37** | | |

#### Sprint 2 — Platform & Stability (1주 내)

| ID | Requirement | Priority | 공수(h) | 대상 파일 | 분석 근거 |
|----|-------------|:--------:|:-------:|----------|----------|
| FR-S2-01 | **크로스 플랫폼 JSON 파서 구현** — `parse_json()`를 `node -e` 기반으로 재구현. Node 미설치 시 `python3 -c` 폴백, 둘 다 없으면 `jq` 폴백 | **Critical** | 4-6 | `install.sh:29-39` | INS-01/OS-01: `osascript`는 macOS 전용. Linux에서 모듈 로딩 완전 불가 |
| FR-S2-02 | **원격 실행 시 shared 스크립트 다운로드** — `run_module()` 함수에서 원격 모드일 때 `curl -sSL` 하기 전에 `shared/oauth-helper.sh`를 임시 디렉토리에 다운로드하여 `source` 가능하도록 환경 구성. **임시 파일 정리 보장**: `trap 'rm -rf "$SHARED_TMP"' EXIT INT TERM` 패턴으로 정상/비정상 종료 시 모두 cleanup | **High** | 3-4 | `install.sh:346-352`, `notion/install.sh:54`, `figma/install.sh:58` | INS-07: `curl\|bash` 원격실행 시 `BASH_SOURCE[0]`가 빈 값이라 `$SCRIPT_DIR/../shared/oauth-helper.sh` 경로 해석 불가. `gap-requirements-traceability.md` 암묵적 요구사항 #3(임시 파일 정리) 반영 |
| FR-S2-03 | **MCP 설정 경로 통일** — Mac/Linux도 Windows와 동일하게 `~/.claude/mcp.json` 사용하도록 통일. **영향 범위: 3개 파일** (`install.sh:406`, `google/install.sh:328`, `atlassian/install.sh:145`) | **High** | 2-3 | `install.sh:406`, `google/install.sh:328`, `atlassian/install.sh:145` | INS-02: Mac 스크립트 3곳이 `~/.mcp.json`(레거시), Windows는 `~/.claude/mcp.json`(현재). commit `b8b01a2`에서 Windows만 변경하고 Mac 미반영 |
| FR-S2-04 | **Linux 패키지 관리자 확장** — `base/install.sh`에 `dnf`(Fedora/RHEL), `pacman`(Arch) 감지 및 설치 로직 추가. **주의**: FR-S2-01(parse_json) 완료 후 착수 필요 (직렬 의존성) | **Medium** | 3-4 | `base/install.sh:46-49, 88-93` | INS-05/OS-02: apt/snap만 지원. 주요 리눅스 배포판 커버리지 확대 |
| FR-S2-05 | **Figma module.json 정합성 수정** — `type: "remote-mcp"` 으로 변경, `requirements.node: false`로 수정 (실제 구현이 `claude mcp add --transport http`이므로) | **Medium** | 1 | `figma/module.json` | INS-08: module.json에는 `type: "mcp"`, `node: true`이지만 실제 install.sh는 Remote MCP 등록 방식 |
| FR-S2-06 | **Atlassian module.json Docker 표기 수정** — `requirements.docker: "optional"` 또는 별도 `modes` 필드 추가하여 Docker/Rovo 듀얼 모드 표현 | **Medium** | 1 | `atlassian/module.json:15` | INS-09: `docker: false`이지만 Docker 모드 존재. 메인 인스톨러 상태 표시에 영향 |
| FR-S2-07 | **모듈 실행 순서 정렬** — `SELECTED_MODULES`를 `MODULE_ORDERS` 배열 기준으로 정렬 후 실행 | **Low** | 2 | `install.sh:376` | INS-04: 모듈이 입력 순서대로 실행됨. 의존성 있는 모듈(base→google)의 순서 보장 필요 |
| FR-S2-08 | **Docker wait 타임아웃 추가** — `google/install.sh`의 `docker wait` 호출에 타임아웃(300초) 래퍼 추가 | **Low** | 1-2 | `google/install.sh:315` | INS-10: 인증 실패 시 무한 대기 가능 |
| FR-S2-09 | **Python 3 의존성 module.json 명시** — Notion, Figma module.json에 `requirements.python3: true` 추가 | **Medium** | 0.5 | `notion/module.json`, `figma/module.json` | OS-07: OAuth 헬퍼가 python3 필수이나 미문서화 |
| FR-S2-10 | **Windows 관리자 권한 조건부 요청** — base 모듈이 아닌 경우 관리자 권한 스킵 옵션 제공. `Test-AdminRequired` 함수로 모듈별 필요성 판단 후 조건부 UAC 상승 | **High** | 4-6 | `install.ps1:130-153` | SEC-06(High): 모든 설치에 무조건 관리자 권한 요구. 검증보고서 원래 위험도 High 복원. `gap-security-verification.md` P-03 반영 |
| FR-S2-11 | **Docker Desktop 버전 호환성 체크** — Docker Desktop 4.42+ 버전에서 macOS Ventura 미지원 이슈 감지 로직 추가. `docker version` 출력에서 Desktop 버전 파싱, OS 버전과 교차 검증하여 비호환 시 경고 메시지 출력. 공유 유틸리티 `docker-utils.sh`의 `docker_check()` 함수에 통합 | **Medium** | 2-3 | `google/install.sh`, `atlassian/install.sh`, `installer/modules/shared/docker-utils.sh` | OS-06(High): Docker Desktop 4.42+ macOS Ventura 미지원. `gap-requirements-traceability.md` Section 2 #5 참조 |
| | | | **합계: 26-39** | | |

#### Sprint 3 — Quality & Testing (2주 내)

| ID | Requirement | Priority | 공수(h) | 대상 파일 | 분석 근거 |
|----|-------------|:--------:|:-------:|----------|----------|
| FR-S3-01 | **Google MCP 유닛 테스트 작성** — Vitest 프레임워크 도입, 각 도구 파일(gmail, calendar, drive, docs, sheets, slides)별 최소 핵심 로직 테스트 작성. 목표 커버리지: 60%+ | **Critical** | 16-20 | `google-workspace-mcp/` (신규) | QA-01: 테스트 커버리지 0%. 회귀 방지를 위한 최소 안전망 필요 |
| FR-S3-02 | **인스톨러 Smoke 테스트 작성** — Bash 기반 테스트 스크립트로 각 모듈의 `module.json` 파싱, 기본 실행 검증 | **High** | 8-10 | `installer/tests/` (신규) | QA-01: 인스톨러 변경 시 회귀 테스트 수단 없음 |
| FR-S3-03 | **CI 자동 트리거 추가** — PR/push 시 자동 실행되는 워크플로우 추가. Google MCP 빌드 + 유닛 테스트 + 인스톨러 smoke 테스트 | **High** | 4-6 | `.github/workflows/test-installer.yml` | QA-02: 수동 `workflow_dispatch`만 존재. PR 머지 전 자동 검증 없음 |
| FR-S3-04 | **CI 테스트 범위 확장** — google, atlassian 모듈을 CI 테스트 대상에 추가 (현재 base, github, notion, figma만) | **Medium** | 2-3 | `.github/workflows/test-installer.yml:17-22` | 분석서: CI 테스트 범위 불완전 |
| FR-S3-05a | **인스톨러 공유 유틸리티 추출** — `installer/modules/shared/` 디렉토리에 5개 공유 스크립트 생성: `colors.sh`(ANSI 색상 상수 8+5개 + `print_success()`/`print_error()`/`print_warning()`/`print_info()`/`print_debug()` 편의함수 5개), `docker-utils.sh`(`docker_is_installed()`/`docker_is_running()`/`docker_get_status()`/`docker_check()`/`docker_wait_for_start()`/`docker_install()`/`docker_pull_image()`/`docker_cleanup_container()`/`docker_show_install_guide()` 9개 함수), `mcp-config.sh`(`mcp_get_config_path()`/`mcp_check_node()`/`mcp_add_docker_server()`/`mcp_add_stdio_server()`/`mcp_remove_server()`/`mcp_server_exists()` 6개 함수), `browser-utils.sh`(`browser_open()`/`browser_open_with_prompt()`/`browser_open_or_show()`/`browser_wait_for_completion()` 4개 함수, WSL 감지 포함), `package-manager.sh`(`pkg_detect_manager()`/`pkg_install()`/`pkg_install_cask()`/`pkg_is_installed()`/`pkg_ensure_installed()` 5개 함수, brew/apt/dnf/yum/pacman 지원). 7개 인스톨러 모듈(base, google, atlassian, figma, notion, github, pencil)을 공유 유틸리티 source로 순차 리팩토링. **수용 기준**: (1) 전 모듈 shared source 적용, (2) 인라인 색상 정의 0건, (3) Docker 모듈 `docker_check()` 사용, (4) MCP 모듈 `mcp_add_docker_server()`/`mcp_add_stdio_server()` 사용, (5) 브라우저 모듈 `browser_open()` 사용 | **Medium** | 12-16 | `installer/modules/shared/` (신규), `installer/modules/*/install.sh` (수정) | QA-06: 컬러 42줄 10회 중복, Docker 체크 4회 중복, MCP 설정 4회 중복, 브라우저 열기 4회 중복. `shared-utilities-design.md` Section 1.3 참조. `gap-shared-utilities.md` P-1~P-5, D-1~D-7 반영 |
| FR-S3-05b | **Google MCP 공유 유틸리티 추출** — `src/utils/` 디렉토리에 5개 유틸리티 생성: `time.ts`(parseTime, getCurrentTime, addDays, formatDate + getTimezone, getUtcOffsetString -- timezone.ts 기능 통합), `retry.ts`(withRetry, RetryOptions, isRetryableError -- 429/500/502/503/504 + ECONNRESET/ETIMEDOUT 대응), `sanitize.ts`(입력 검증 통합 7개 함수 -- FR-S1-12와 연계), `messages.ts`(8개 카테고리 ~60개 메시지 키 + `msg()` 헬퍼 -- FR-S5-05 동시 구현), `mime.ts`(extractTextBody, extractAttachments -- 재귀적 MIME 파싱). `oauth.ts` 내 서비스 캐싱 + `clearServiceCache()` 테스트 유틸리티 추가(FR-S4-04 연계). **수용 기준**: (1) calendar.ts 내 중복 parseTime 0건, (2) 69개 핸들러 캐싱된 getGoogleServices() 사용, (3) 모든 API 호출에 withRetry() 적용, (4) 사용자 입력 sanitize 함수 통과, (5) 하드코딩 한국어 메시지 0건(Sprint 5 완료 시) | **Medium** | 10-14 | `google-workspace-mcp/src/utils/` (신규), `google-workspace-mcp/src/tools/*.ts` (수정) | QA-06: parseTime 2곳 중복, QA-07: 서비스 69회 재생성. `shared-utilities-design.md` Section 2 참조. `gap-shared-utilities.md` P-6~P-10, D-8~D-14 반영 |
| FR-S3-06 | **ESLint + Prettier 설정** — Google MCP TypeScript 프로젝트에 린터/포매터 설정 추가 | **Low** | 2-3 | `google-workspace-mcp/` (신규) | QA-08: 코드 스타일 일관성 도구 없음 |
| FR-S3-07 | **`any` 타입 제거** — `index.ts:32`, `sheets.ts:18,341`, `calendar.ts:288`, `slides.ts:135,156`, `docs.ts:236`의 `any`/`as any` 사용을 proper type으로 교체. 총 7개 위치 대응 | **Low** | 2-3 | `google-workspace-mcp/src/index.ts:32`, `sheets.ts`, `calendar.ts`, `slides.ts`, `docs.ts` | GWS-04: TypeScript strict 모드의 의미 약화. Appendix A.2 Code Analyzer 추가 발견 위치 반영. `gap-requirements-traceability.md` Section 2.1 참조 |
| FR-S3-08 | **에러 메시지 영문 통일** — `index.ts:48`의 `오류:`, `oauth.ts:207`의 `서버 시작 실패:` 등을 영문으로 통일. FR-S3-05b의 `messages.ts` 중앙집중 메시지 구조를 활용하여 단순 치환이 아닌 구조적 메시지 관리 기반 마련 | **Low** | 1-2 | `index.ts:48`, `oauth.ts` | GWS-03: 한국어/영어 에러 메시지 혼재. `gap-shared-utilities.md` P-9 참조 |
| FR-S3-09 | **npm audit CI 통합** — CI 파이프라인에 `npm audit --audit-level=high` 단계 추가. High 이상 취약점 발견 시 빌드 실패. `npm ci` 전환과 함께 의존성 보안 자동 검증 게이트 구축 | **High** | 2-3 | `.github/workflows/ci.yml` (수정) | Security Architect 추가 발견: "Dependencies Not Audited". `gap-security-verification.md` P-06 참조 |
| FR-S3-10 | **보안 이벤트 로깅** — 인증 실패/성공, 토큰 갱신, 파일 권한 변경 이벤트를 stderr에 구조화된 형태로 출력. 최소 필드: timestamp, event_type, result, detail. MCP 서버 특성상 stdout은 JSON-RPC 전용이므로 stderr 사용 | **Medium** | 4-6 | `oauth.ts`, `index.ts` | OWASP A09(Security Logging and Monitoring Failures): 보안 로깅 부재. `gap-security-verification.md` P-05 참조 |
| | | | **합계: 63-86** | | |

#### Sprint 4 — Google MCP Hardening (3주 내)

| ID | Requirement | Priority | 공수(h) | 대상 파일 | 분석 근거 |
|----|-------------|:--------:|:-------:|----------|----------|
| FR-S4-01 | **Google API Rate Limiting 구현** — 지수 백오프 재시도 로직 추가. 429(Too Many Requests) 및 503 에러 시 자동 재시도 (최대 3회, 1s→2s→4s 백오프) | **High** | 4-6 | `google-workspace-mcp/src/tools/*.ts` | GWS-02: Google API 할당량 초과 시 에러만 반환. 일시적 오류에도 실패 |
| FR-S4-02 | **OAuth 스코프 동적 설정** — 환경변수 `GOOGLE_SCOPES`로 필요한 서비스 스코프만 선택 가능하도록 변경. 미지정 시 현재 전체 스코프 유지 (하위호환) | **High** | 4-6 | `oauth.ts:17-25` | SEC-07: 6개 서비스 스코프를 항상 전체 요청. Gmail만 사용해도 Drive/Calendar 권한 요구 |
| FR-S4-03 | **Calendar 타임존 동적화** — 하드코딩된 `Asia/Seoul` 대신 환경변수 `TIMEZONE`(기본값: `Intl.DateTimeFormat().resolvedOptions().timeZone`)에서 읽도록 변경 | **High** | 3-4 | `calendar.ts:161,170,175` | GWS-09: `+09:00` (KST) 하드코딩. 한국 외 사용자에게 잘못된 시간대 적용 |
| FR-S4-04 | **getGoogleServices() 싱글톤/캐싱** — 인증 클라이언트와 서비스 인스턴스를 모듈 레벨에서 캐싱. 토큰 만료 시에만 재생성. **주의**: FR-S4-05(토큰 검증), FR-S4-06(뮤텍스) 완료 후 착수 권장 (직렬 의존성) | **Medium** | 4-6 | `oauth.ts:227-238` | QA-07: 71개 도구 호출마다 `getGoogleServices()` 재생성. 불필요한 OAuth 체크 반복 |
| FR-S4-05 | **Token refresh_token 유효성 검증** — `loadToken()` 시 `refresh_token` 존재 여부 확인, 없으면 재인증 유도 | **Medium** | 2-3 | `oauth.ts:196-211` | GWS-01: `expiry_date`만 체크. refresh_token이 revoke된 경우 무한 실패 가능 |
| FR-S4-06 | **동시 인증 요청 처리** — 뮤텍스/세마포어 패턴으로 동시 인증 요청 방지. 첫 번째 요청 완료 후 나머지는 캐시된 결과 사용 | **Medium** | 3-4 | `oauth.ts:113-182` | GWS-05: 여러 도구가 동시에 인증 요청 시 경쟁 조건 가능 |
| FR-S4-07 | **Gmail 중첩 MIME 파싱 개선** — 재귀적 `parts` 탐색으로 중첩 multipart 이메일 본문 추출 | **Medium** | 3-4 | `gmail.ts:70-75` | GWS-10: 1단계 `parts`만 파싱. 첨부파일 포함 메일에서 본문 누락 |
| FR-S4-08 | **Gmail 첨부파일 다운로드 개선** — 1000자 절삭 제거, base64 전체 데이터 반환 (크기 제한 옵션 추가) | **Low** | 2-3 | `gmail.ts:358` | GWS-11: 첨부파일 데이터가 1000자로 잘려 실질적 다운로드 불가 |
| FR-S4-09 | **Node.js 22 마이그레이션** — Dockerfile의 `node:20-slim`을 `node:22-slim`으로 업데이트 | **Medium** | 2-3 | `Dockerfile` | OS-08: Node.js 20 LTS 2026-04-30 EOL. 보안 패치 중단 전 마이그레이션 필요 |
| FR-S4-10 | **.dockerignore 추가** — `.google-workspace/`, `node_modules/`, `.git/` 등 빌드 컨텍스트 제외 | **Low** | 0.5 | `google-workspace-mcp/` (신규) | GWS-12: 인증 파일이 Docker 빌드 컨텍스트에 포함될 위험 |
| | | | **합계: 28-40** | | |

#### Sprint 5 — UX & Documentation (1개월 내)

| ID | Requirement | Priority | 공수(h) | 대상 파일 | 분석 근거 |
|----|-------------|:--------:|:-------:|----------|----------|
| FR-S5-01 | **설치 후 자동 검증** — 각 모듈 설치 완료 후 MCP 서버 연결 테스트(health check) 실행. 실패 시 가이드 메시지 출력 | **High** | 6-8 | `install.sh` (완료 섹션) | 분석서 8.1: 설치 완료 후 정상 동작 자동 검증 미구현 |
| FR-S5-02 | **롤백 메커니즘 도입** — 설치 시작 전 현재 `.mcp.json` 백업, 실패 시 원본 복원 | **Medium** | 4-6 | `install.sh` | INS-03: 설치 실패 시 부분 설치 상태로 남음 |
| FR-S5-03 | **ARCHITECTURE.md 동기화** — Pencil 모듈, Remote MCP 타입(Notion, Figma), `shared/` 디렉토리 추가 | **Low** | 2-3 | `installer/ARCHITECTURE.md` | INS-06/QA 아키텍처 일치도: 2개 항목 불일치 |
| FR-S5-04 | **package.json 버전 업데이트** — `0.1.0` → `1.0.0` (프로덕션 배포 중이므로 SemVer 준수) | **Low** | 0.5 | `google-workspace-mcp/package.json:3` | GWS-06: 프로덕션 사용 중이나 버전이 0.1.0 |
| FR-S5-05 | **Google MCP 도구 메시지 영문화** — 전체 도구의 `description`, 응답 `message` 를 영문으로 통일 (국제화 준비). FR-S3-05b의 `messages.ts` 중앙집중 구조 활용 | **Low** | 4-6 | `google-workspace-mcp/src/tools/*.ts` | GWS-03: 한국어 메시지가 비한국어 사용자에게 의미 없음 |
| FR-S5-06 | **.gitignore 보강** — `client_secret.json` 패턴 추가 확인, `.env` 파일 패턴 추가 | **Medium** | 0.5 | `.gitignore` | SEC-10: Google OAuth 클라이언트 시크릿 파일 누출 위험 |
| | | | **합계: 17-24** | | |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| **Security** | OWASP Top 10 주요 항목 대응 — Injection(A03), CSRF(A01), Broken Auth(A07) | 코드 리뷰 + 보안 에이전트 검증 |
| **Test Coverage** | Google MCP 서버 60%+, 인스톨러 smoke 테스트 전 모듈 | Vitest coverage report |
| **CI/CD** | PR 자동 테스트 + 빌드 검증 Gate | GitHub Actions 워크플로우 |
| **Performance** | Google API 호출 시 서비스 인스턴스 재사용 (캐싱) | 응답시간 측정 |
| **Compatibility** | macOS 14+, Windows 10+, Ubuntu 22.04+, Fedora 39+, Arch Linux | CI 매트릭스 테스트 |
| **Reliability** | 설치 실패 시 롤백, Docker wait 타임아웃, Rate limit 재시도 | E2E 테스트 시나리오 |
| **Shell Quality** | ShellCheck warning 수준 이상 오류 0건 (인스톨러 전체) | ShellCheck CI job |
| **Dependency Security** | npm audit high+ 취약점 0건 | npm audit CI gate |
| **Security Logging** | 인증 실패/성공, 토큰 갱신, 파일 권한 변경 이벤트 로깅 | 보안 로그 출력 검증 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] 모든 Critical/High 보안 이슈 해결 (FR-S1-01 ~ FR-S1-12)
- [ ] Linux에서 `install.sh` 정상 동작 (FR-S2-01)
- [ ] Google MCP 유닛 테스트 60%+ 커버리지 (FR-S3-01)
- [ ] CI가 PR/push 시 자동 실행 (FR-S3-03)
- [ ] Gap Analysis Match Rate 90%+ 달성

### 4.2 Quality Criteria

- [ ] Zero Critical/High 보안 취약점
- [ ] 테스트 커버리지 60% 이상 (Google MCP)
- [ ] ESLint 에러 0건
- [ ] CI 빌드 성공
- [ ] 모든 모듈 설치 smoke 테스트 통과

### 4.3 정량적 기대 효과

| 지표 | 현재 | 목표 | 개선율 | 근거 |
|------|:----:|:----:|:------:|------|
| 인스톨러 LOC | ~1,200줄 | ~850줄 | **-29%** | 공유 유틸리티 추출(FR-S3-05a)로 7개 모듈의 중복 코드 제거 |
| Google MCP LOC | ~1,800줄 | ~1,300줄 | **-28%** | 공유 유틸리티 추출(FR-S3-05b)로 parseTime, sanitize, messages 통합 |
| 서비스 인스턴스 생성 | 414회/전체 호출 | 6회/캐시 TTL | **-99%** | getGoogleServices() 싱글톤 캐싱(FR-S4-04) |
| 테스트 커버리지 | 0% | 60%+ | **+60%** | Vitest 도입(FR-S3-01) + 인스톨러 Smoke 테스트(FR-S3-02) |
| 보안 취약점 (Critical/High) | 3C + 8H = 11건 | 0건 | **-100%** | Sprint 1~2 보안 이슈 전수 해결 |
| Match Rate | 65.5% | 95%+ | **+30%** | 5개 Sprint 전체 완료 시 |

> `gap-shared-utilities.md` Section 5 정량적 기대 효과 참조

### 4.4 Sprint별 완료 기준

| Sprint | 완료 기준 | 예상 Match Rate |
|--------|----------|:--------------:|
| Sprint 1 | 보안 이슈 12건 해결(FR-S1-01~12), 코드 리뷰 완료 | 74% |
| Sprint 2 | Linux 지원, 인스톨러 버그 11건 수정(FR-S2-01~11) | 82% |
| Sprint 3 | 테스트 도입, CI 자동화(npm audit 포함), 코드 품질 개선, 공유 유틸리티 추출(5a/5b) | 88% |
| Sprint 4 | Google MCP 강화 10건 | 92% |
| Sprint 5 | UX 개선, 문서 동기화 | **95%+** |

---

## 5. Risks and Mitigation

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|:------:|:----------:|------------|
| R-01 | MCP 설정 경로 변경 시 기존 사용자 설정 유실 | High | Medium | 마이그레이션 스크립트 제공, 기존 경로 폴백 지원 |
| R-02 | OAuth state 추가 시 기존 인증 플로우 깨짐 | High | Low | 하위 호환: state 없는 콜백도 허용(경고 로그만) |
| R-03 | Node.js 22 마이그레이션 시 googleapis 호환성 | Medium | Medium | 마이그레이션 전 로컬 테스트 + CI 검증 |
| R-04 | 크로스 플랫폼 JSON 파서 변경 시 기존 macOS 동작 변경 | Medium | Low | macOS에서도 동일한 `node -e` 방식 사용. osascript 폴백 유지 |
| R-05 | 환경변수 기반 토큰 저장이 Docker 환경에서 복잡도 증가 | Medium | Medium | Docker compose 예시 제공, 환경변수 설정 가이드 |
| R-06 | 테스트 도입 시 Google API Mock 구현 복잡도 | Medium | High | googleapis-mock 라이브러리 사용 또는 MSW(Mock Service Worker) 활용 |
| R-07 | Linux 패키지 관리자 다양성으로 엣지케이스 증가 | Low | High | 주요 3개(apt, dnf, pacman)만 지원, 나머지는 수동 안내 |
| R-08 | 공유 유틸리티 리팩토링 시 기존 인스톨러 모듈 동작 깨짐 | High | Medium | 모듈별 순차 리팩토링 + 각 모듈 리팩토링 후 smoke 테스트 실행. `gap-shared-utilities.md` P-15 참조 |

---

## 6. Architecture Considerations

### 6.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Simple structure | Static sites | ☐ |
| **Dynamic** | Feature-based modules, BaaS integration | Web apps with backend | ☐ |
| **Enterprise** | Strict layer separation, DI, microservices | High-traffic systems | ☑ |

> ADW는 크로스 플랫폼 인스톨러 + MCP 서버 + Docker 기반으로 Enterprise 레벨 구조를 따른다.

### 6.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| JSON Parser | osascript / node -e / python3 -c / jq | **node -e (primary)** | Node.js가 base 설치 의존성이므로 항상 가용. 미설치 시 python3 폴백 |
| Test Framework | Jest / Vitest / Mocha | **Vitest** | TypeScript 네이티브 지원, ESM 호환, 빠른 실행 속도 |
| CI Trigger | workflow_dispatch / push / PR | **push + PR** | PR 머지 전 자동 품질 게이트 필수 |
| Token Storage | 평문 JSON / OS Keychain / .env | **.env + 환경변수** | 크로스 플랫폼 호환, Docker 친화적 |
| Rate Limiting | 커스텀 구현 / p-retry / google-auth-library built-in | **커스텀 지수 백오프** | 외부 의존성 최소화, 429/503 특화 처리 |
| Timezone | 하드코딩 / 환경변수 / Intl API | **Intl API 기본값 + 환경변수 오버라이드** | 사용자 시스템 타임존 자동 감지, 명시적 오버라이드 가능 |

### 6.3 변경 영향 범위

```
변경 대상:
┌─────────────────────────────────────────────────────┐
│ installer/                                           │
│   install.sh ─── parse_json() 재구현, 모듈 정렬     │
│   install.ps1 ── 관리자 권한 조건부 요청             │
│   modules/                                           │
│     shared/      ── 공유 유틸리티 추가                │
│     atlassian/   ── 토큰 보안, 변수 이스케이핑       │
│     figma/       ── module.json 수정, 토큰 보안      │
│     notion/      ── module.json 수정                 │
│     google/      ── Docker wait 타임아웃              │
│     base/        ── Linux 패키지 관리자 확장          │
├─────────────────────────────────────────────────────┤
│ google-workspace-mcp/                                │
│   Dockerfile ─── non-root, Node 22, .dockerignore   │
│   src/auth/oauth.ts ── state, 권한, 캐싱, 파일권한  │
│   src/index.ts ─── 타입 수정, 에러 메시지 영문화     │
│   src/tools/                                         │
│     drive.ts ─── 쿼리 이스케이핑                     │
│     gmail.ts ─── 헤더 인젝션, MIME 파싱, 첨부파일    │
│     calendar.ts ─── 타임존 동적화                    │
├─────────────────────────────────────────────────────┤
│ .github/workflows/ ── CI 자동 트리거, 테스트 확장    │
│ .gitignore ── .env, client_secret.json 패턴 확인     │
│ installer/ARCHITECTURE.md ── 문서 동기화              │
└─────────────────────────────────────────────────────┘
```

---

## 7. Convention Prerequisites

### 7.1 Existing Project Conventions

- [ ] `CLAUDE.md` has coding conventions section
- [x] `installer/ARCHITECTURE.md` exists (but needs sync)
- [ ] `CONVENTIONS.md` exists at project root
- [ ] ESLint configuration (`.eslintrc.*`) — **미존재, Sprint 3에서 추가**
- [ ] Prettier configuration (`.prettierrc`) — **미존재, Sprint 3에서 추가**
- [x] TypeScript configuration (`tsconfig.json`) — strict 모드 활성

### 7.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|:------------:|-----------|:--------:|
| **Error Messages** | 한/영 혼재 | 영문 통일, i18n 키 방식 검토 | Medium |
| **Shell Script** | 모듈별 중복 코드 | `shared/` 유틸리티 import 패턴 | High |
| **TypeScript** | strict, any 사용 | `any` 금지, unknown + type guard | Medium |
| **Security** | 평문 저장 | 환경변수 참조, 파일 권한 600 | **Critical** |
| **Docker** | root 실행 | non-root 사용자 패턴 | High |
| **Env Management** | 환경변수 분산 | `.env.example` 템플릿, 신규 환경변수 문서화 | Medium |
| **Module Schema** | 비공식 JSON 구조 | `installer/module-schema.json` JSON Schema 정의 | Medium |
| **Shell Quality** | ShellCheck 미적용 | CI에 ShellCheck 검증 통합, warning 수준 이상 오류 0건 | Medium |

---

## 8. Implementation Strategy

### 8.1 Sprint 실행 계획

```
Sprint 1 (Critical Security) ─── 즉시 착수
  ├── S1-WP1: OAuth + CSRF 방지 (FR-S1-01, FR-S1-08)
  ├── S1-WP2: 인젝션 방지 (FR-S1-02, FR-S1-03, FR-S1-09, FR-S1-10, FR-S1-12)
  ├── S1-WP3: 자격증명 보안 (FR-S1-04~07)
  └── S1-WP4: 무결성 검증 (FR-S1-11)

Sprint 2 (Platform) ─── Sprint 1 완료 후
  ├── S2-WP1: 크로스 플랫폼 (FR-S2-01, FR-S2-10, FR-S2-11)
  │   └── **PG-02**: FR-S2-04는 FR-S2-01 완료 후 착수 (직렬 의존성)
  │   └── **PG-03**: FR-S2-09는 FR-S2-05 완료 후 착수 (동일 파일 직렬)
  ├── S2-WP2: 인스톨러 버그 (FR-S2-02, FR-S2-03, FR-S2-04, FR-S2-05~09)
  └── S2-WP3: Gap Analysis #1 (Sprint 1+2 검증)

Sprint 3 (Quality) ─── Sprint 2 완료 후
  ├── S3-WP1: 테스트 기반 구축 (FR-S3-01, FR-S3-02, FR-S3-06)
  ├── S3-WP2: CI/CD 자동화 (FR-S3-03, FR-S3-04, FR-S3-09) + ShellCheck CI 통합
  ├── S3-WP3: 코드 품질 (FR-S3-05a, FR-S3-05b, FR-S3-07, FR-S3-08)
  │   └── FR-S3-05a(인스톨러) → FR-S3-05b(Google MCP) 순차 리팩토링
  └── S3-WP4: 보안 품질 (FR-S3-10: 보안 이벤트 로깅, OWASP A09 대응)

Sprint 4 (Google MCP) ─── Sprint 3과 병렬 가능
  ├── S4-WP1: 안정성 (FR-S4-01, FR-S4-05, FR-S4-06)
  │   └── **PG-04**: FR-S4-04(캐싱)는 FR-S4-05(토큰 검증) + FR-S4-06(뮤텍스) 완료 후 착수 (직렬 의존성)
  ├── S4-WP2: 국제화/캐싱 (FR-S4-02, FR-S4-03, FR-S4-04)
  └── S4-WP3: 인프라/기능 (FR-S4-07~10)

Sprint 5 (UX & Docs) ─── Sprint 3+4 완료 후
  ├── S5-WP1: 사용자 경험 (FR-S5-01, FR-S5-02)
  ├── S5-WP2: 문서화 (FR-S5-03~05)
  └── S5-WP3: 최종 Gap Analysis + Completion Report
```

### 8.2 분석서 이슈 → 요구사항 매핑 (전수 추적)

| 분석 이슈 ID | 심각도 | 요구사항 ID | Sprint |
|:----------:|:------:|:----------:|:------:|
| SEC-01 | Critical | FR-S1-03 (osascript 인젝션), **FR-S1-11** (SHA-256 체크섬), Out of Scope (GPG) | S1 |
| SEC-02 | Critical | FR-S1-04 | S1 |
| SEC-03 | Critical | FR-S1-05 | S1 |
| SEC-04 | High | FR-S1-07 | S1 |
| SEC-05 | High | FR-S1-06 | S1 |
| SEC-06 | High | FR-S2-10 | S2 |
| SEC-07 | High | FR-S4-02 | S4 |
| SEC-08 | High | FR-S1-01 | S1 |
| SEC-08a | High | FR-S1-03 | S1 |
| SEC-09 | Medium | FR-S1-09 | S1 |
| SEC-10 | Medium | FR-S5-06 | S5 |
| SEC-11 | Medium | Out of Scope (서드파티 이미지 검증) | - |
| SEC-12 | Medium | FR-S1-09 | S1 |
| SEC-13 | Medium | FR-S1-04 (환경변수 전환으로 해결) | S1 |
| SEC-14 | Medium | FR-S1-08 | S1 |
| INS-01 | High | FR-S2-01 | S2 |
| INS-02 | Medium | FR-S2-03 | S2 |
| INS-03 | Medium | FR-S5-02 | S5 |
| INS-04 | Low | FR-S2-07 | S2 |
| INS-05 | Medium | FR-S2-04 | S2 |
| INS-06 | Low | FR-S5-03 | S5 |
| INS-07 | High | FR-S2-02 | S2 |
| INS-08 | Medium | FR-S2-05 | S2 |
| INS-09 | Medium | FR-S2-06 | S2 |
| INS-10 | Low | FR-S2-08 | S2 |
| GWS-01 | Medium | FR-S4-05 | S4 |
| GWS-02 | Medium | FR-S4-01 | S4 |
| GWS-03 | Low | FR-S3-08, FR-S5-05 | S3/S5 |
| GWS-04 | Low | FR-S3-07 | S3 |
| GWS-05 | Medium | FR-S4-06 | S4 |
| GWS-06 | Low | FR-S5-04 | S5 |
| GWS-07 | High | FR-S1-02 | S1 |
| GWS-08 | Medium | FR-S1-10 | S1 |
| GWS-09 | Medium | FR-S4-03 | S4 |
| GWS-10 | Medium | FR-S4-07 | S4 |
| GWS-11 | Low | FR-S4-08 | S4 |
| GWS-12 | Low | FR-S4-10 | S4 |
| OS-01 | High | FR-S2-01 | S2 |
| OS-02 | Medium | FR-S2-04 | S2 |
| OS-05 | Medium | (문서화로 대응) | S5 |
| OS-06 | High | **FR-S2-11** (Docker Desktop 버전 호환성 체크) | S2 |
| OS-07 | Medium | FR-S2-09 | S2 |
| OS-08 | Medium | FR-S4-09 | S4 |
| QA-01 | Critical | FR-S3-01, FR-S3-02 | S3 |
| QA-02 | High | FR-S3-03 | S3 |
| QA-03 | Medium | FR-S3-05a, FR-S3-05b | S3 |
| QA-04 | Medium | FR-S5-02 | S5 |
| QA-05 | Low | (구조적 로깅은 Out of Scope, 단 보안 로깅은 **FR-S3-10**으로 대응) | S3/- |
| QA-06 | Medium | FR-S3-05a, FR-S3-05b | S3 |
| QA-07 | Medium | FR-S4-04 | S4 |
| QA-08 | Low | FR-S3-06 | S3 |
| QA-09 | Low | Out of Scope (CHANGELOG 생성) | - |

> **추적 결과**: 분석서 총 48건 이슈 중 **45건 대응** (93.8%), 3건 Out of Scope (SEC-11, QA-05, QA-09)
> v2.1 신규 FR(S1-11, S1-12, S2-11, S3-09, S3-10) 추가로 커버리지 89.6% → 93.8% 향상
>
> **v2.2 추가 검증**: 3개 갭 분석 보고서(보안 검증, 공유 유틸리티, 요구사항 추적) 전수 교차 검증 완료.
> - 보안 검증 갭 6개 계획서 보완사항(P-01~P-06): 전수 반영 (v2.1에서 5건 반영, v2.2에서 1건 추가 보완)
> - 공유 유틸리티 갭 15개 계획서 항목(P-1~P-15): 전수 반영 (FR-S3-05a/b 세분화, R-08 추가, 정량적 기대효과 포함)
> - 요구사항 추적 갭 19개 항목: High 4건 전수 반영, Medium 7건 전수 반영, Low 8건 중 6건 반영(Pencil 보안검토/i18n 방향은 별도 검토)

---

## 9. Detailed Remediation Approaches

### 9.1 Sprint 1 핵심 구현 가이드

#### FR-S1-01: OAuth state 파라미터 (oauth.ts)

**현재 코드** (`oauth.ts:113-118`):
```typescript
const authUrl = oauth2Client.generateAuthUrl({
  access_type: "offline",
  scope: SCOPES,
  prompt: "consent",
});
```

**개선 방향**:
```typescript
import crypto from "crypto";

const state = crypto.randomBytes(32).toString("hex");
const authUrl = oauth2Client.generateAuthUrl({
  access_type: "offline",
  scope: SCOPES,
  prompt: "consent",
  state,
});
// 콜백에서 state 검증:
// if (url.searchParams.get("state") !== state) reject("State mismatch");
```

#### FR-S1-02: Drive API 쿼리 이스케이핑 (drive.ts)

**현재 코드** (`drive.ts:18`):
```typescript
let q = `name contains '${query}' and trashed = false`;
```

**개선 방향**:
```typescript
const escapedQuery = query.replace(/\\/g, "\\\\").replace(/'/g, "\\'");
let q = `name contains '${escapedQuery}' and trashed = false`;
```

#### FR-S1-03: parse_json() osascript 인젝션 방지 (install.sh)

**현재 코드** (`install.sh:29-39`):
```bash
parse_json() {
    local json="$1"
    osascript -l JavaScript -e "
        var obj = JSON.parse(\`$json\`);  # backtick 인젝션 취약
```

**개선 방향** (Sprint 2 FR-S2-01과 통합):
```bash
parse_json() {
    local json="$1"
    local key="$2"
    # node -e 방식 (stdin으로 JSON 전달, 인젝션 불가)
    echo "$json" | node -e "
        const chunks = [];
        process.stdin.on('data', c => chunks.push(c));
        process.stdin.on('end', () => {
            const obj = JSON.parse(chunks.join(''));
            const keys = process.argv[1].split('.');
            let val = obj;
            for (const k of keys) val = val ? val[k] : undefined;
            console.log(val === undefined ? '' : String(val));
        });
    " "$key" 2>/dev/null || echo ""
}
```

#### FR-S1-06: Docker non-root 사용자 (Dockerfile)

**현재 코드** — root로 실행:
```dockerfile
CMD ["node", "dist/index.js"]
```

**개선 방향**:
```dockerfile
# Production stage에 추가:
RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 --ingroup app app && \
    chown -R app:app /app
USER app
CMD ["node", "dist/index.js"]
```

### 9.2 Sprint 2 핵심 구현 가이드

#### FR-S2-01: 크로스 플랫폼 JSON 파서

```bash
parse_json() {
    local json="$1"
    local key="$2"

    # 우선순위: node > python3 > osascript(macOS only)
    if command -v node > /dev/null 2>&1; then
        echo "$json" | node -e "..." "$key"
    elif command -v python3 > /dev/null 2>&1; then
        echo "$json" | python3 -c "
import json, sys
obj = json.load(sys.stdin)
keys = sys.argv[1].split('.')
val = obj
for k in keys:
    val = val.get(k, '') if isinstance(val, dict) else ''
print(val if val else '')
" "$key"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS 폴백 (기존 방식 유지하되 stdin 방식으로 개선)
        echo "$json" | osascript -l JavaScript -e "..."
    else
        echo "Error: node or python3 required" >&2
        return 1
    fi
}
```

#### FR-S2-02: 원격 실행 시 shared 스크립트 다운로드

`install.sh`의 `run_module()` 함수에 원격 모드용 사전 다운로드 로직 추가:

```bash
run_module() {
    local module_name=$1
    # ...
    if [ "$USE_LOCAL" = false ]; then
        # 원격 모드: shared 스크립트를 임시 디렉토리에 다운로드
        local tmp_dir=$(mktemp -d)
        mkdir -p "$tmp_dir/shared"
        curl -sSL "$BASE_URL/modules/shared/oauth-helper.sh" \
            -o "$tmp_dir/shared/oauth-helper.sh" 2>/dev/null || true
        # SCRIPT_DIR를 임시 디렉토리로 설정하여 source 경로 해결
        export INSTALLER_SHARED_DIR="$tmp_dir/shared"
        # 모듈 스크립트에서 INSTALLER_SHARED_DIR 환경변수 우선 사용
    fi
}
```

---

## 10. Next Steps

1. [ ] Plan 문서 리뷰 및 승인
2. [ ] Design 문서 작성 (`/pdca design adw-improvement`)
3. [ ] Sprint 1 착수 — Critical Security 이슈 즉시 수정
4. [ ] Sprint 1 완료 후 Gap Analysis 실행 (`/pdca analyze adw-improvement`)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-12 | Initial draft -- CTO Team 8-agent parallel analysis | CTO Team |
| 2.0 | 2026-02-12 | adw-comprehensive.analysis.md 기반 44개 요구사항 수립 | CTO Team |
| 2.1 | 2026-02-12 | 3개 추가 분석문서 + 3개 갭 분석 반영. 신규 FR 5건(S1-11, S1-12, S2-11, S3-09, S3-10), FR-S3-05 세분화(5a/5b), R-08 리스크 추가, 개별 공수 추정, 정량적 기대 효과, Sprint 실행 계획 | CTO Team |
| 2.2 | 2026-02-13 | 7개 분석문서 전수 교차 검증 완료. FR-S1-04 우선순위 Critical 정정(P-02), FR-S2-10 우선순위 High 복원(P-03), FR-S2-02 임시파일 정리 보장(trap 패턴), FR-S3-05a/b 함수명 상세화(29+7개 함수 확정), PG-02/PG-04 직렬 의존성 명시, NFR 3건 추가(ShellCheck/npm audit/보안로깅), Convention 3건 추가(Env/Schema/ShellCheck), Out of Scope 정밀화(In Scope 전환 이력), References 7개 분석문서 전체 목록, Sprint 2 합계 재산출 | CTO Lead |

---

## Appendix A: CTO Team Verification Summary

### A.1 Security Architect 검증 결과

| 보고 ID | 보고 심각도 | 검증 심각도 | 상태 | 비고 |
|---------|:----------:|:----------:|:----:|------|
| SEC-01 | Critical | **Critical** | Confirmed | MITM 시 원격 코드 실행 가능 |
| SEC-02 | Critical | **Critical** | Confirmed | `.mcp.json`에 API 토큰 평문 기록 |
| SEC-03 | Critical | **Informational** | **Downgraded** | `{accessToken}`은 템플릿 플레이스홀더, 디스크 미기록 |
| SEC-04 | High | **High** | Confirmed | `token.json` 파일 권한 644 (타 사용자 읽기 가능) |
| SEC-05 | High | **High** | Confirmed | Docker 컨테이너 root 실행 |
| SEC-06 | High | **High** | Confirmed | Windows 전 모듈에 관리자 권한 요구 |
| SEC-07 | High | **High** | Confirmed | 6개 서비스 스코프 무조건 전체 요청 |
| SEC-08 | High | **High** | Confirmed | OAuth state 파라미터 누락 (CSRF) |
| SEC-08a | High | **High** | Confirmed | backtick 인젝션으로 임의 JS 실행 가능 |
| GWS-07 | High | **High** | Confirmed | Drive 쿼리에 `'` 미이스케이핑 |
| GWS-08 | Medium | **Medium** | Confirmed | CRLF로 이메일 헤더 인젝션 가능 |
| SEC-12 | Medium | **Medium** | Confirmed | `node -e`에 사용자 입력 직접 삽입 |

> 추가 발견: 입력 검증 레이어 부재, 보안 로깅 미구현, `npm audit` 미적용

### A.2 Code Analyzer 검증 결과

| 보고 ID | 보고 심각도 | 검증 심각도 | 상태 | 비고 |
|---------|:----------:|:----------:|:----:|------|
| INS-01 | High | **High** | Confirmed | `osascript` macOS 전용, Linux 모듈 로딩 불가 |
| INS-02 | Medium | **High** | **Upgraded** | Mac 3개 파일 경로 불일치 (commit b8b01a2 Windows만 변경) |
| INS-03 | Medium | **Medium** | Confirmed | 롤백 메커니즘 부재 |
| INS-07 | High | **High** | Confirmed | 원격실행 시 oauth-helper.sh 미다운로드 |
| INS-08 | Medium | **Medium** | Confirmed | Figma module.json이 npx 방식이나 실제는 Remote MCP |
| INS-09 | Medium | **Low** | **Downgraded** | `docker: false`는 Rovo 경로 고려한 설계 의도 |
| GWS-01 | Medium | **Medium** | Confirmed | 만료 버퍼 없음 + expiry_date 미존재 케이스 미처리 |
| GWS-02 | Medium | **Medium** | Confirmed | 69개 핸들러 전부 Rate Limit 없음 |
| GWS-05 | Medium | **Medium** | Confirmed | 동시 인증 시 EADDRINUSE 가능 |
| GWS-07 | High | **High** | Confirmed | drive_search + drive_list + mimeType 3곳 |
| GWS-09 | Medium | **Medium** | Confirmed | 4곳에 `Asia/Seoul` 하드코딩 |
| GWS-10 | Medium | **Medium** | Confirmed | 중첩 multipart 미파싱 |
| QA-01 | Critical | **Critical** | Confirmed | 0 test files, 0 test infrastructure |
| QA-06 | Medium | **Medium** | Confirmed | 컬러 9파일 중복, MCP config 2곳, parseTime 2곳 |
| QA-07 | Medium | **Medium** | Confirmed | 69 핸들러마다 6개 서비스 재생성 |

> 추가 발견: `any` 타입 `sheets.ts:18,341`, `calendar.ts:288`, `slides.ts:135,156`에서도 사용

### A.3 Enterprise Expert 검증 결과

| 보고 ID | 보고 심각도 | 검증 심각도 | 상태 | 비고 |
|---------|:----------:|:----------:|:----:|------|
| OS-01 | High | **Critical** | **Upgraded** | install.sh 전체가 Linux에서 비기능적 |
| OS-02 | Medium | **Medium** | Confirmed | apt/snap만 지원, github 모듈만 dnf 지원 |
| OS-05 | Medium | **Low** | **Downgraded** | WSL 재시작 가이드 이미 구현됨 |
| OS-06 | High | **High** | Confirmed | Docker Desktop 4.42+ macOS Ventura 미지원 |
| OS-07 | Medium | **Medium** | Confirmed | 3개 모듈에서 python3 필수이나 module.json 미표기 |
| OS-08 | Medium | **High** | **Upgraded** | Node.js 20 EOL 77일 남음 (2026-04-30) |
| INS-04 | Low | **Low** | Confirmed | PowerShell은 정렬 구현, Shell은 미구현 |
| INS-05 | Medium | (중복) | = OS-02 | 동일 이슈 |
| INS-10 | Low | **Low** | Confirmed | `docker wait` 타임아웃 없음 |

> 핵심 발견: **PowerShell 구현이 Shell보다 모든 차원에서 견고** — JSON 파싱(네이티브), 모듈 정렬(구현), 에러 처리(`try/catch`), 패키지 관리자(winget 유니버설)

### A.4 종합 노력 추정

| 분류 | 보안 에이전트 | 코드 분석 에이전트 | 엔터프라이즈 에이전트 | 합계 |
|------|:-----------:|:----------------:|:------------------:|:----:|
| Critical Path | 12-16h | 7-8h | 7-13h | **26-37h** |
| 전체 | 34-49h | 40-55h | 18-32h | **92-136h** |
