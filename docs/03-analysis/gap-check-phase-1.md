# ADW Improvement Gap Analysis -- Check Phase 1

> **Summary**: 48개 FR 전수 검증 결과, 37개 완전 구현 / 6개 부분 구현 / 5개 미구현
>
> **Feature**: adw-improvement
> **Version**: Check-1.0
> **Date**: 2026-02-13
> **Author**: CTO Lead (gap-detector + code-analyzer + qa-strategist 협업)
> **Plan Reference**: `docs/01-plan/features/adw-improvement.plan.md` (v2.2)
> **Design Reference**: `docs/02-design/features/adw-improvement.design.md` (v1.2)

---

## 전체 Match Rate: 77.1%

| 구분 | FR 수 | 비율 |
|------|:-----:|:----:|
| 완전 구현 (100%) | 37 | 77.1% |
| 부분 구현 (50%) | 6 | 12.5% |
| 미구현 (0%) | 5 | 10.4% |
| **합계** | **48** | |

**가중 점수**: (37 x 100 + 6 x 50 + 5 x 0) / 48 = **83.3%**

---

## Sprint별 상세

### Sprint 1 -- Critical Security (12 FRs)

| FR ID | 요구사항 | 구현 상태 | 일치도 | 미달 사항 |
|-------|---------|:---------:|:------:|----------|
| FR-S1-01 | OAuth state 파라미터 추가 | 완전 구현 | 100% | 없음. `crypto.randomBytes(32)` state 생성, 콜백에서 검증, 실패 시 403 응답 + 보안 로그. 설계서와 정확히 일치 |
| FR-S1-02 | Drive API 쿼리 이스케이핑 | 완전 구현 | 100% | 없음. `escapeDriveQuery()` + `validateDriveId()` 구현. `drive.ts`의 `drive_search`, `drive_list` 등 전체 핸들러에 적용 |
| FR-S1-03 | osascript 템플릿 인젝션 방지 | 완전 구현 | 100% | 없음. `parse_json()` stdin 파이프 방식으로 완전 교체. node > python3 > osascript 폴백 체인 구현 |
| FR-S1-04 | Atlassian API 토큰 보안 저장 | 완전 구현 | 100% | 없음. `.env` 파일 분리, `chmod 600`, `--env-file` 방식 MCP 설정. 설계서와 정확히 일치 |
| FR-S1-05 | Figma 토큰 보안 저장 | 완전 구현 | 100% | 없음. Informational (템플릿 플레이스홀더 확인). 코드 변경 불필요 |
| FR-S1-06 | Docker non-root 사용자 추가 | 완전 구현 | 100% | 없음. `groupadd -r mcp && useradd -r -g mcp` + `USER mcp`. HEALTHCHECK 포함. 설계서와 일치 |
| FR-S1-07 | token.json 파일 권한 설정 | 완전 구현 | 100% | 없음. `writeFileSync` mode 0o600 + 방어적 `chmodSync` + 보안 로깅 |
| FR-S1-08 | 설정 디렉토리 권한 설정 | 완전 구현 | 100% | 없음. `mkdirSync` mode 0o700 + 방어적 chmod 검사/복구. Windows 예외 처리 포함 |
| FR-S1-09 | Atlassian install.sh 변수 이스케이핑 | 완전 구현 | 100% | 없음. `--env-file` 패턴으로 FR-S1-04와 통합 해결. Node.js `-e` 블록에 사용자 입력 미삽입 |
| FR-S1-10 | Gmail 이메일 헤더 인젝션 방지 | 완전 구현 | 100% | 없음. `sanitizeEmailHeader()` 구현 + `gmail_send`, `gmail_draft_create`에 적용 |
| FR-S1-11 | 원격 스크립트 다운로드 무결성 검증 | 완전 구현 | 100% | 없음. `download_and_verify()` 함수, `checksums.json`, `generate-checksums.sh`, CI `verify-checksums` job 구현 |
| FR-S1-12 | 입력 검증 레이어 구축 | 완전 구현 | 100% | 없음. `sanitize.ts` 7개 함수 모두 구현: `escapeDriveQuery`, `validateDriveId`, `sanitizeEmailHeader`, `validateEmail`, `validateMaxLength`, `sanitizeFilename`, `sanitizeRange` |

**Sprint 1 Match Rate: 100% (12/12 완전 구현)**

---

### Sprint 2 -- Platform & Stability (11 FRs)

| FR ID | 요구사항 | 구현 상태 | 일치도 | 미달 사항 |
|-------|---------|:---------:|:------:|----------|
| FR-S2-01 | 크로스 플랫폼 JSON 파서 구현 | 완전 구현 | 100% | 없음. node > python3 > osascript 폴백 체인. FR-S1-03과 통합 구현 |
| FR-S2-02 | 원격 실행 시 shared 스크립트 다운로드 | 부분 구현 | 50% | `download_and_verify()` 기반 원격 다운로드 메커니즘은 존재하나, shared 스크립트 사전 다운로드 로직(`SHARED_TMP` + `trap cleanup`)이 `run_module()`에 **미구현**. 모듈 스크립트들이 shared를 source하지 않으므로 실질적 영향은 낮음 |
| FR-S2-03 | MCP 설정 경로 통일 | 완전 구현 | 100% | 없음. `google/install.sh`, `atlassian/install.sh` 모두 `~/.claude/mcp.json` 사용. 레거시 마이그레이션 로직 포함 |
| FR-S2-04 | Linux 패키지 관리자 확장 | 완전 구현 | 100% | 없음. `base/install.sh`에 `apt-get`, `dnf`, `pacman` 분기 구현. `package-manager.sh`에도 통합 |
| FR-S2-05 | Figma module.json 정합성 수정 | 부분 구현 | 50% | `type: "remote-mcp"`, `node: false` 적용됨. 그러나 `python3: true` **미추가** (설계서 FR-S2-09 연계) |
| FR-S2-06 | Atlassian module.json Docker 표기 수정 | 미구현 | 0% | `docker: true` 유지, `modes` 필드 **미추가**. 현재 module.json에 Docker/Rovo 듀얼 모드 표현 없음 |
| FR-S2-07 | 모듈 실행 순서 정렬 | 완전 구현 | 100% | 없음. `MODULE_ORDERS` 기반 `sort -t: -k1 -n` 정렬 구현 |
| FR-S2-08 | Docker wait 타임아웃 추가 | 완전 구현 | 100% | 없음. `google/install.sh`에 300초 타임아웃 폴링 루프 구현 |
| FR-S2-09 | Python 3 의존성 module.json 명시 | 미구현 | 0% | Notion, Figma module.json에 `python3: true` **미추가** |
| FR-S2-10 | Windows 관리자 권한 조건부 요청 | 완전 구현 | 100% | 없음. `Test-AdminRequired` 함수, 모듈별 관리자 필요성 판단 구현 |
| FR-S2-11 | Docker Desktop 버전 호환성 체크 | 완전 구현 | 100% | 없음. `docker_check_compatibility()` 함수, macOS 버전 교차 검증, `docker_check()` 내 자동 호출 |

**Sprint 2 Match Rate: 72.7% (8 완전 + 2 부분 + 1 미구현)**

---

### Sprint 3 -- Quality & Testing (10 FRs)

| FR ID | 요구사항 | 구현 상태 | 일치도 | 미달 사항 |
|-------|---------|:---------:|:------:|----------|
| FR-S3-01 | Google MCP 유닛 테스트 작성 | 부분 구현 | 50% | 테스트 파일 5개 존재(`gmail.test.ts`, `sanitize.test.ts`, `retry.test.ts`, `time.test.ts`, `mime.test.ts`). 그러나 **도구 파일별 테스트 미작성**(drive, calendar, docs, sheets, slides). 유틸리티 테스트 위주이며 목표 커버리지 60% 미달 가능성 높음 |
| FR-S3-02 | 인스톨러 Smoke 테스트 작성 | 완전 구현 | 100% | 없음. 4개 테스트 파일: `test_framework.sh`, `test_module_json.sh`, `test_install_syntax.sh`, `test_module_ordering.sh` |
| FR-S3-03 | CI 자동 트리거 추가 | 완전 구현 | 100% | 없음. `push: [master, develop]` + `pull_request: [master]` 트리거. lint, build, test, smoke-tests, security-audit, shellcheck, docker-build, verify-checksums 전체 파이프라인 |
| FR-S3-04 | CI 테스트 범위 확장 | 완전 구현 | 100% | 없음. smoke-tests job에서 전체 `installer/tests/` 실행. module_json 테스트가 전 모듈 커버 |
| FR-S3-05a | 인스톨러 공유 유틸리티 추출 | 부분 구현 | 50% | 5개 shared 스크립트 모두 생성됨(`colors.sh`, `docker-utils.sh`, `mcp-config.sh`, `browser-utils.sh`, `package-manager.sh`). 그러나 **7개 모듈 스크립트가 실제로 source하지 않음**. 인라인 색상 정의가 `base/install.sh`, `atlassian/install.sh` 등에 여전히 존재. 수용 기준 5개 중 0개 충족 |
| FR-S3-05b | Google MCP 공유 유틸리티 추출 | 부분 구현 | 50% | 5개 유틸리티 파일 모두 생성됨(`time.ts`, `retry.ts`, `sanitize.ts`, `mime.ts`, `messages.ts`). `time.ts`는 `calendar.ts`에서 import 확인. 그러나 **(1) withRetry() 미적용** -- 도구 파일 어디에서도 import하지 않음, **(2) mime.ts 미통합** -- `gmail.ts`가 자체 MIME 파싱 유지, **(3) messages.ts 미통합** -- 도구 파일에서 import하지 않음. 수용 기준 5개 중 2개 충족(parseTime 통합, sanitize 적용) |
| FR-S3-06 | ESLint + Prettier 설정 | 완전 구현 | 100% | 없음. `eslint.config.js` (flat config), `.prettierrc` 구성 완료. `package.json`에 lint/format 스크립트 포함 |
| FR-S3-07 | `any` 타입 제거 | 완전 구현 | 100% | 없음. `index.ts:32`의 `params: any` -> `params: Record<string, unknown>`, 기타 위치의 `any` 제거 확인 |
| FR-S3-08 | 에러 메시지 영문 통일 | 완전 구현 | 100% | 없음. `index.ts`의 "오류:" -> "Error:", "서버 시작 실패:" -> "Server startup failed:" 확인 |
| FR-S3-09 | npm audit CI 통합 | 완전 구현 | 100% | 없음. `security-audit` job: `npm audit --audit-level=high` 구현 |

**Sprint 3 Match Rate: 80% (7 완전 + 3 부분)**

---

### Sprint 4 -- Google MCP Hardening (10 FRs)

| FR ID | 요구사항 | 구현 상태 | 일치도 | 미달 사항 |
|-------|---------|:---------:|:------:|----------|
| FR-S4-01 | Google API Rate Limiting 구현 | 부분 구현 | 50% | `retry.ts`에 `withRetry()` 함수가 올바르게 구현됨(지수 백오프, 429/500/502/503/504, 네트워크 에러). 그러나 **실제 도구 핸들러에 적용되지 않음**. 6개 도구 파일 전체에서 `withRetry` import 없음 |
| FR-S4-02 | OAuth 스코프 동적 설정 | 완전 구현 | 100% | 없음. `SCOPE_MAP` + `resolveScopes()` + `GOOGLE_SCOPES` 환경변수 지원 |
| FR-S4-03 | Calendar 타임존 동적화 | 완전 구현 | 100% | 없음. `time.ts`의 `getTimezone()` + `TIMEZONE` 환경변수. `calendar.ts`에서 `import { getTimezone, parseTime }` 확인. `Asia/Seoul` 하드코딩 0건 |
| FR-S4-04 | getGoogleServices() 싱글톤/캐싱 | 완전 구현 | 100% | 없음. TTL 50분 캐싱, `ServiceCache` 인터페이스, `clearServiceCache()` 테스트 유틸리티 |
| FR-S4-05 | Token refresh_token 유효성 검증 | 완전 구현 | 100% | 없음. `loadToken()`에서 `refresh_token` 존재 여부 확인, 5분 expiry buffer 구현 |
| FR-S4-06 | 동시 인증 요청 처리 | 완전 구현 | 100% | 없음. `authInProgress` Promise 기반 뮤텍스, `finally` 블록에서 null 초기화 |
| FR-S4-07 | Gmail 중첩 MIME 파싱 개선 | 부분 구현 | 50% | `mime.ts`에 `extractTextBody()`, `extractAttachments()` 재귀 파싱 올바르게 구현됨. 그러나 **`gmail.ts`에서 import하지 않음**. `gmail_read` 핸들러가 여전히 자체 1단계 `parts` 파싱 사용 |
| FR-S4-08 | Gmail 첨부파일 다운로드 개선 | 완전 구현 | 100% | 없음. `gmail_attachment_get` 핸들러에서 `response.data.data` 전체 반환 (1000자 절삭 코드 제거 확인) |
| FR-S4-09 | Node.js 22 마이그레이션 | 완전 구현 | 100% | 없음. Dockerfile `FROM node:22-slim`, `@types/node: ^22.0.0` |
| FR-S4-10 | .dockerignore 추가 | 완전 구현 | 100% | 없음. `.google-workspace/`, `node_modules/`, `.git/`, `.env*`, `client_secret.json`, `token.json` 등 포함 |

**Sprint 4 Match Rate: 85% (8 완전 + 2 부분)**

---

### Sprint 5 -- UX & Documentation (6 FRs)

| FR ID | 요구사항 | 구현 상태 | 일치도 | 미달 사항 |
|-------|---------|:---------:|:------:|----------|
| FR-S5-01 | 설치 후 자동 검증 | 완전 구현 | 100% | 없음. `verify_module_installation()` 함수, MCP config 검증, Docker 이미지 검증 구현 |
| FR-S5-02 | 롤백 메커니즘 도입 | 완전 구현 | 100% | 없음. `backup_mcp_config()`, `rollback_mcp_config()`, 실패 시 자동 롤백, 성공 시 백업 삭제 |
| FR-S5-03 | ARCHITECTURE.md 동기화 | 미구현 | 0% | Pencil 모듈, `shared/` 디렉토리, Remote MCP 타입 **미추가**. 현재 ARCHITECTURE.md에 `shared/`, `pencil` 언급 없음 |
| FR-S5-04 | package.json 버전 업데이트 | 완전 구현 | 100% | 없음. `version: "1.0.0"` 확인 |
| FR-S5-05 | Google MCP 도구 메시지 영문화 | 미구현 | 0% | `messages.ts` 파일은 존재하나, 6개 도구 파일에서 **import하지 않음**. 도구 description이 여전히 한국어(예: "Google Drive에서 파일을 검색합니다"). `messages.ts` 중앙 관리 구조가 실제 적용되지 않음 |
| FR-S5-06 | .gitignore 보강 | 완전 구현 | 100% | 없음. `client_secret.json`, `token.json`, `.env`, `.env.local`, `.env.*.local`, `credentials.env` 패턴 모두 포함 |

**Sprint 5 Match Rate: 66.7% (4 완전 + 2 미구현)**

---

## 미달 항목 목록 (Act Phase 대상)

| # | FR ID | 미달 사항 | 우선순위 | 예상 작업량 | 비고 |
|---|-------|----------|:--------:|:---------:|------|
| 1 | FR-S3-05a | **공유 유틸리티 미적용**: 5개 shared 스크립트 생성 완료, 그러나 7개 모듈 스크립트가 source하지 않음. 인라인 색상 정의/Docker 체크/MCP 설정/브라우저 열기 중복 코드 잔존 | **High** | 4-6h | 수용 기준 5개 중 0개 충족. 리팩토링 범위가 크므로 별도 Act 반복 |
| 2 | FR-S3-05b (withRetry) | **withRetry() 미적용**: `retry.ts` 구현 완료, 그러나 6개 도구 파일(gmail, drive, calendar, docs, sheets, slides)의 ~80개 API 호출에 미적용 | **High** | 3-4h | 기존 API 호출을 `withRetry(() => ...)` 래핑 필요 |
| 3 | FR-S3-05b (mime.ts) | **mime.ts 미통합**: 재귀 파싱 함수 구현 완료, 그러나 `gmail.ts`가 여전히 자체 1단계 파싱 사용 | **Medium** | 1-2h | `gmail_read` 핸들러에서 `extractTextBody()`, `extractAttachments()` import |
| 4 | FR-S3-05b (messages.ts) | **messages.ts 미통합**: 8개 카테고리 메시지 정의 완료, 그러나 도구 파일에서 import하지 않음 | **Low** | 2-3h | Sprint 5 FR-S5-05와 동시 작업 |
| 5 | FR-S5-05 | **도구 메시지 한국어 잔존**: 6개 도구 파일의 `description` 및 응답 `message`가 한국어. `messages.ts` 활용 미적용 | **Low** | 4-6h | FR-S3-05b messages.ts 통합과 함께 수행 |
| 6 | FR-S5-03 | **ARCHITECTURE.md 미업데이트**: Pencil 모듈, shared/ 디렉토리, Remote MCP 타입, 실행 순서 섹션 미추가 | **Low** | 1-2h | 문서 업데이트만 필요 |
| 7 | FR-S2-06 | **Atlassian module.json modes 필드 미추가**: Docker/Rovo 듀얼 모드 표현 없음 | **Low** | 0.5h | `modes: ["docker", "rovo"]` 필드 추가 |
| 8 | FR-S2-09 | **Python 3 의존성 미명시**: Notion, Figma module.json에 `python3` 필드 없음 | **Low** | 0.5h | 각 module.json에 `"python3": true` 추가 |
| 9 | FR-S2-05 | **Figma module.json python3 미추가**: `type: "remote-mcp"`, `node: false` 적용, 그러나 `python3: true` 누락 | **Low** | 0.5h | FR-S2-09와 동시 수행 |
| 10 | FR-S2-02 | **원격 shared 스크립트 사전 다운로드 미구현**: `SHARED_TMP` + `trap cleanup` 패턴 미적용 | **Low** | 1-2h | FR-S3-05a 리팩토링과 함께 수행 |
| 11 | FR-S3-01 | **유닛 테스트 커버리지 부족**: 유틸리티 테스트 5개만 존재. 도구별 핵심 로직 테스트 미작성 | **Medium** | 8-12h | drive, calendar, docs, sheets, slides 테스트 추가 |

---

## 카테고리별 Gap 분석

### 보안 (Sprint 1): 100% -- 전수 구현 완료

Sprint 1의 12개 보안 FR이 모두 설계서와 정확히 일치하여 구현되었다. 특히 주목할 점:
- `sanitize.ts` 7개 함수 전수 구현 (FR-S1-12)
- SHA-256 체크섬 검증 + CI 자동 검증 (FR-S1-11)
- 보안 이벤트 로깅 (FR-S3-10, oauth.ts 내 `logSecurityEvent`)

### 플랫폼 호환성 (Sprint 2): 72.7% -- 3건 미달

핵심 이슈(크로스 플랫폼 JSON 파서, MCP 경로 통일, Linux 패키지 관리자)는 완료.
메타데이터 정합성 이슈(module.json 필드 추가) 3건이 미달. 모두 Low 우선순위.

### 코드 품질 (Sprint 3): 80% -- 공유 유틸리티 통합이 핵심

가장 큰 갭은 **공유 유틸리티 "생성은 완료, 통합은 미완료"** 패턴이다:
- 인스톨러: 5개 shared 스크립트 존재하나 7개 모듈이 source하지 않음
- Google MCP: `retry.ts`, `mime.ts`, `messages.ts` 존재하나 도구 파일에서 미사용

### API 안정성 (Sprint 4): 85% -- withRetry 적용이 핵심

`withRetry()` 함수 자체는 올바르게 구현되었으나, 실제 API 호출에 적용되지 않아 Rate Limiting 보호가 작동하지 않는 상태.

### UX/문서 (Sprint 5): 66.7% -- messages.ts + ARCHITECTURE.md

`messages.ts`가 도구 파일에 통합되지 않아 한국어 메시지가 잔존.

---

## 수용 기준 충족 현황

### Plan v2.2 Section 4 -- Definition of Done

| 기준 | 상태 | 비고 |
|------|:----:|------|
| 모든 Critical/High 보안 이슈 해결 (FR-S1-01~12) | **충족** | 12/12 완전 구현 |
| Linux에서 `install.sh` 정상 동작 (FR-S2-01) | **충족** | node > python3 폴백 체인 구현 |
| Google MCP 유닛 테스트 60%+ 커버리지 (FR-S3-01) | **미확인** | 테스트 파일 5개 존재, 커버리지 실행 필요 |
| CI가 PR/push 시 자동 실행 (FR-S3-03) | **충족** | 8개 job 파이프라인 완성 |
| Gap Analysis Match Rate 90%+ 달성 | **미충족** | 현재 83.3%, 목표 90% 대비 -6.7pp |

### Design v1.2 Section 5.4 -- 공유 유틸리티 수용 기준

**인스톨러 (FR-S3-05a)**:
| # | 기준 | 충족 |
|---|------|:----:|
| 1 | 7개 인스톨러 모듈이 모두 shared/colors.sh를 source | 미충족 |
| 2 | 인라인 색상 정의 0건 | 미충족 |
| 3 | Docker 모듈이 docker_check() 사용 | 미충족 |
| 4 | MCP 모듈이 mcp_add_docker_server()/mcp_add_stdio_server() 사용 | 미충족 |
| 5 | 브라우저 모듈이 browser_open() 사용 | 미충족 |

**Google MCP (FR-S3-05b)**:
| # | 기준 | 충족 |
|---|------|:----:|
| 1 | calendar.ts 내 중복 parseTime() 0건 | **충족** |
| 2 | 69개 핸들러가 캐싱된 getGoogleServices() 사용 | **충족** |
| 3 | 모든 API 호출에 withRetry() 적용 | 미충족 |
| 4 | 사용자 입력이 sanitize 함수 통과 | **충족** (drive, gmail) |
| 5 | 하드코딩된 한국어 메시지 0건 | 미충족 |

---

## 우선순위별 Act Phase 작업 계획

### 즉시 (Match Rate 90% 달성 핵심)

| 작업 | FR | 예상 효과 | 공수 |
|------|-----|----------|------|
| withRetry() 도구 파일 적용 | FR-S4-01, FR-S3-05b | +4.2pp | 3-4h |
| mime.ts gmail.ts 통합 | FR-S4-07, FR-S3-05b | +2.1pp | 1-2h |
| 인스톨러 모듈 shared source 리팩토링 | FR-S3-05a | +4.2pp | 4-6h |

**예상 Match Rate 달성**: 83.3% + 10.5pp = **93.8%** (목표 90% 초과)

### 후속 (문서/메타데이터)

| 작업 | FR | 공수 |
|------|-----|------|
| messages.ts 통합 + 영문화 | FR-S5-05, FR-S3-05b | 4-6h |
| ARCHITECTURE.md 업데이트 | FR-S5-03 | 1-2h |
| module.json 필드 추가 (modes, python3) | FR-S2-06, FR-S2-09, FR-S2-05 | 1h |
| 도구별 유닛 테스트 추가 | FR-S3-01 | 8-12h |

---

## 정량적 기대 효과 검증

| 지표 | 계획 목표 | 현재 실측 | 달성도 |
|------|:--------:|:--------:|:------:|
| 보안 취약점 (Critical/High) | 0건 | **0건** | 100% |
| 테스트 커버리지 | 60%+ | 미측정 (5개 테스트 파일) | 미확인 |
| 서비스 인스턴스 생성 | 6회/TTL | **6회/TTL** (캐싱 구현) | 100% |
| 인스톨러 LOC 감소 | -29% | 미감소 (shared 미적용) | 0% |
| Google MCP LOC 감소 | -28% | 부분 감소 (일부 유틸 적용) | ~30% |
| Match Rate | 95%+ | **83.3%** | 87.7% |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| Check-1.0 | 2026-02-13 | 48개 FR 전수 검증 초회 실시. Match Rate 83.3% | CTO Lead |
