# 공유 유틸리티 설계 갭 분석 보고서

**작성일**: 2026-02-12
**작성자**: Frontend Architect (shared-utilities 전문 에이전트)
**분석 대상**:
- `docs/03-analysis/shared-utilities-design.md` (v1.0)
- `docs/01-plan/features/adw-improvement.plan.md` (v2.0)
- `docs/02-design/features/adw-improvement.design.md` (v1.0)

---

## 1. 분석 개요

### 1.1 분석 범위

shared-utilities-design.md에서 제안하는 **10개 공유 유틸리티 모듈**과 **3단계 마이그레이션 로드맵**이 계획서(Plan) 및 설계서(Design)에 어느 정도 반영되었는지를 항목별로 비교 분석한다.

- **인스톨러 공유 스크립트 5개**: colors.sh, docker-utils.sh, mcp-config.sh, browser-utils.sh, package-manager.sh
- **Google MCP 유틸리티 5개**: time.ts, retry.ts, sanitize.ts, messages.ts, google-client.ts
- **3단계 마이그레이션 로드맵**: Phase 1(인스톨러), Phase 2(Google MCP), Phase 3(테스트/문서)

### 1.2 갭 유형 정의

| 갭 유형 | 정의 |
|---------|------|
| **누락** | shared-utilities-design에 있으나 계획서/설계서에 전혀 언급되지 않음 |
| **불충분** | 언급은 있으나 상세 구현 사양이 빠져 있거나 범위가 축소됨 |
| **불일치** | 양측의 내용이 서로 다르거나 모순됨 |
| **반영됨** | 적절히 반영되어 갭 없음 |

---

## 2. 계획서(Plan) 갭

### 2.1 인스톨러 공유 스크립트

| # | 항목 | shared-utilities-design 내용 | 현재 계획서 상태 | 갭 유형 |
|---|------|---------------------------|---------------|---------|
| P-1 | **colors.sh** | ANSI 색상 상수 8개 + 시맨틱 색상 5개 + 편의함수 5개(`print_success` 등). 7개 모듈에서 42줄 중복 제거 | FR-S3-05에서 "컬러 정의 10회 중복" 언급하고 `shared/` 분리 명시. 단, 구체적 파일명/함수명 미기재 | **불충분** |
| P-2 | **docker-utils.sh** | `docker_is_installed()`, `docker_is_running()`, `docker_get_status()`, `docker_check()`, `docker_wait_for_start()`, `docker_install()`, `docker_pull_image()`, `docker_cleanup_container()`, `docker_show_install_guide()` 총 9개 함수 | FR-S3-05에서 "Docker 체크" 중복 언급. FR-S2-08에서 Docker wait 타임아웃 별도 요구. 함수 목록이나 `docker_install()` 같은 핵심 함수 미기재 | **불충분** |
| P-3 | **mcp-config.sh** | `mcp_get_config_path()`, `mcp_add_docker_server()`, `mcp_add_stdio_server()`, `mcp_remove_server()`, `mcp_server_exists()`, `mcp_check_node()` 총 6개 함수. Node.js 기반 JSON 조작 | FR-S3-05에서 "MCP 설정 업데이트 4회 중복" 언급. FR-S2-03에서 경로 통일 요구. 그러나 `mcp_add_docker_server()`/`mcp_add_stdio_server()` 같은 구체적 API 미기재 | **불충분** |
| P-4 | **browser-utils.sh** | `browser_open()`, `browser_open_with_prompt()`, `browser_open_or_show()`, `browser_wait_for_completion()` 4개 함수. macOS/Windows/Linux 크로스 플랫폼 지원 | FR-S3-05에서 일부 언급 가능하나, 계획서에 browser-utils 관련 명시적 요구사항 **없음** | **누락** |
| P-5 | **package-manager.sh** | `pkg_detect_manager()`, `pkg_install()`, `pkg_install_cask()`, `pkg_is_installed()`, `pkg_ensure_installed()` 5개 함수. brew/apt/dnf/yum/pacman 지원 | FR-S2-04에서 Linux 패키지 관리자 확장(dnf, pacman) 요구. 그러나 공유 유틸리티로의 추출은 미언급. base/install.sh 내부 구현으로만 기술 | **불충분** |

### 2.2 Google MCP 유틸리티

| # | 항목 | shared-utilities-design 내용 | 현재 계획서 상태 | 갭 유형 |
|---|------|---------------------------|---------------|---------|
| P-6 | **time.ts** | `parseTime()`, `getCurrentTime()`, `addDays()`, `formatDate()` 4개 함수. 타임존 오프셋 매핑 포함 | FR-S4-03에서 타임존 동적화 요구. 계획서에는 `parseTime()` 중복 제거 명시적 요구 **없음** (QA-06에서 "parseTime 2곳" 언급만) | **불충분** |
| P-7 | **retry.ts** | `RetryOptions` 인터페이스, `withRetry()`, `retryable()` 데코레이터. 429/500/502/503/504 자동 재시도. ECONNRESET/ETIMEDOUT 대응 | FR-S4-01에서 Rate Limiting 요구사항 반영됨. "최대 3회, 1s->2s->4s 백오프" 명시. 그러나 `retryable()` 데코레이터나 네트워크 에러(ECONNRESET 등) 대응은 미기재 | **불충분** |
| P-8 | **sanitize.ts** | `sanitizeQuery()`, `sanitizeEmail()`, `sanitizeEmailHeader()`, `sanitizeFilename()`, `sanitizeHtml()`, `sanitizeRange()`, `limitInputSize()` 총 7개 함수 | FR-S1-02(Drive 쿼리 이스케이핑), FR-S1-10(이메일 헤더 인젝션 방지) 요구. 그러나 `sanitizeFilename()`, `sanitizeHtml()`, `sanitizeRange()`, `limitInputSize()` 4개 함수는 계획서에 **대응 요구사항 없음** | **불충분** |
| P-9 | **messages.ts** | 6개 서비스(Calendar/Gmail/Drive/Docs/Sheets/Slides)별 메시지 + 공통/에러 메시지. 총 ~60개 메시지 키. `msg()` 헬퍼 함수. 3단계 i18n 마이그레이션 경로 제안 | FR-S3-08(에러 메시지 영문 통일), FR-S5-05(도구 메시지 영문화) 에서 부분 반영. 그러나 계획서에는 **중앙집중화된 메시지 시스템 구축** 요구가 없고, 단순 "영문 통일"만 요구 | **불충분** |
| P-10 | **google-client.ts** | 싱글톤 패턴 서비스 매니저. `cachedAuth`, `serviceInstances` 캐시. `getGoogleServices()` (싱글톤), `clearServiceCache()`. 414→6 서비스 인스턴스 감소 | FR-S4-04에서 "getGoogleServices() 싱글톤/캐싱" 요구사항 반영됨. 그러나 계획서는 `oauth.ts` 내부 캐싱으로 기술하고, 별도 `services/google-client.ts` 파일 분리는 미언급 | **불일치** |

### 2.3 마이그레이션 로드맵

| # | 항목 | shared-utilities-design 내용 | 현재 계획서 상태 | 갭 유형 |
|---|------|---------------------------|---------------|---------|
| P-11 | **Phase 1 (인스톨러, Week 1)** | shared/ 디렉토리 생성, 5개 유틸리티 구현, 7개 모듈 리팩토링, 수용 기준 4개 | FR-S3-05에 Sprint 3(2주 내)로 배정. 그러나 "Week 1" 상세 일정이나 7개 모듈 순차 리팩토링 계획 미기재 | **불충분** |
| P-12 | **Phase 2 (Google MCP, Week 2)** | utils/ 디렉토리 생성, 4개 유틸리티 + services/google-client.ts 구현, calendar.ts 우선 리팩토링 후 5개 파일 순차 적용. 수용 기준 5개 | Sprint 3~4에 분산 배정(retry는 S4, sanitize는 S1, messages는 S3/S5, caching은 S4). **통합된 Phase 2 계획 없음** | **불일치** |
| P-13 | **Phase 3 (테스트/문서, Week 3)** | E2E 테스트, 통합 테스트, 성능 벤치마크(서비스 인스턴스 90% 감소 검증), 마이그레이션 가이드 | FR-S3-01~04에서 테스트 도입. 그러나 **공유 유틸리티 전용 테스트**나 **성능 벤치마크** 요구 없음 | **누락** |
| P-14 | **정량적 기대 효과** | 인스톨러 LOC -29%, Google MCP LOC -28%, 서비스 인스턴스 -99%, 중복 함수 -50%, 하드코딩 메시지 -100% | 계획서에 정량적 기대 효과 미기재. Match Rate 목표(65.5%→95%)만 있음 | **누락** |
| P-15 | **위험 분석** | 4개 리스크(기존 모듈 깨짐, 성능 회귀, 쉘 호환성, TS 컴파일 에러) + 완화 전략 | 계획서 Risk R-01~R-07에 공유 유틸리티 리팩토링 관련 리스크 **없음** | **누락** |

---

## 3. 설계서(Design) 갭

### 3.1 인스톨러 공유 스크립트

| # | 항목 | shared-utilities-design 내용 | 현재 설계서 상태 | 갭 유형 |
|---|------|---------------------------|---------------|---------|
| D-1 | **colors.sh** | 완전한 소스코드(100줄). ANSI 코드 8개 + 시맨틱 5개 + 편의함수 5개 | Section 5.4에서 `colors.sh` 파일명과 "Color constants, `print_ok()`, `print_fail()`" 기능만 언급. 함수명이 **다름** (`print_ok`/`print_fail` vs `print_success`/`print_error`). 전체 소스 미포함 | **불일치** |
| D-2 | **docker-utils.sh** | 완전한 소스코드(150줄). 9개 함수. `docker_install()`에 macOS brew 스피너, Linux 공식 스크립트 분기 포함 | Section 5.4에서 `docker-utils.sh` 파일명과 "`docker_check()`, `docker_wait_start()`" 2개 함수만 언급. **7개 함수 누락** (특히 `docker_install()`, `docker_pull_image()`, `docker_cleanup_container()`) | **불충분** |
| D-3 | **mcp-config.sh** | 완전한 소스코드(180줄). 6개 함수. OS별 경로 판별, Docker/stdio 두 가지 서버 타입 지원 | Section 5.4에서 "`mcp_add_server()`, `mcp_read()`" 2개 함수만 언급. 함수명이 **다름** (`mcp_add_server` vs `mcp_add_docker_server`/`mcp_add_stdio_server`). Docker/stdio 분리 설계 미반영 | **불일치** |
| D-4 | **browser-utils.sh** | 완전한 소스코드(70줄). 4개 함수. WSL 감지 포함 크로스 플랫폼 | Section 5.4에서 "`open_browser()`" 1개 함수만 언급. 함수명 **다름** (`open_browser` vs `browser_open`). `browser_open_with_prompt()`, `browser_wait_for_completion()` 누락 | **불일치** |
| D-5 | **package-manager.sh** | 완전한 소스코드(100줄). 5개 함수. 6개 패키지 관리자 지원 | 설계서에 **전혀 언급 없음**. Section 4.4(FR-S2-04)에서 `base/install.sh` 내부에 인라인 `detect_pkg_manager()`, `pkg_install()` 구현으로 설계. 공유 유틸리티 분리 미반영 | **누락** |
| D-6 | **인스톨러 마이그레이션 가이드** | Before/After 코드 비교. `SCRIPT_DIR` 기반 source 패턴. 모듈당 ~50줄 절감 예시 | 설계서에 마이그레이션 가이드 없음. Section 4.2에서 `$SHARED_DIR` 환경변수 기반 source 패턴 제시(원격 실행 대응). 로컬 실행 시의 source 패턴은 미명시 | **불충분** |
| D-7 | **수정 대상 파일 7개** | base, google, atlassian, figma, notion, github, pencil 모듈의 install.sh | 설계서 Section 11.3에 shared/*.sh 파일 생성은 명시. 그러나 7개 모듈의 **개별 리팩토링 변경사항**은 FR-S3-05에 대한 상세 설계 없음 | **불충분** |

### 3.2 Google MCP 유틸리티

| # | 항목 | shared-utilities-design 내용 | 현재 설계서 상태 | 갭 유형 |
|---|------|---------------------------|---------------|---------|
| D-8 | **time.ts** | `parseTime()`, `getCurrentTime()`, `addDays()`, `formatDate()`. 타임존 오프셋 매핑 테이블. calendar.ts 마이그레이션 예시 | 설계서에 **time.ts 파일 없음**. Section 6.3에서 `timezone.ts`로 별도 설계(`getTimezone()`, `getUtcOffsetString()`). `parseTime()` 함수 분리는 미설계 | **불일치** |
| D-9 | **retry.ts** | `RetryOptions` 인터페이스, `withRetry()`, `retryable()` 데코레이터, `isRetryableError()`, `sleep()`. ECONNRESET/ETIMEDOUT 대응 | Section 6.1에서 `withRetry()` 상세 코드 제공. `RetryOptions` 인터페이스 반영. 그러나 `retryable()` 데코레이터와 `ECONNRESET/ETIMEDOUT` 네트워크 에러 대응 **미반영** | **불충분** |
| D-10 | **sanitize.ts** | 7개 함수: `sanitizeQuery()`, `sanitizeEmail()`, `sanitizeEmailHeader()`, `sanitizeFilename()`, `sanitizeHtml()`, `sanitizeRange()`, `limitInputSize()` | Section 9.2에서 `escapeDriveQuery()`, `validateDriveId()`, `sanitizeEmailHeader()`, `validateEmail()`, `validateMaxLength()` 5개 함수 설계. **함수명/범위 불일치**: `sanitizeQuery()` vs `escapeDriveQuery()`, `sanitizeFilename()`/`sanitizeHtml()`/`sanitizeRange()` 3개 누락, `validateDriveId()` 추가됨 | **불일치** |
| D-11 | **messages.ts** | 8개 카테고리(common/calendar/gmail/drive/docs/sheets/slides/errors), ~60개 메시지 키, `msg()` 헬퍼 함수, 3단계 i18n 로드맵 | Section 5.4 Summary에서 "Centralized i18n-ready message strings"으로만 언급. **상세 메시지 구조, 카테고리, msg() 헬퍼 모두 미설계**. Section 5.7에서 단순 한->영 치환만 설계 | **불충분** |
| D-12 | **google-client.ts** | `services/google-client.ts` 파일. 싱글톤 패턴. `cachedAuth`, `serviceInstances` 분리. `clearServiceCache()` 테스트 유틸리티 | Section 6.4에서 **`oauth.ts` 내부**에 ServiceCache 설계. TTL 50분 기반 캐싱. 별도 `services/google-client.ts` 파일 분리 **미반영**. `clearServiceCache()` 테스트 유틸리티는 미언급 | **불일치** |
| D-13 | **디렉토리 구조** | `src/utils/` (time, retry, sanitize, messages) + `src/services/` (google-client) + `src/types/` (common.types) | 설계서에 `src/utils/` (retry, sanitize, timezone, mime, messages) + **`services/` 디렉토리 없음** + `types/` 미언급. `mime.ts`는 추가, `time.ts`는 `timezone.ts`로 변경 | **불일치** |
| D-14 | **calendar.ts 마이그레이션 예시** | import 변경, parseTime 외부화, withRetry 적용, messages 사용 등 Before/After 전체 코드 | 설계서에 부분적 마이그레이션 언급(timezone 적용, retry 적용). **통합된 마이그레이션 예시 없음** | **불충분** |

### 3.3 마이그레이션 로드맵 및 기대 효과

| # | 항목 | shared-utilities-design 내용 | 현재 설계서 상태 | 갭 유형 |
|---|------|---------------------------|---------------|---------|
| D-15 | **3단계 마이그레이션 로드맵** | Phase 1(인스톨러 Week 1) -> Phase 2(Google MCP Week 2) -> Phase 3(테스트/문서 Week 3) | 설계서 Section 11.1에서 Sprint 3 Phase 4로 통합 배치("FR-S3-05, FR-S3-07, FR-S3-08"). **전용 마이그레이션 단계 없음** | **불일치** |
| D-16 | **수용 기준 (인스톨러)** | (1) 전 모듈 shared source (2) 중복 색상 정의 0건 (3) docker_check() 일관 사용 (4) mcp_add_docker_server() 일관 사용 | 설계서에 FR-S3-05 수용 기준 **미명시** | **누락** |
| D-17 | **수용 기준 (Google MCP)** | (1) 싱글톤 getGoogleServices() (2) parseTime() 중복 0건 (3) 한국어 메시지 0건 (4) retry 적용 (5) 입력 sanitize 적용 | 설계서에 개별 FR 수준의 검증은 있으나, **공유 유틸리티 전체 수용 기준**은 미통합 | **불충분** |
| D-18 | **정량적 기대 효과** | 인스톨러 LOC 1200→850(-29%), Google MCP LOC 1800→1300(-28%), 서비스 인스턴스 414→6(-99%) | 설계서에 정량적 효과 **미기재** | **누락** |
| D-19 | **위험 분석** | 모듈 깨짐(Medium/High), 성능 회귀(Low/Medium), 쉘 호환성(Low/Medium), TS 컴파일(Low/Low) + 완화 전략 | 설계서에 공유 유틸리티 리팩토링 전용 위험 분석 **없음** | **누락** |
| D-20 | **완전한 파일 트리** | 리팩토링 후 전체 프로젝트 파일 트리 (NEW/MODIFIED/EXISTING 태그 포함) | 설계서 Section 11.3에서 "New Files" 테이블로 부분 반영. shared/*.sh는 명시되어 있으나, `services/google-client.ts` 미포함. `time.ts` 대신 `timezone.ts` 기재 | **불충분** |

---

## 4. 보완 권고사항

### 4.1 계획서 보완 필요사항

| 우선순위 | 권고 | 관련 갭 |
|---------|------|---------|
| **High** | FR-S3-05 요구사항을 세분화하여 인스톨러 5개 + Google MCP 5개 공유 유틸리티 파일을 명시적으로 나열 | P-1~P-5, P-6~P-10 |
| **High** | browser-utils.sh에 대한 명시적 요구사항 추가 (현재 4개 모듈에서 중복되는 브라우저 열기 로직 통합) | P-4 |
| **Medium** | package-manager.sh를 공유 유틸리티로 추출하는 요구사항 추가 (FR-S2-04와 FR-S3-05 연계) | P-5 |
| **Medium** | messages.ts 중앙집중화 요구사항 추가 (FR-S3-08/FR-S5-05의 "영문 통일"을 넘어서 구조적 메시지 관리) | P-9 |
| **Medium** | google-client.ts 파일 분리 vs oauth.ts 내부 캐싱 방향 결정 후 계획서 명시 | P-10 |
| **Low** | 공유 유틸리티 리팩토링 관련 위험(기존 모듈 깨짐) 추가 | P-15 |
| **Low** | 정량적 기대 효과(LOC 감소율, 서비스 인스턴스 감소율) 계획서에 추가 | P-14 |
| **Low** | 공유 유틸리티 전용 테스트 및 성능 벤치마크 요구사항 추가 | P-13 |

### 4.2 설계서 보완 필요사항

| 우선순위 | 권고 | 관련 갭 |
|---------|------|---------|
| **High** | 인스톨러 공유 유틸리티 함수명 통일 결정 (`print_ok` vs `print_success`, `open_browser` vs `browser_open`, `mcp_add_server` vs `mcp_add_docker_server`) | D-1, D-3, D-4 |
| **High** | docker-utils.sh의 누락된 7개 함수 설계 추가 (특히 `docker_install()`, `docker_pull_image()`) | D-2 |
| **High** | time.ts vs timezone.ts 통합 결정: `parseTime()` 함수를 어디에 배치할지 명확화 | D-8 |
| **High** | google-client.ts 파일 분리 여부 최종 결정. 현재 설계서(oauth.ts 내부) vs shared-utilities-design(별도 파일) 불일치 해소 | D-12 |
| **Medium** | package-manager.sh 상세 설계 추가 (현재 설계서에 완전 누락) | D-5 |
| **Medium** | messages.ts 상세 설계 추가 (메시지 카테고리, 키 구조, msg() 헬퍼) | D-11 |
| **Medium** | sanitize.ts 함수 목록 통일: shared-utilities-design의 7개 vs 설계서의 5개 비교 후 최종 범위 확정 | D-10 |
| **Medium** | FR-S3-05 공유 유틸리티 수용 기준(Acceptance Criteria) 명시 | D-16, D-17 |
| **Low** | 7개 인스톨러 모듈 개별 리팩토링 상세 설계 추가 | D-7 |
| **Low** | 마이그레이션 순서 명확화 (Sprint 3 내에서의 Phase 구분) | D-15 |
| **Low** | 정량적 기대 효과 및 전용 위험 분석 추가 | D-18, D-19 |

---

## 5. 구체적 추가 내용 제안

### 5.1 계획서에 추가해야 할 텍스트

#### FR-S3-05 세분화 (Section 3.1 Sprint 3 테이블에 추가)

```markdown
| FR-S3-05a | **인스톨러 공유 유틸리티 추출** — `installer/modules/shared/` 디렉토리에 5개 공유 스크립트 생성: `colors.sh`(색상 상수+편의함수), `docker-utils.sh`(Docker 상태 확인/설치/정리), `mcp-config.sh`(MCP JSON 설정 읽기/쓰기), `browser-utils.sh`(크로스 플랫폼 브라우저 열기), `package-manager.sh`(패키지 관리자 추상화). 7개 인스톨러 모듈을 공유 유틸리티 source로 리팩토링 | **Medium** | `installer/modules/shared/` (신규), `installer/modules/*/install.sh` (수정) | QA-06: 컬러 10회, Docker 4회, MCP config 4회, 브라우저 4회 중복 |
| FR-S3-05b | **Google MCP 공유 유틸리티 추출** — `src/utils/` 디렉토리에 4개 유틸리티 생성: `time.ts`(시간 파싱), `sanitize.ts`(입력 검증 통합), `messages.ts`(중앙집중 메시지), `retry.ts`(재시도 로직). `src/services/google-client.ts`(싱글톤 서비스 매니저) 또는 `oauth.ts` 내 캐싱 구현 | **Medium** | `google-workspace-mcp/src/utils/` (신규), `google-workspace-mcp/src/tools/*.ts` (수정) | QA-06: parseTime 2회 중복, QA-07: 서비스 69회 재생성 |
```

#### 위험 추가 (Section 5 Risks 테이블에 추가)

```markdown
| R-08 | 공유 유틸리티 리팩토링 시 기존 인스톨러 모듈 동작 깨짐 | High | Medium | 모듈별 순차 리팩토링 + 각 모듈 리팩토링 후 smoke 테스트 실행 |
```

### 5.2 설계서에 추가해야 할 텍스트

#### Section 5.4 확장 (FR-S3-05 상세 설계)

```markdown
### 5.4 FR-S3-05: Shared Utilities (Detailed)

#### 5.4.1 인스톨러 공유 유틸리티 상세

**디렉토리**: `installer/modules/shared/`

| File | Functions | Source Reference |
|------|-----------|-----------------|
| `colors.sh` | `RED`, `GREEN`, `YELLOW`, `CYAN`, `GRAY`, `BLUE`, `MAGENTA`, `WHITE`, `NC`, `COLOR_SUCCESS`, `COLOR_ERROR`, `COLOR_WARNING`, `COLOR_INFO`, `COLOR_DEBUG`, `print_success()`, `print_error()`, `print_warning()`, `print_info()`, `print_debug()` | `shared-utilities-design.md` Section 1.3.1 |
| `docker-utils.sh` | `docker_is_installed()`, `docker_is_running()`, `docker_get_status()`, `docker_check()`, `docker_wait_for_start()`, `docker_install()`, `docker_pull_image()`, `docker_cleanup_container()`, `docker_show_install_guide()` | `shared-utilities-design.md` Section 1.3.2 |
| `mcp-config.sh` | `mcp_get_config_path()`, `mcp_check_node()`, `mcp_add_docker_server()`, `mcp_add_stdio_server()`, `mcp_remove_server()`, `mcp_server_exists()` | `shared-utilities-design.md` Section 1.3.3 |
| `browser-utils.sh` | `browser_open()`, `browser_open_with_prompt()`, `browser_open_or_show()`, `browser_wait_for_completion()` | `shared-utilities-design.md` Section 1.3.4 |
| `package-manager.sh` | `pkg_detect_manager()`, `pkg_install()`, `pkg_install_cask()`, `pkg_is_installed()`, `pkg_ensure_installed()` | `shared-utilities-design.md` Section 1.3.5 |

**Source 패턴**:
```bash
# 로컬 실행
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../shared/colors.sh"

# 원격 실행 (FR-S2-02 연계)
source "${SHARED_DIR:-$SCRIPT_DIR/../shared}/colors.sh"
```

**수용 기준**:
1. 7개 인스톨러 모듈이 모두 `shared/colors.sh`를 source
2. 인라인 색상 정의(RED=, GREEN= 등) 0건
3. Docker 관련 모듈(google, atlassian)이 `docker_check()` 사용
4. MCP 설정 모듈(google, atlassian)이 `mcp_add_docker_server()` 사용
5. 브라우저 열기 모듈(atlassian, google, figma, notion)이 `browser_open()` 사용

#### 5.4.2 Google MCP 공유 유틸리티 상세

**주요 결정사항**:
- `parseTime()` 함수는 `src/utils/time.ts`에 배치 (timezone.ts와 통합 검토 필요)
- 서비스 캐싱은 `oauth.ts` 내부에 구현 (별도 google-client.ts 파일 분리는 보류)
- `sanitize.ts`의 최종 함수 목록: `escapeDriveQuery()`, `sanitizeEmailHeader()`, `validateEmail()`, `validateDriveId()`, `validateMaxLength()`, `sanitizeFilename()`, `sanitizeRange()`
- `messages.ts`는 Sprint 5 FR-S5-05 메시지 영문화와 동시 구현

**수용 기준**:
1. `calendar.ts` 내 중복 `parseTime()` 함수 0건
2. 69개 핸들러가 캐싱된 `getGoogleServices()` 사용
3. 모든 Google API 호출에 `withRetry()` 적용
4. 사용자 입력이 API에 전달되기 전 sanitize 함수 통과
5. 하드코딩된 한국어 메시지 0건 (Sprint 5 완료 시)
```

#### Section 11.3 New Files 테이블 보완

```markdown
| `src/utils/time.ts` | S3-05 | Time parsing (parseTime, addDays) |
| `installer/modules/shared/package-manager.sh` | S3-05 | Cross-platform package manager |
| `installer/modules/shared/browser-utils.sh` | S3-05 | Cross-platform browser opening |
```

---

## 6. 갭 요약 통계

### 6.1 계획서 갭 요약

| 갭 유형 | 건수 | 비율 |
|---------|:----:|:----:|
| 누락 | 4 | 26.7% |
| 불충분 | 8 | 53.3% |
| 불일치 | 2 | 13.3% |
| 반영됨 | 1 | 6.7% |
| **합계** | **15** | **100%** |

### 6.2 설계서 갭 요약

| 갭 유형 | 건수 | 비율 |
|---------|:----:|:----:|
| 누락 | 4 | 20.0% |
| 불충분 | 7 | 35.0% |
| 불일치 | 7 | 35.0% |
| 반영됨 | 2 | 10.0% |
| **합계** | **20** | **100%** |

### 6.3 핵심 불일치 요약

| # | 불일치 항목 | shared-utilities-design | 설계서 | 결정 필요 |
|---|-----------|----------------------|--------|----------|
| 1 | 편의함수 이름 | `print_success()` / `print_error()` | `print_ok()` / `print_fail()` | 명명 규칙 통일 |
| 2 | 브라우저 함수 이름 | `browser_open()` | `open_browser()` | 명명 규칙 통일 |
| 3 | MCP 함수 구조 | `mcp_add_docker_server()` + `mcp_add_stdio_server()` (2개 분리) | `mcp_add_server()` (1개 통합) | API 설계 결정 |
| 4 | 시간 유틸리티 파일 | `time.ts` (parseTime + getCurrentTime + addDays + formatDate) | `timezone.ts` (getTimezone + getUtcOffsetString) | 파일 범위 결정 |
| 5 | 서비스 캐싱 위치 | `services/google-client.ts` (별도 파일) | `auth/oauth.ts` (기존 파일 내부) | 아키텍처 결정 |
| 6 | sanitize 함수 범위 | 7개 함수 (sanitizeQuery 등) | 5개 함수 (escapeDriveQuery 등) | 범위 확정 |
| 7 | 마이그레이션 단계 | 3 Phase (Week 1/2/3) | Sprint 3 Phase 4 (통합) | 일정 결정 |

---

## 7. 결론

shared-utilities-design.md는 공유 유틸리티에 대한 **완전한 구현 사양**(전체 소스코드, 마이그레이션 예시, 정량적 효과)을 제공하고 있으나, 현재 계획서와 설계서에는 이 내용이 **부분적으로만 반영**되어 있다.

**주요 갭 패턴**:
1. **추상화 수준 차이** -- shared-utilities-design은 함수 단위 상세 설계를 제공하나, 계획서/설계서는 파일 단위 요약만 포함
2. **명명 불일치** -- 동일 기능에 대해 3개 문서가 서로 다른 함수명을 사용 (7건)
3. **범위 누락** -- browser-utils.sh, package-manager.sh가 설계서에 미반영, messages.ts 상세 미설계
4. **아키텍처 결정 미합의** -- 서비스 캐싱 위치, 시간 유틸리티 구조에 대한 2개 문서 간 불일치 미해소

**권고 조치**: 계획서에서 FR-S3-05를 FR-S3-05a(인스톨러)/FR-S3-05b(Google MCP)로 세분화하고, 설계서에서 Section 5.4를 본 갭 분석 보고서의 제안 내용 기준으로 확장하여 불일치를 해소해야 한다.
