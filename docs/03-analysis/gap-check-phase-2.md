# ADW Improvement Gap Analysis -- Check Phase 2

> **Summary**: Act Phase Iterate 1 이후 48개 FR 재검증. 11개 미달 항목 중 8개 완전 해소, 3개 잔존(부분)
>
> **Feature**: adw-improvement
> **Version**: Check-2.0
> **Date**: 2026-02-13
> **Author**: gap-detector (Check Phase 2 재검증)
> **Plan Reference**: `docs/01-plan/features/adw-improvement.plan.md` (v2.2)
> **Design Reference**: `docs/02-design/features/adw-improvement.design.md` (v1.2)
> **Check Phase 1 Reference**: `docs/03-analysis/gap-check-phase-1.md`

---

## 전체 Match Rate: 93.8%

| 구분 | FR 수 | 비율 |
|------|:-----:|:----:|
| 완전 구현 (100%) | 45 | 93.8% |
| 부분 구현 (50%) | 3 | 6.2% |
| 미구현 (0%) | 0 | 0% |
| **합계** | **48** | |

**가중 점수**: (45 x 100 + 3 x 50 + 0 x 0) / 48 = **96.9%**

> Check Phase 1 대비: 77.1% -> 93.8% (+16.7pp), 가중 점수 83.3% -> 96.9% (+13.6pp)
> **목표 90%를 초과 달성**

---

## 이전 미달 항목 재검증 결과

| # | FR ID | Check Phase 1 | Check Phase 2 | 변경사항 |
|---|-------|:-------------:|:-------------:|----------|
| 1 | FR-S4-01 | 부분(50%) | **완전(100%)** | `withRetry()` 6개 도구 파일 전체 적용. 91개 `await withRetry()` 호출로 87개 API 메서드 호출 100% 래핑 확인 |
| 2 | FR-S4-07 | 부분(50%) | **완전(100%)** | `gmail.ts:5`에 `import { extractTextBody, extractAttachments } from "../utils/mime.js"` 확인. `gmail_read` 핸들러(line 79-85)에서 `extractTextBody(response.data.payload)` + `extractAttachments(response.data.payload)` 재귀 파싱 적용 |
| 3 | FR-S3-05a | 부분(50%) | **부분(50%)** | 수용 기준 5개 중 2개 충족 (상세 후술). 7개 모듈 모두 `source "$SHARED_DIR/colors.sh"` 적용(기준 1). 인라인 색상은 fallback else 블록으로 이동(기준 2 부분). 그러나 `docker_check()`, `mcp_add_docker_server()`, `browser_open()` 미사용(기준 3,4,5) |
| 4 | FR-S5-05 | 미구현(0%) | **완전(100%)** | 6개 도구 파일 전체에 `import { messages, msg } from "../utils/messages.js"` 적용. `msg()` 호출 11건 확인. 사용자 대면 `description` 전체 영문 전환. 잔존 한국어는 JSDoc 주석 4건(비기능적)만 존재 |
| 5 | FR-S3-01 | 부분(50%) | **부분(50%)** | 기존 유틸 테스트 4개(sanitize, retry, time, mime) + 도구 테스트 3개(gmail, drive, calendar) = 총 7개 테스트 파일. docs, sheets, slides 테스트 미작성. 목표 커버리지 60% 미확인 |
| 6 | FR-S2-02 | 부분(50%) | **완전(100%)** | `install.sh:553-569`에 `SHARED_TMP`, `setup_shared_dir()`, `trap 'rm -rf "$SHARED_TMP"' EXIT` 완전 구현. 원격 모드에서 `mktemp -d`로 임시 디렉토리 생성, 4개 shared 스크립트 다운로드, 정상/비정상 종료 시 cleanup 보장 |
| 7 | FR-S5-03 | 미구현(0%) | **완전(100%)** | `ARCHITECTURE.md`에 `shared/` 디렉토리 추가(line 117-123), Pencil 모듈 추가(line 112-115), Remote MCP 타입 추가(line 203-207), IDE Extension 타입 추가(line 209-217), 실행 순서 표 추가(line 221-234) |
| 8 | FR-S2-06 | 미구현(0%) | **완전(100%)** | `atlassian/module.json:12`에 `"modes": ["docker", "rovo"]` 필드 추가 확인 |
| 9 | FR-S2-09 | 미구현(0%) | **완전(100%)** | `notion/module.json:16`에 `"python3": true` 확인 |
| 10 | FR-S2-05 | 부분(50%) | **완전(100%)** | `figma/module.json`에 `"type": "remote-mcp"`, `"node": false`, `"python3": true`(line 17) 전부 확인 |
| 11 | FR-S3-05b | 부분(50%) | **부분(50%)** | 수용 기준 5개 중 4개 충족 (상세 후술). `parseTime` 통합, `getGoogleServices()` 캐싱, `withRetry()` 전면 적용, `sanitize` 적용 모두 확인. 그러나 하드코딩 한국어 메시지 기준은 JSDoc 주석 4건 잔존(기능적 영향 없으나 엄밀한 기준 적용 시 미충족) |

### 요약: 11개 미달 -> 8개 완전 해소, 3개 잔존(부분)

---

## 잔존 미달 항목

| # | FR ID | 미달 사항 | 현재 충족도 | 우선순위 | 비고 |
|---|-------|----------|:----------:|:--------:|------|
| 1 | FR-S3-05a | 공유 유틸리티 함수 미적용: 7개 모듈이 `colors.sh`를 source하지만 `docker_check()`, `mcp_add_docker_server()`, `browser_open()` 등 shared 함수를 사용하지 않음. 각 모듈이 여전히 인라인 Docker 체크/MCP 설정/브라우저 열기 로직 보유 | 2/5 기준 | **Low** | 색상 통합은 완료. 나머지 3개 기준(Docker/MCP/Browser 유틸리티 함수)은 리팩토링 규모가 크므로 별도 Sprint에서 처리 권장. 기능적 정합성에 영향 없음 |
| 2 | FR-S3-01 | 도구별 테스트 부분 미작성: docs, sheets, slides 테스트 미존재. 7개 테스트 파일 존재하나 목표 커버리지 60% 실측 미완 | 유틸 4 + 도구 3 / 6 | **Medium** | gmail, drive, calendar의 핵심 도구 테스트는 작성됨. 나머지 3개 도구(docs, sheets, slides)는 구조가 유사하여 우선순위 하향 가능 |
| 3 | FR-S3-05b | JSDoc 한국어 주석 4건 잔존: `gmail.ts:9`, `calendar.ts:8`, `docs.ts:7`, `sheets.ts:7`에 `* XXX 도구 정의` 형태의 주석. 사용자 대면 메시지 아닌 개발자 주석이므로 기능적 영향 없음 | 4/5 기준 | **Low** | 엄밀하게는 "하드코딩 한국어 0건" 기준 미충족이나, 코드 주석은 사용자 대면이 아니므로 실질적 영향 없음. 정리 시 5분 미만 소요 |

---

## FR-S3-05a 수용 기준 재검증

### 인스톨러 공유 유틸리티 (5개 기준)

| # | 기준 | Check-1 | Check-2 | 근거 |
|---|------|:-------:|:-------:|------|
| 1 | 7개 인스톨러 모듈이 모두 `shared/colors.sh`를 source | 미충족 | **충족** | `base`, `google`, `atlassian`, `figma`, `notion`, `github`, `pencil` 전체 7개 모듈에서 `source "$SHARED_DIR/colors.sh"` 확인. fallback else 블록으로 원격 실행 안전성 확보 |
| 2 | 인라인 색상 정의 0건 | 미충족 | **부분 충족** | 각 모듈의 `else` 블록에 fallback 색상 정의 존재. 이는 원격 실행(`curl\|bash`) 시 `SHARED_DIR` 경로 해석 불가한 경우를 위한 방어적 패턴. primary path에서는 shared source 사용. 엄밀한 "0건" 기준은 미충족이나 설계 의도는 합리적 |
| 3 | Docker 모듈이 `docker_check()` 사용 | 미충족 | **미충족** | `google/install.sh:21`에서 `docker info > /dev/null 2>&1` 인라인 사용. `docker-utils.sh`의 `docker_check()` 미호출 |
| 4 | MCP 모듈이 `mcp_add_docker_server()`/`mcp_add_stdio_server()` 사용 | 미충족 | **미충족** | `google/install.sh:340-375`에서 인라인 Node.js 코드로 MCP 설정 직접 처리. `mcp-config.sh` 함수 미호출 |
| 5 | 브라우저 모듈이 `browser_open()` 사용 | 미충족 | **미충족** | 모듈 install.sh 내 `open`/`xdg-open` 직접 호출 패턴 없음(확인). 현재 브라우저 열기가 필요한 모듈(google)에서 인라인 처리 |

**FR-S3-05a 충족도: 2/5 (40%) -- 부분 구현(50%) 유지**

> 분석: 기준 1(색상 source)만 완전히 해소됨. 기준 2(인라인 0건)는 fallback 패턴으로 부분 충족.
> 기준 3/4/5는 각 모듈의 인라인 로직을 shared 함수 호출로 대체하는 대규모 리팩토링이 필요하며,
> 기능적 정합성에 영향이 없으므로 후속 Sprint에서 처리 권장.

---

## FR-S3-05b 수용 기준 재검증

### Google MCP 공유 유틸리티 (5개 기준)

| # | 기준 | Check-1 | Check-2 | 근거 |
|---|------|:-------:|:-------:|------|
| 1 | `calendar.ts` 내 중복 `parseTime()` 0건 | **충족** | **충족** | `calendar.ts`에서 `import { getTimezone, parseTime } from "../utils/time.js"` 확인(line 3). 로컬 `parseTime` 함수 정의 0건. 4곳에서 import된 `parseTime()` 사용(line 173, 177, 301, 304) |
| 2 | 69개 핸들러가 캐싱된 `getGoogleServices()` 사용 | **충족** | **충족** | 6개 도구 파일 전체에서 `getGoogleServices()` 호출 총 75회 확인. `oauth.ts:93-99`의 `ServiceCache` + TTL 50분 캐싱 건재. `clearServiceCache()` 테스트 유틸리티 존재(line 433) |
| 3 | 모든 API 호출에 `withRetry()` 적용 | 미충족 | **충족** | 6개 도구 파일 전체에서 `import { withRetry } from "../utils/retry.js"` 확인. `await withRetry()` 총 91회, API 메서드 호출 87회 -- 100% 래핑. 지수 백오프(1s->2s->4s), 429/500/502/503/504 + 네트워크 에러 대응 |
| 4 | 사용자 입력이 sanitize 함수 통과 | **충족** | **충족** | `drive.ts`에서 `escapeDriveQuery()` 5회, `validateDriveId()` 14회 사용. `gmail.ts`에서 `sanitizeEmailHeader()` 5회 사용. `sanitize.ts` 7개 함수 전수 건재 |
| 5 | 하드코딩된 한국어 메시지 0건 | 미충족 | **대부분 충족** | 사용자 대면 메시지(description, error, response message) 한국어 0건. 6개 도구 파일 + `index.ts` + `oauth.ts`의 사용자 대면 문자열 전체 영문 확인. 잔존: JSDoc 주석 4건(`gmail.ts:9`, `calendar.ts:8`, `docs.ts:7`, `sheets.ts:7`의 `* XXX 도구 정의`) + `index.ts` 주석 3건(`// 모든 도구 등록` 등). 주석은 런타임 영향 없음 |

**FR-S3-05b 충족도: 4.5/5 (90%) -- 부분 구현(50%) -> 부분 구현(50%) 유지**

> 분석: Check Phase 1 대비 3번(withRetry)과 5번(한국어 메시지)이 크게 개선됨.
> 5번 기준의 잔존 항목이 JSDoc 주석뿐이므로 실질적으로는 4.5/5에 해당.
> 엄밀한 "0건" 기준 적용 시 부분 구현으로 분류하나, 기능적 영향은 없음.

---

## Sprint별 Match Rate

### Sprint 1 -- Critical Security (12 FRs)

| FR ID | 요구사항 | Check-1 | Check-2 | 비고 |
|-------|---------|:-------:|:-------:|------|
| FR-S1-01 | OAuth state 파라미터 | 100% | **100%** | `crypto.randomBytes(32)` + state 검증 건재 |
| FR-S1-02 | Drive 쿼리 이스케이핑 | 100% | **100%** | `escapeDriveQuery()` + `validateDriveId()` 건재 |
| FR-S1-03 | osascript 인젝션 방지 | 100% | **100%** | stdin 파이프 방식 건재 |
| FR-S1-04 | Atlassian 토큰 보안 | 100% | **100%** | `.env` 분리 + `--env-file` 건재 |
| FR-S1-05 | Figma 토큰 보안 | 100% | **100%** | 변경 없음 |
| FR-S1-06 | Docker non-root | 100% | **100%** | 변경 없음 |
| FR-S1-07 | token.json 권한 | 100% | **100%** | 변경 없음 |
| FR-S1-08 | 설정 디렉토리 권한 | 100% | **100%** | 변경 없음 |
| FR-S1-09 | Atlassian 변수 이스케이핑 | 100% | **100%** | 변경 없음 |
| FR-S1-10 | Gmail 헤더 인젝션 방지 | 100% | **100%** | `sanitizeEmailHeader()` 건재 |
| FR-S1-11 | 원격 스크립트 무결성 | 100% | **100%** | 변경 없음 |
| FR-S1-12 | 입력 검증 레이어 | 100% | **100%** | 7개 함수 전수 건재 |

**Sprint 1 Match Rate: 100% (12/12) -- 변동 없음**

---

### Sprint 2 -- Platform & Stability (11 FRs)

| FR ID | 요구사항 | Check-1 | Check-2 | 비고 |
|-------|---------|:-------:|:-------:|------|
| FR-S2-01 | 크로스 플랫폼 JSON 파서 | 100% | **100%** | 변동 없음 |
| FR-S2-02 | 원격 shared 스크립트 다운로드 | 50% | **100%** | `SHARED_TMP` + `setup_shared_dir()` + `trap cleanup` 완전 구현 |
| FR-S2-03 | MCP 설정 경로 통일 | 100% | **100%** | 변동 없음 |
| FR-S2-04 | Linux 패키지 관리자 확장 | 100% | **100%** | 변동 없음 |
| FR-S2-05 | Figma module.json 정합성 | 50% | **100%** | `python3: true` 추가 확인 |
| FR-S2-06 | Atlassian module.json modes | 0% | **100%** | `"modes": ["docker", "rovo"]` 추가 확인 |
| FR-S2-07 | 모듈 실행 순서 정렬 | 100% | **100%** | 변동 없음 |
| FR-S2-08 | Docker wait 타임아웃 | 100% | **100%** | 변동 없음 |
| FR-S2-09 | Python 3 의존성 명시 | 0% | **100%** | Notion(`python3: true`), Figma(`python3: true`) 확인 |
| FR-S2-10 | Windows 관리자 권한 조건부 | 100% | **100%** | 변동 없음 |
| FR-S2-11 | Docker Desktop 버전 체크 | 100% | **100%** | 변동 없음 |

**Sprint 2 Match Rate: 100% (11/11) -- Check-1 대비 72.7% -> 100% (+27.3pp)**

---

### Sprint 3 -- Quality & Testing (10 FRs)

| FR ID | 요구사항 | Check-1 | Check-2 | 비고 |
|-------|---------|:-------:|:-------:|------|
| FR-S3-01 | Google MCP 유닛 테스트 | 50% | **50%** | 테스트 파일 7개(유틸 4 + 도구 3). docs/sheets/slides 테스트 미작성 |
| FR-S3-02 | 인스톨러 Smoke 테스트 | 100% | **100%** | 변동 없음 |
| FR-S3-03 | CI 자동 트리거 | 100% | **100%** | 변동 없음 |
| FR-S3-04 | CI 테스트 범위 확장 | 100% | **100%** | 변동 없음 |
| FR-S3-05a | 인스톨러 공유 유틸리티 | 50% | **50%** | 수용 기준 2/5. colors.sh source 적용, 나머지 shared 함수 미사용 |
| FR-S3-05b | Google MCP 공유 유틸리티 | 50% | **50%** | 수용 기준 4.5/5. withRetry/messages 적용 완료. JSDoc 주석 한국어 잔존(비기능적) |
| FR-S3-06 | ESLint + Prettier | 100% | **100%** | 변동 없음 |
| FR-S3-07 | `any` 타입 제거 | 100% | **100%** | 도구 파일 전체 `any`/`as any` 0건 확인 |
| FR-S3-08 | 에러 메시지 영문 통일 | 100% | **100%** | 변동 없음 |
| FR-S3-09 | npm audit CI 통합 | 100% | **100%** | 변동 없음 |

**Sprint 3 Match Rate: 85% (7 완전 + 3 부분) -- Check-1 대비 80% -> 85% (+5pp)**

---

### Sprint 4 -- Google MCP Hardening (10 FRs)

| FR ID | 요구사항 | Check-1 | Check-2 | 비고 |
|-------|---------|:-------:|:-------:|------|
| FR-S4-01 | Google API Rate Limiting | 50% | **100%** | `withRetry()` 6개 도구 파일 전체, 91개 래핑 확인 |
| FR-S4-02 | OAuth 스코프 동적 설정 | 100% | **100%** | 변동 없음 |
| FR-S4-03 | Calendar 타임존 동적화 | 100% | **100%** | `Asia/Seoul` 하드코딩 0건(테스트/주석 제외) |
| FR-S4-04 | getGoogleServices() 캐싱 | 100% | **100%** | `ServiceCache` + TTL 50분 + `clearServiceCache()` 건재 |
| FR-S4-05 | Token refresh_token 검증 | 100% | **100%** | 변동 없음 |
| FR-S4-06 | 동시 인증 요청 처리 | 100% | **100%** | `authInProgress` 뮤텍스 건재 |
| FR-S4-07 | Gmail MIME 파싱 개선 | 50% | **100%** | `extractTextBody()` + `extractAttachments()` gmail.ts에 통합 완료 |
| FR-S4-08 | Gmail 첨부파일 개선 | 100% | **100%** | 변동 없음 |
| FR-S4-09 | Node.js 22 마이그레이션 | 100% | **100%** | 변동 없음 |
| FR-S4-10 | .dockerignore 추가 | 100% | **100%** | 변동 없음 |

**Sprint 4 Match Rate: 100% (10/10) -- Check-1 대비 85% -> 100% (+15pp)**

---

### Sprint 5 -- UX & Documentation (5 FRs)

| FR ID | 요구사항 | Check-1 | Check-2 | 비고 |
|-------|---------|:-------:|:-------:|------|
| FR-S5-01 | 설치 후 자동 검증 | 100% | **100%** | 변동 없음 |
| FR-S5-02 | 롤백 메커니즘 | 100% | **100%** | 변동 없음 |
| FR-S5-03 | ARCHITECTURE.md 동기화 | 0% | **100%** | shared/, Pencil, Remote MCP, IDE Extension, 실행 순서 전부 추가 |
| FR-S5-04 | package.json 버전 | 100% | **100%** | 변동 없음 |
| FR-S5-05 | 도구 메시지 영문화 | 0% | **100%** | 6개 도구 전체 messages.ts import + msg() 사용 + description 영문 전환 |
| FR-S5-06 | .gitignore 보강 | 100% | **100%** | 변동 없음 |

**Sprint 5 Match Rate: 100% (6/6) -- Check-1 대비 66.7% -> 100% (+33.3pp)**

---

## Sprint별 Match Rate 비교

| Sprint | Check Phase 1 | Check Phase 2 | 변동 |
|--------|:------------:|:------------:|:----:|
| Sprint 1 (Security) | 100% | **100%** | +0pp |
| Sprint 2 (Platform) | 72.7% | **100%** | **+27.3pp** |
| Sprint 3 (Quality) | 80% | **85%** | +5pp |
| Sprint 4 (Google MCP) | 85% | **100%** | **+15pp** |
| Sprint 5 (UX & Docs) | 66.7% | **100%** | **+33.3pp** |
| **전체** | **77.1%** | **93.8%** | **+16.7pp** |

---

## 샘플 회귀 검증 (이전 완전 구현 FR)

Act Phase에서 대량 코드 변경이 발생했으므로, 기존 완전 구현 37개 FR 중 주요 항목이 깨지지 않았는지 샘플 검증.

| FR ID | 검증 대상 | 상태 | 근거 |
|-------|----------|:----:|------|
| FR-S1-01 | `oauth.ts`의 state 파라미터 | 건재 | `crypto.randomBytes(32).toString("hex")` (line 227) + `url.searchParams.get("state")` 검증 (line 248) |
| FR-S1-02 | `drive.ts`의 `escapeDriveQuery` | 건재 | 5회 호출, `validateDriveId` 14회 호출 확인 |
| FR-S1-12 | `sanitize.ts` 7개 함수 | 건재 | `escapeDriveQuery`, `validateDriveId`, `sanitizeEmailHeader`, `validateEmail`, `validateMaxLength`, `sanitizeFilename`, `sanitizeRange` 전수 확인 (107줄) |
| FR-S4-04 | `getGoogleServices()` 캐싱 | 건재 | `ServiceCache` 인터페이스(line 93), `CACHE_TTL_MS = 50분`(line 98), `serviceCache` 변수(line 99), `clearServiceCache()`(line 433) |
| FR-S4-06 | 동시 인증 뮤텍스 | 건재 | `authInProgress: Promise<OAuth2Client> \| null`(line 102) |
| FR-S3-07 | `any` 타입 제거 | 건재 | 6개 도구 파일 전체에서 `: any`/`as any` 0건 |
| FR-S4-03 | 타임존 동적화 | 건재 | `Asia/Seoul` 프로덕션 코드 0건, `getTimezone()` import 사용 |

**회귀 검증 결과: 깨진 항목 0건**

---

## 정량적 기대 효과 재검증

| 지표 | 계획 목표 | Check-1 실측 | Check-2 실측 | 달성도 |
|------|:--------:|:-----------:|:-----------:|:------:|
| 보안 취약점 (Critical/High) | 0건 | 0건 | **0건** | 100% |
| 테스트 파일 수 | 도구별 + 유틸 | 5개 | **7개 (+2)** | 개선 |
| 서비스 인스턴스 생성 | 6회/TTL | 6회/TTL | **6회/TTL** | 100% |
| withRetry 적용률 | 100% | 0% | **100% (91/87)** | 100% |
| 한국어 사용자 대면 메시지 | 0건 | 다수 | **0건** | 100% |
| messages.ts 통합 | 6개 파일 | 0개 | **6개 파일** | 100% |
| mime.ts 통합 | gmail.ts | 미적용 | **적용 완료** | 100% |
| Match Rate | 90%+ | 83.3% | **96.9% (가중)** | 100% |

---

## 종합 판단

### Match Rate: 93.8% (가중 96.9%) -- 목표 90% 초과 달성

Act Phase Iterate 1에서 수행한 11개 항목 수정이 대부분 성공적으로 적용되었다.

**핵심 성과**:
1. **withRetry() 전면 적용** (FR-S4-01, FR-S3-05b): 6개 도구 파일 91개 API 호출 100% 래핑으로 Google API Rate Limiting 보호 완성
2. **mime.ts/messages.ts 통합** (FR-S4-07, FR-S5-05): gmail.ts 재귀 MIME 파싱 + 6개 파일 영문 메시지 중앙관리 완료
3. **module.json 메타데이터 정합성** (FR-S2-05, FR-S2-06, FR-S2-09): 3개 모듈의 `modes`/`python3` 필드 전부 추가
4. **ARCHITECTURE.md 동기화** (FR-S5-03): shared/, Pencil, Remote MCP 타입 전부 반영
5. **원격 실행 안정성** (FR-S2-02): `SHARED_TMP` + `trap cleanup` 패턴으로 임시 파일 정리 보장

**잔존 과제** (3건, 모두 Low-Medium):
1. FR-S3-05a: 인스톨러 shared 함수(docker_check, mcp_add 등) 실제 사용 전환 -- 대규모 리팩토링, 기능적 영향 없음
2. FR-S3-01: docs/sheets/slides 테스트 추가 -- 핵심 도구(gmail/drive/calendar) 테스트 완료, 나머지는 유사 구조
3. FR-S3-05b: JSDoc 한국어 주석 4건 -- 비기능적 코드 주석, 정리 시 5분 미만

### 권장 조치

잔존 3건 모두 기능적 정합성에 영향이 없고, Match Rate 90% 목표를 이미 초과했으므로
**Check Phase를 종료하고 Completion Report 단계로 진입**하는 것을 권장한다.

잔존 항목은 후속 Sprint 또는 기술 부채로 관리:
- FR-S3-05a (shared 함수 리팩토링): 별도 Plan 수립 후 진행
- FR-S3-01 (테스트 확장): 지속적 테스트 개선 과제로 관리
- FR-S3-05b (JSDoc 주석): 코드 리뷰 시 자연스럽게 정리

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| Check-1.0 | 2026-02-13 | 48개 FR 전수 검증 초회. Match Rate 83.3% | gap-detector |
| Check-2.0 | 2026-02-13 | Act Iterate 1 후 재검증. Match Rate 96.9%. 8/11 미달 해소 | gap-detector |
