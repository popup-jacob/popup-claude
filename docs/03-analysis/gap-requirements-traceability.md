# 요구사항 추적 갭 분석 보고서

> **Summary**: 추적 매트릭스(48개 이슈 / 44개 FR)와 계획서 및 설계서 간 갭 식별 및 보완 권고
>
> **Project**: popup-claude (AI-Driven Work Installer)
> **Author**: Gap Analyst Agent
> **Created**: 2026-02-12
> **Status**: Draft
> **References**:
> - `docs/03-analysis/adw-requirements-traceability-matrix.md` (추적 매트릭스)
> - `docs/01-plan/features/adw-improvement.plan.md` (계획서)
> - `docs/02-design/features/adw-improvement.design.md` (설계서)

---

## 1. 분석 개요

### 1.1 분석 목적

추적 매트릭스에서 식별된 44개 기능 요구사항, 8개 잠재적 누락 요구사항, 7개 암묵적 요구사항, 8개 횡단 관심사가 계획서와 설계서에 완전히 반영되었는지 검증하고, 보완이 필요한 항목을 도출한다.

### 1.2 분석 범위

| 항목 | 추적 매트릭스 | 계획서 | 설계서 |
|------|:----------:|:-----:|:-----:|
| 기능 요구사항 (FR) | 44개 | 44개 | 44개 |
| 분석 이슈 커버리지 | 43/48 (89.6%) | 43/48 (89.6%) | 43/48 (89.6%) |
| 잠재적 누락 요구사항 | 8개 식별 | 부분 반영 | 부분 반영 |
| 암묵적 요구사항 | 7개 식별 | 미반영 | 부분 반영 |
| 횡단 관심사 | 8개 식별 | 부분 반영 | 부분 반영 |
| 크리티컬 패스 | 6개 경로 | 반영됨 | 반영됨 |
| 병렬 실행 그룹 | 5개 스프린트 | 반영됨 | 반영됨 |

### 1.3 핵심 결론

- **44개 기본 FR**: 계획서와 설계서 모두 100% 반영 (갭 없음)
- **잠재적 누락 8건**: 2건 반영, 6건 미반영 (보완 필요)
- **암묵적 요구사항 7건**: 3건 부분 반영, 4건 미반영 (보완 필요)
- **횡단 관심사 8건**: 5건 반영, 3건 미반영 (보완 필요)
- **89.6% 커버리지 누락 5건**: Out of Scope 타당성 확인 완료

---

## 2. 누락 요구사항 분석

추적 매트릭스 Section 8.1에서 식별된 8개 잠재적 누락 요구사항의 계획서/설계서 반영 상태를 분석한다.

| # | ID | 요구사항명 | 추적 매트릭스 설명 | 계획서 반영 | 설계서 반영 | 추가 필요여부 |
|:-:|:---|:---------|:---------------|:---------:|:---------:|:----------:|
| 1 | FR-S3-09 (제안) | npm audit / 의존성 취약점 스캔 | Appendix A.1에서 "npm audit 미적용" 추가 발견 | **미반영** | **미반영** | **Yes** (High) |
| 2 | FR-S3-07 확장 | 추가 `any` 타입 위치 | `sheets.ts:18,341`, `calendar.ts:288`, `slides.ts:135,156`, `docs.ts:236` | **미반영** (index.ts:32만 기재) | **반영됨** (설계서 5.6에 7개 위치 모두 기재) | 계획서만 보완 |
| 3 | FR-S3-10 (제안) | 보안 로깅 | Appendix A.1에서 "보안 로깅 미구현" 추가 발견 | **미반영** | **미반영** | **Yes** (Medium) |
| 4 | FR-S1-11 (제안) | 입력 검증 레이어 | Appendix A.1에서 "입력 검증 레이어 부재" 지적 | **미반영** (명시적 FR 없음) | **반영됨** (설계서 9.2에 `sanitize.ts` 5개 함수 설계) | 계획서만 보완 |
| 5 | FR-S2-11 (제안) | Docker Desktop 버전 체크 | OS-06이 FR-S2-04에 매핑되나, FR-S2-04 설명은 패키지 관리자만 언급 | **미반영** (FR-S2-04가 apt/dnf/pacman만 기술) | **미반영** | **Yes** (Medium) |
| 6 | - | OS-05 문서화 처리 | WSL 재시작 가이드가 이미 구현됨, 문서화로 대응 | **반영됨** (매핑 테이블에 "문서화로 대응" 기재) | **반영됨** (Sprint 5 UX에 포함) | No |
| 7 | - | Pencil 모듈 보안/플랫폼 수정 | Pencil 모듈이 코드베이스에 존재하지만 요구사항 미언급 | **미반영** | **미반영** | Low (별도 검토) |
| 8 | - | 구조적 로깅 | QA-05가 Out of Scope으로 처리됨 | **반영됨** (Out of Scope 명시) | **미반영** (언급 없음) | No (Out of Scope 유지 타당) |

### 2.1 주요 발견

1. **FR-S3-07 범위 불일치**: 계획서는 `index.ts:32`만 명시하지만, 설계서는 7개 위치(index.ts, sheets.ts, slides.ts, calendar.ts, docs.ts)를 모두 포함함. **계획서가 설계서보다 좁은 범위**를 기술하고 있어 계획서 갱신 필요.

2. **입력 검증 레이어**: 계획서에 별도 FR 없지만, 설계서에는 `sanitize.ts`가 5개 함수(escapeDriveQuery, validateDriveId, sanitizeEmailHeader, validateEmail, validateMaxLength)로 설계됨. FR-S1-02, FR-S1-10에 분산 포함되어 있으나 **횡단 관심사로서 별도 명시 권장**.

3. **npm audit**: CI 파이프라인(FR-S3-03)에 `npm audit` 단계가 없음. 보안 관점에서 High 우선순위.

---

## 3. 암묵적 요구사항 분석

추적 매트릭스 Section 8.2에서 식별된 7개 암묵적 요구사항의 반영 상태.

| # | 항목 | 설명 | 관련 스프린트 | 계획서 반영 | 설계서 반영 |
|:-:|:-----|:----|:----------:|:---------:|:---------:|
| 1 | 하위 호환성 테스팅 | MCP 경로 변경(FR-S2-03), OAuth state(FR-S1-01), parse_json(FR-S2-01) 마이그레이션 경로 검증 | S1, S2 | **부분 반영** (R-01, R-02, R-04 리스크로 기재) | **반영됨** (FR-S2-03에 마이그레이션 스크립트 설계, FR-S1-01에 stateless fallback) |
| 2 | 에러 처리 일관성 | Rate limiting(FR-S4-01) + Token validation(FR-S4-05) 에러 처리 패턴 통일 | S4 | **미반영** | **부분 반영** (retry.ts에 에러 처리 패턴 있으나 통합 가이드 없음) |
| 3 | 임시 파일 정리 | FR-S2-02에서 temp dir 다운로드 후 cleanup 보장 | S2 | **미반영** (trap 핸들러 미언급) | **미반영** (temp dir 생성만 설계, cleanup 미언급) |
| 4 | CI 시크릿 관리 | Google API 크레덴셜 모킹/스터빙 | S3 | **미반영** | **반영됨** (설계서 5.1에서 `vi.mock("../../auth/oauth.js")` 패턴) |
| 5 | 마이그레이션 문서 | `~/.mcp.json` 레거시 경로 사용자 가이드 | S2, S5 | **미반영** (R-01 리스크만 언급) | **미반영** (마이그레이션 코드만 있고 사용자 문서 없음) |
| 6 | TypeScript strict 모드 보존 | `any` 제거 시 strict:true 회귀 방지 | S3 | **미반영** | **미반영** (any 대체 타입은 명시했으나 strict 호환성 테스트 미언급) |
| 7 | Docker 빌드 캐시 무효화 | 베이스 이미지 변경 + 사용자 추가 + .dockerignore가 레이어 캐싱에 미치는 영향 | S1, S4 | **미반영** | **부분 반영** (Dockerfile 멀티스테이지 설계에 캐시 고려 있으나 명시적 가이드 없음) |

### 3.1 주요 발견

1. **임시 파일 정리 (항목 3)**: 계획서와 설계서 모두 FR-S2-02의 temp dir cleanup을 누락함. Shell 스크립트의 `trap` 핸들러로 비정상 종료 시에도 정리를 보장해야 함. **설계서 보완 필수**.

2. **마이그레이션 문서 (항목 5)**: MCP 경로 변경(FR-S2-03)은 High 우선순위 리스크(R-01)로 식별되었으나, 구체적인 사용자 마이그레이션 가이드 작성이 계획/설계에 빠져 있음. **FR-S5-03 범위에 포함 권장**.

3. **에러 처리 일관성 (항목 2)**: `withRetry()` 함수가 설계되었으나, retry 실패 후의 사용자 대면 에러 메시지 포맷이 통일되지 않음. Sprint 4 설계에 에러 메시지 포맷 표준 추가 권장.

---

## 4. 횡단 관심사 분석

추적 매트릭스 Section 7 (Target File Impact Matrix) + Section 8.3 (Cross-Cutting Concerns)의 반영 상태.

### 4.1 고영향 파일 조율 분석

| 파일 | 관련 요구사항 수 | 설계 조율 필요 | 계획서 상태 | 설계서 상태 |
|:-----|:--------------:|:------------:|:----------:|:----------:|
| `oauth.ts` | **7** (S1-01, S1-07, S1-08, S4-02, S4-04, S4-05, S4-06) | **Critical** | **반영됨** (Section 8.1에 스프린트별 WP 분리) | **반영됨** (Section 3.1, 6.2-6.5에 순차적 설계) |
| `install.sh` | **6** (S1-03, S2-01, S2-02, S2-07, S5-01, S5-02) | **Critical** | **반영됨** (Section 8.1에 스프린트별 WP 분리) | **반영됨** (Section 3.3, 4.1-4.3, 7.1-7.2) |
| `gmail.ts` | 3 (S1-10, S4-07, S4-08) | High | 반영됨 | 반영됨 |
| `atlassian/install.sh` | 3 (S1-04, S1-09, S2-03) | High | 반영됨 | 반영됨 |
| `figma/module.json` | 3 (S1-05, S2-05, S2-09) | Medium | 반영됨 | 반영됨 |
| `Dockerfile` | 2 (S1-06, S4-09) | Medium | 반영됨 | **반영됨** (Section 8.1에 통합 Dockerfile 설계) |

### 4.2 횡단 관심사 반영 상태

| # | 관심사 | 영향 요구사항 | 계획서 반영 | 설계서 반영 | 갭 |
|:-:|:------|:------------|:---------:|:---------:|:--:|
| 1 | oauth.ts 리팩토링 필요 (7개 FR) | S1-01, S1-07, S1-08, S4-02, S4-04, S4-05, S4-06 | **미반영** (리팩토링 별도 FR 없음) | **부분 반영** (설계서에 순차 설계이나 모듈 분리 미제안) | **Gap** |
| 2 | install.sh 변경 순서 조율 (6개 FR) | S1-03, S2-01, S2-02, S2-07, S5-01, S5-02 | **반영됨** (S1-03과 S2-01 통합 명시) | **반영됨** (Section 3.3 + 4.1 통합) | OK |
| 3 | 환경변수 증가 관리 | S1-04, S4-02, S4-03, S1-05 | **미반영** (.env.example 미언급) | **미반영** (.env.example 템플릿 미설계) | **Gap** |
| 4 | module.json 스키마 표준화 | S2-05, S2-06, S2-09 | **미반영** (각 FR별 개별 수정만) | **미반영** (스키마 정의 없음) | **Gap** |
| 5 | 테스트 인프라 아키텍처 | S3-01, S3-02, S3-03, S3-04, S3-06 | **반영됨** (S3 WP1~WP3 구성) | **반영됨** (Section 5 전체, 별도 test-strategy.md 참조) | OK |
| 6 | Docker 보안 강화 일괄 처리 | S1-06, S4-09, S4-10 | **부분 반영** (S1과 S4에 분리) | **반영됨** (Section 8.1에 통합 Dockerfile) | OK |
| 7 | i18n 방향 결정 | S3-08, S5-05 | **미반영** (영문 통일만 명시, i18n 키 방식 미결정) | **부분 반영** (messages.ts 중앙화 언급이나 i18n 프레임워크 미결정) | Minor Gap |
| 8 | Shell 스크립트 품질 기준 | S1-03, S1-09, S2-01, S2-02, S3-05 | **미반영** (ShellCheck CI 미언급) | **미반영** (ShellCheck 미언급) | **Gap** |

### 4.3 주요 발견

1. **oauth.ts 리팩토링**: 7개 요구사항이 동일 파일을 수정하지만, 모듈 분리(auth, token, cache 등으로 분할) 설계가 없음. 머지 충돌 및 리그레션 리스크가 높음.

2. **환경변수 관리**: 새로운 환경변수가 최소 4개(CONFLUENCE_*, JIRA_*, GOOGLE_SCOPES, TIMEZONE) 추가되나, `.env.example` 템플릿이 설계되지 않음.

3. **module.json 스키마**: 3개 FR이 module.json을 수정하지만, 정식 스키마 정의(JSON Schema 등)가 없어 향후 불일치 재발 가능.

4. **ShellCheck CI**: Shell 스크립트 변경이 5개 FR에 걸쳐 있으나, CI에 ShellCheck 검증이 포함되지 않음. 추적 매트릭스의 권고가 설계서에 미반영.

---

## 5. 크리티컬 패스 및 병렬 실행 분석

### 5.1 크리티컬 패스 반영 상태

추적 매트릭스 Section 4.1~4.2의 6개 크리티컬 패스와 계획서 Section 8.1 비교.

| 크리티컬 패스 | 추적 매트릭스 | 계획서 반영 | 설계서 반영 | 상태 |
|:------------|:-----------|:---------:|:---------:|:----:|
| FR-S1-03 -> FR-S2-01 -> FR-S2-04 -> FR-S5-01 | Section 4.1 | **반영됨** (S1 Phase1에 FR-S1-03 우선, S2 Phase1에 FR-S2-01 배치) | **반영됨** (Section 11.1에 의존성 명시, 3.3+4.1 통합 설계) | OK |
| FR-S1-01 -> FR-S4-02 | Section 4.1 | **반영됨** (S1 WP1에 FR-S1-01) | **반영됨** (Section 11.2에 의존성 체인 명시) | OK |
| FR-S3-01 -> FR-S3-03 -> FR-S3-04 | Section 4.1 | **반영됨** (S3 WP1->WP2 순서) | **반영됨** (Section 11.1 Sprint 3 Phase 순서) | OK |
| FR-S2-03 -> FR-S5-02 | Section 4.1 | **반영됨** | **반영됨** | OK |
| FR-S3-05 -> FR-S5-03 | Section 4.1 | **반영됨** | **반영됨** | OK |
| FR-S1-06 -> FR-S4-09 | Section 4.1 | **반영됨** | **반영됨** (Section 8.1 통합 Dockerfile) | OK |

**결론**: 6개 크리티컬 패스 모두 계획서와 설계서에 정확히 반영됨. **갭 없음**.

### 5.2 병렬 실행 그룹 반영 상태

추적 매트릭스 Section 4.3의 병렬 실행 그룹과 계획서 Section 8.1 비교.

| 스프린트 | 추적 매트릭스 병렬 그룹 | 계획서 WP 구성 | 일치 여부 | 차이점 |
|:-------:|:---------------------|:-------------|:---------:|:------|
| S1 | S1-WP1(01,08), S1-WP2(02,03,10), S1-WP3(04,05,06,07), Serial(09) | S1-WP1(01,08), S1-WP2(02,03,09,10), S1-WP3(04~07) | **부분 일치** | 계획서 S1-WP2에 FR-S1-09 포함 (추적 매트릭스는 Serial로 분류) |
| S2 | S2-WP1(01,10), S2-WP2(05,06), S2-WP3(02,08), Serial(03,04,07,09) | S2-WP1(01,04,10), S2-WP2(02,03,05~09) | **부분 일치** | 계획서가 더 큰 그룹으로 묶음. 추적 매트릭스의 세밀한 의존성(S2-04->S2-01, S2-09->S2-05) 미반영 |
| S3 | S3-WP1(01,02,06), S3-WP2(05), S3-WP3(07,08), Serial(03,04) | S3-WP1(01,02,06), S3-WP2(03,04), S3-WP3(05,07,08) | **일치** | 그룹 구성 동일, 번호만 차이 |
| S4 | S4-WP1(01,03,07), S4-WP2(02,05), S4-WP3(09,10), Serial(04,06,08) | S4-WP1(01,04~06), S4-WP2(02,03), S4-WP3(09,10) | **부분 일치** | 계획서 S4-WP1에 안정성 그룹 배치, 추적 매트릭스의 S4-04 직렬 의존성(S4-05, S4-06 이후) 미반영 |
| S5 | S5-WP1(04,05,06), S5-WP2(03), Serial(01,02) | S5-WP1(01,02), S5-WP2(03~05) | **부분 일치** | 계획서가 01,02를 WP1에 묶었으나, 추적 매트릭스는 크로스 스프린트 의존성(S2-01, S2-03)으로 Serial 지정 |
| 크로스 스프린트 | S3과 S4 병렬 가능 | **반영됨** (Section 8.1: "Sprint 4 — Sprint 3과 병렬 가능") | **일치** | |

### 5.3 병렬 실행 갭 상세

| 갭 ID | 스프린트 | 추적 매트릭스 | 계획서 | 영향 |
|:-----:|:-------:|:-----------|:------|:-----|
| PG-01 | S1 | FR-S1-09는 FR-S1-04 이후 Serial | 계획서 S1-WP2에 병렬 포함 | Low - 같은 파일 영역이므로 순차 작업 권장 |
| PG-02 | S2 | FR-S2-04는 FR-S2-01 이후 Serial | 계획서 S2-WP1에 함께 배치 | **Medium** - Linux parse_json 완료 전 패키지 관리자 확장 불가 |
| PG-03 | S2 | FR-S2-09는 FR-S2-05 이후 Serial | 계획서 S2-WP2에 함께 배치 | Low - 동일 파일(figma/module.json) 순차 수정 필요 |
| PG-04 | S4 | FR-S4-04는 FR-S4-05, FR-S4-06 이후 Serial | 계획서 S4-WP1에 함께 배치 | **Medium** - 캐싱은 토큰 검증+뮤텍스 설계 후 구현해야 함 |

**권고**: PG-02와 PG-04는 계획서의 WP 내부에서 Phase 순서를 명시하거나, 추적 매트릭스의 Serial 지정을 반영하여 계획서를 수정해야 한다.

---

## 6. 보완 권고사항

### 6.1 계획서 추가 항목

| 우선순위 | 항목 | 현재 상태 | 권고 조치 |
|:-------:|:-----|:---------|:---------|
| **High** | FR-S3-07 범위 확장 | index.ts:32만 기재 | sheets.ts, calendar.ts, slides.ts, docs.ts의 `any` 위치 추가 (설계서와 정합성 맞춤) |
| **High** | FR-S3-09 (npm audit) 추가 | 미존재 | Sprint 3 FR 목록에 "CI 파이프라인에 `npm audit --audit-level=high` 단계 추가" 요구사항 신설 |
| **Medium** | FR-S2-11 (Docker Desktop 버전 체크) 추가 | 미존재 | OS-06 대응으로 Docker Desktop 4.42+ / macOS Ventura 호환성 체크 로직 FR 신설 또는 FR-S2-04 범위 확장 |
| **Medium** | FR-S1-11 (입력 검증 레이어) 명시 | 미존재 (설계서에만 있음) | Sprint 1에 횡단 관심사로 `sanitize.ts` 유틸리티 생성 FR 추가 |
| **Medium** | 병렬 실행 그룹 세분화 | WP 단위 기재 | PG-02(S2-04->S2-01), PG-04(S4-04->S4-05,S4-06) 직렬 의존성 명시 |
| **Low** | FR-S3-10 (보안 로깅) 검토 | 미존재 | 인증 실패, 입력 검증 실패 시 로깅 요구사항 검토 (Out of Scope에서 In Scope으로 전환 여부 결정) |
| **Low** | Pencil 모듈 보안 검토 | 미존재 | Pencil 모듈에 Sprint 1 수준의 보안 검토가 필요한지 별도 평가 |

### 6.2 설계서 추가 항목

| 우선순위 | 항목 | 현재 상태 | 권고 조치 |
|:-------:|:-----|:---------|:---------|
| **High** | FR-S2-02 임시 파일 정리 | temp dir 생성만 설계 | `trap 'rm -rf "$SHARED_TMP"' EXIT` 패턴 추가, 비정상 종료 시 cleanup 보장 |
| **High** | oauth.ts 리팩토링 가이드 | 7개 FR 순차 적용만 기술 | oauth.ts를 `auth-flow.ts`, `token-manager.ts`, `service-cache.ts`로 분리하는 리팩토링 로드맵 추가 |
| **Medium** | .env.example 템플릿 | 환경변수 각 FR에 분산 | 프로젝트 루트에 `.env.example` 포함 모든 신규 환경변수 일괄 문서화 설계 추가 |
| **Medium** | module.json 스키마 정의 | 개별 수정만 기술 | JSON Schema 정의 파일(`installer/module-schema.json`) 설계 추가 |
| **Medium** | ShellCheck CI 통합 | 미언급 | CI 파이프라인(Section 5.3)에 ShellCheck 단계 추가 |
| **Medium** | 마이그레이션 사용자 가이드 | 코드만 설계 | FR-S5-03 범위에 MCP 경로 마이그레이션 가이드 섹션 추가 |
| **Low** | 에러 메시지 포맷 표준 | retry.ts에 console.warn만 | 사용자 대면 에러 메시지 포맷 표준 정의 (prefix, error code, 해결 가이드 링크) |
| **Low** | TypeScript strict 호환성 테스트 | 미언급 | FR-S3-07 테스트에 `tsc --strict --noEmit` 검증 단계 추가 |
| **Low** | Docker 빌드 캐시 가이드 | 멀티스테이지만 기술 | 레이어 순서 최적화 및 `--mount=type=cache` 활용 가이드 |
| **Low** | i18n 방향 결정 | English-only + messages.ts 언급 | 향후 i18n 프레임워크 도입 여부 명시적 결정 (현재는 English-only, 키 기반 구조만 선제 적용) |

---

## 7. 구체적 추가 내용 제안

### 7.1 계획서: FR-S3-07 범위 확장 (즉시 반영)

현재 계획서 FR-S3-07:
```
FR-S3-07 | `any` 타입 제거 — `index.ts:32`의 `async (params: any)` 를 올바른 타입으로 교체
```

권고 수정:
```
FR-S3-07 | `any` 타입 제거 — `index.ts:32`, `sheets.ts:18,341`, `calendar.ts:288`,
          `slides.ts:135,156`, `docs.ts:236`의 `any`/`as any` 사용을 proper type으로 교체
```

### 7.2 계획서: FR-S3-09 신설 (npm audit CI 통합)

```
| FR-S3-09 | **npm audit CI 통합** — CI 파이프라인에 `npm audit --audit-level=high`
            단계 추가. High 이상 취약점 발견 시 빌드 실패 | **High** |
            `.github/workflows/ci.yml` | Security Architect 추가 발견 |
```

### 7.3 설계서: FR-S2-02 임시 파일 정리 추가

Section 4.2에 다음 추가:
```bash
run_module() {
    local mod="$1"
    if [ "$USE_LOCAL" != true ]; then
        SHARED_TMP=$(mktemp -d)
        # Guarantee cleanup on any exit (normal, error, signal)
        trap 'rm -rf "$SHARED_TMP"' EXIT INT TERM
        for shared_script in oauth-helper.sh; do
            curl -sSL "$BASE_URL/modules/shared/$shared_script" \
                -o "$SHARED_TMP/$shared_script" || true
        done
        export SHARED_DIR="$SHARED_TMP"
    fi
    # ...
}
```

### 7.4 설계서: .env.example 템플릿

프로젝트 루트에 `.env.example` 파일 추가 설계:
```bash
# Google Workspace MCP Configuration
# Copy to .env and fill in values

# OAuth Scopes (comma-separated: gmail,calendar,drive,docs,sheets,slides)
# Default: all scopes enabled
# GOOGLE_SCOPES=gmail,calendar,drive

# Timezone (IANA format, e.g., America/New_York)
# Default: system timezone via Intl API
# TIMEZONE=Asia/Seoul

# Atlassian Configuration (FR-S1-04)
# CONFLUENCE_URL=https://your-domain.atlassian.net/wiki
# CONFLUENCE_USERNAME=your@email.com
# CONFLUENCE_API_TOKEN=your-token
# JIRA_URL=https://your-domain.atlassian.net
# JIRA_USERNAME=your@email.com
# JIRA_API_TOKEN=your-token
```

### 7.5 설계서: CI 파이프라인 ShellCheck 단계 추가

Section 5.3 CI 워크플로우에 다음 job 추가:
```yaml
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ShellCheck
        run: sudo apt-get install -y shellcheck
      - name: Run ShellCheck
        run: |
          find installer/ -name "*.sh" -exec shellcheck -S warning {} +
```

### 7.6 설계서: oauth.ts 리팩토링 로드맵

Section 6에 추가:
```
oauth.ts 리팩토링 (7개 FR 적용 시 머지 충돌 방지):

현재 구조: oauth.ts (단일 파일, ~240줄)
  - generateAuthUrl() + callback handler
  - loadToken() + saveToken()
  - getGoogleServices()
  - config directory management

제안 구조:
  src/auth/
    config.ts         -- CONFIG_DIR, ensureConfigDir(), SCOPES (FR-S1-08, FR-S4-02)
    token-manager.ts  -- loadToken(), saveToken(), validateRefreshToken() (FR-S1-07, FR-S4-05)
    auth-flow.ts      -- generateAuthUrl(), callback, state validation, mutex (FR-S1-01, FR-S4-06)
    service-cache.ts  -- getGoogleServices(), singleton cache with TTL (FR-S4-04)
    index.ts          -- re-export public API (하위 호환)

적용 시점: Sprint 1 완료 후, Sprint 4 착수 전 리팩토링 수행
```

---

## 8. 89.6% 커버리지 누락 5건 분석

추적 매트릭스 Section 10 마지막 줄에 의하면 "48건 이슈 중 43건 대응 (89.6%), 5건 Out of Scope".

| # | 분석 이슈 ID | 심각도 | 내용 | Out of Scope 사유 | 타당성 |
|:-:|:----------:|:-----:|:-----|:----------------|:-----:|
| 1 | SEC-01 (부분) | Critical | GPG 서명 기반 스크립트 무결성 검증 | 인프라 별도 구축 필요 (키 관리, 서명 배포) | **타당** - GPG 인프라는 별도 프로젝트 스코프 |
| 2 | SEC-11 | Medium | 서드파티 Docker 이미지 검증 | 외부 이미지 공급망 보안은 프로젝트 범위 외 | **타당** - 이미지 서명 검증(cosign 등)은 인프라 레벨 |
| 3 | QA-05 | Low | 구조적 로깅 (structured logging) | 현재 단계에서 과도한 엔지니어링 | **타당** - 단, 보안 이벤트 로깅(FR-S3-10 제안)은 별도 검토 권장 |
| 4 | QA-09 | Low | CHANGELOG 자동 생성 | 도구 도입보다 코드 품질이 우선 | **타당** - Sprint 5 이후 검토 가능 |
| 5 | SEC-01 (GPG) | Critical | 원격 실행 시 MITM 방지 | HTTPS 사용으로 기본 보호, GPG는 추가 레이어 | **조건부 타당** - HTTPS가 보장되는 한 허용, 장기적으로 SRI hash 검토 |

**결론**: 5건 모두 Out of Scope 판정이 타당함. 다만 SEC-01(GPG)은 장기 로드맵에 Subresource Integrity(SRI) 해시 방식의 경량 검증을 검토할 가치가 있음.

---

## 9. 종합 갭 요약

| 카테고리 | 전체 항목 | 갭 없음 | 갭 발견 | 갭 비율 |
|:--------|:--------:|:------:|:------:|:------:|
| 44개 기본 FR | 44 | 44 | 0 | 0% |
| 잠재적 누락 요구사항 | 8 | 2 | 6 | 75% |
| 암묵적 요구사항 | 7 | 1 | 6 | 86% |
| 횡단 관심사 | 8 | 5 | 3 | 38% |
| 크리티컬 패스 | 6 | 6 | 0 | 0% |
| 병렬 실행 그룹 | 5 | 1 | 4 | 80% |
| 89.6% 커버리지 누락 | 5 | 5 | 0 | 0% |

### 9.1 갭 심각도 분류

| 심각도 | 건수 | 항목 |
|:-----:|:----:|:-----|
| **High** | 4 | FR-S3-07 범위 불일치, FR-S3-09(npm audit) 누락, FR-S2-02 cleanup 미설계, oauth.ts 리팩토링 가이드 부재 |
| **Medium** | 7 | FR-S2-11(Docker Desktop), FR-S1-11(입력검증) 계획서 미반영, .env.example 미설계, module.json 스키마 부재, ShellCheck CI 미반영, 마이그레이션 가이드 부재, 병렬 실행 PG-02/PG-04 |
| **Low** | 8 | FR-S3-10(보안로깅), Pencil 모듈, 에러 메시지 포맷, TypeScript strict 테스트, Docker 캐시 가이드, i18n 방향, 에러 처리 일관성, 병렬 실행 PG-01/PG-03 |

### 9.2 즉시 조치 권고 (High)

1. **계획서 FR-S3-07 범위 수정**: `index.ts:32` -> 7개 위치로 확장 (설계서와 정합성)
2. **계획서 FR-S3-09 추가**: npm audit CI 통합 요구사항 신설
3. **설계서 FR-S2-02 보완**: trap 기반 임시 파일 정리 추가
4. **설계서 oauth.ts 리팩토링 가이드**: 모듈 분리 로드맵 추가

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-12 | 초기 갭 분석 보고서 작성 - 3개 문서 교차 분석 | Gap Analyst Agent |
