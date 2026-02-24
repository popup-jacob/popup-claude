# 보안 검증 갭 분석 보고서

> Security Architect | 작성: 2026-02-12
> 대상 문서:
> - 검증보고서: `docs/03-analysis/security-verification-report.md`
> - 계획서: `docs/01-plan/features/adw-improvement.plan.md`
> - 설계서: `docs/02-design/security-spec.md`

---

## 1. 분석 개요

### 1.1 목적

보안 검증 보고서(security-verification-report.md)에서 식별된 12개 보안 이슈가 계획서(adw-improvement.plan.md)와 설계서(security-spec.md)에 정확히 반영되었는지 검증한다. 문서 간 불일치(갭)를 식별하고, 보완이 필요한 구체적 항목을 제시한다.

### 1.2 분석 범위

| 항목 | 내용 |
|------|------|
| 보안 이슈 수 | 12건 (검증보고서 기준) |
| 검증 항목 | 위험도 반영, 수정 코드 정확성, OWASP 매핑, 공수 추정, 우선순위 |
| 문서 기준일 | 모두 2026-02-12 (동일 커밋 7b16685 기준) |

---

## 2. 보안 이슈별 반영 상태

| SEC-ID | 이슈명 | 검증보고서 위험도 | 계획서 반영 | 설계서 반영 | 갭 |
|--------|-------|:-------------:|:---------:|:---------:|-----|
| SEC-01 | curl\|bash 무결성 미검증 | Critical | O (FR-S1-03 부분, GPG는 Out of Scope) | X (미포함) | **설계서 누락**: SEC-01의 checksum 검증 패턴이 설계서에 없음. 계획서는 FR-S1-03으로 osascript 인젝션만 대응하고 `download_and_verify()` 패턴은 Out of Scope 처리 |
| SEC-02 | Atlassian API 토큰 평문 저장 | Critical | O (FR-S1-04) | O (FR-S1-04) | 없음 |
| SEC-03 | Figma 토큰 노출 | **Informational** (다운그레이드) | O (FR-S1-05, Low로 다운) | X (미포함) | **설계서 누락**: SEC-03은 Informational이므로 설계서 미포함이 적절할 수 있으나, 계획서에는 FR-S1-05로 여전히 존재. 계획서의 FR-S1-05 설명에 다운그레이드 사실이 명확히 기술되어 있어 정합성은 양호 |
| SEC-04 | token.json 암호화 미적용 | High | O (FR-S1-07) | O (FR-S1-07) | 없음 |
| SEC-05 | Docker non-root 미사용 | High | O (FR-S1-06) | O (FR-S1-06) | 없음 |
| SEC-06 | Windows 관리자 권한 과다 요청 | High | O (FR-S2-10, Sprint 2) | X (미포함) | **설계서 누락**: Sprint 1 설계서 범위 외이므로 구조적 누락은 아니나, 검증보고서의 상세 수정 코드(`Invoke-AsAdmin` 패턴)가 아직 어떤 설계서에도 반영되지 않음 |
| SEC-07 | 과도한 OAuth 스코프 | High | O (FR-S4-02, Sprint 4) | X (미포함) | **설계서 누락**: Sprint 4 범위이므로 Sprint 1 설계서 미포함은 구조적으로 정당. 향후 Sprint 4 설계서에서 반영 필요 |
| SEC-08 | OAuth state 파라미터 누락 | High | O (FR-S1-01) | O (FR-S1-01) | 없음 |
| SEC-08a | osascript 템플릿 인젝션 | High | O (FR-S1-03) | O (FR-S1-03) | 없음 |
| GWS-07 | Drive API 쿼리 인젝션 | High | O (FR-S1-02) | O (FR-S1-02) | 없음 |
| GWS-08 | Gmail 이메일 헤더 인젝션 | Medium | O (FR-S1-10) | O (FR-S1-10) | 없음 |
| SEC-12 | Atlassian install.sh 변수 이스케이핑 | Medium | O (FR-S1-09) | O (FR-S1-09) | 없음 |

### 2.1 반영률 요약

| 구분 | 계획서 | 설계서 |
|------|:-----:|:-----:|
| 완전 반영 | 12/12 (100%) | 8/12 (67%) |
| 부분 반영 | 0 | 0 |
| 미반영 (구조적 정당) | 0 | 3건 (SEC-06, SEC-07, SEC-03) |
| 미반영 (갭) | 0 | **1건 (SEC-01)** |

---

## 3. 계획서 갭

### 3.1 공수 추정 불일치

검증보고서와 계획서 간 공수 추정 비교:

| SEC-ID | 검증보고서 공수 | 계획서 대응 ID | 계획서 명시 공수 | 불일치 |
|--------|:------------:|:------------:|:-------------:|:------:|
| SEC-01 | 6-8h | FR-S1-03 (부분) | 명시 안 됨 | **갭**: 계획서에 개별 FR별 공수 미기재 |
| SEC-02 | 4-6h | FR-S1-04 | 명시 안 됨 | 동일 |
| SEC-03 | 0.5h | FR-S1-05 | 명시 안 됨 | 동일 |
| SEC-04 | 2h (권한), 6-8h (암호화) | FR-S1-07 | 명시 안 됨 | 동일 |
| SEC-05 | 2-3h | FR-S1-06 | 명시 안 됨 | 동일 |
| SEC-06 | 4-6h | FR-S2-10 | 명시 안 됨 | 동일 |
| SEC-07 | 4-6h | FR-S4-02 | 명시 안 됨 | 동일 |
| SEC-08 | 1-2h | FR-S1-01 | 명시 안 됨 | 동일 |
| SEC-08a | 3-4h | FR-S1-03 | 명시 안 됨 | 동일 |
| GWS-07 | 2-3h | FR-S1-02 | 명시 안 됨 | 동일 |
| GWS-08 | 2h | FR-S1-10 | 명시 안 됨 | 동일 |
| SEC-12 | 3-4h | FR-S1-09 | 명시 안 됨 | 동일 |

**핵심 갭**: 계획서는 FR(Functional Requirement) 테이블에 개별 공수를 기재하지 않는다. 대신 Appendix A.4에서 에이전트별 합산 공수만 제시한다:

- 검증보고서 총 공수: **34-49시간**
- 계획서 Appendix A.4 보안 에이전트 전체 공수: **34-49시간** (일치)
- 계획서 Appendix A.4 보안 에이전트 Critical Path: **12-16시간**

**결론**: 총합 수준에서는 검증보고서의 34-49시간이 계획서에 정확히 반영됨. 그러나 개별 이슈별 공수 추정이 계획서 본문(Sprint 1 Requirements 테이블)에 기재되지 않아, Sprint 계획 시 세부 일정 수립에 어려움이 있을 수 있다.

반면, 설계서(security-spec.md)는 Sprint 1 Effort Estimate 테이블에서 개별 FR별 공수를 명시하고 있으며, 합계 **22-33시간**으로 산출하고 있다. 이는 검증보고서의 34-49시간 중 Sprint 1에 해당하는 이슈들의 합산과 비교 시 상이하다(아래 설계서 갭 참조).

### 3.2 우선순위 불일치

검증보고서와 계획서 간 우선순위 비교:

| SEC-ID | 검증보고서 우선순위 | 검증보고서 위험도 | 계획서 우선순위 | 불일치 |
|--------|:---------------:|:-------------:|:------------:|:------:|
| SEC-01 | 1위 | Critical | FR-S1-03: **Critical** | 없음 (부분 대응이나 우선순위 일치) |
| SEC-08a | 2위 | High | FR-S1-03: **Critical** | 없음 (계획서가 상향 조정, 보수적 판단) |
| SEC-02 | 3위 | Critical | FR-S1-04: **High** | **갭**: 검증보고서는 Critical인데 계획서는 High로 다운 |
| SEC-04 | 4위 | High | FR-S1-07: **High** | 없음 |
| SEC-08 | 5위 | High | FR-S1-01: **Critical** | **갭**: 검증보고서는 High인데 계획서는 Critical로 상향 |
| GWS-07 | 6위 | High | FR-S1-02: **Critical** | **갭**: 검증보고서는 High인데 계획서는 Critical로 상향 |
| SEC-12 | 7위 | Medium | FR-S1-09: **High** | **갭**: 검증보고서는 Medium인데 계획서는 High로 상향 |
| GWS-08 | 8위 | Medium | FR-S1-10: **Medium** | 없음 |
| SEC-05 | 9위 | High | FR-S1-06: **High** | 없음 |
| SEC-06 | 10위 | High | FR-S2-10: **Medium** | **갭**: 검증보고서는 High인데 계획서는 Medium으로 다운 |
| SEC-07 | 11위 | High | FR-S4-02: **High** | 없음 |
| SEC-03 | 12위 | Informational | FR-S1-05: **Low** | 양호 (Informational을 Low로 매핑, 합리적) |

**주요 갭**:
1. **SEC-02 (Critical -> High)**: 가장 심각한 불일치. Atlassian 토큰 평문 저장은 검증보고서에서 Critical로 확인되었으나 계획서에서 High로 다운그레이드됨.
2. **SEC-08, GWS-07 (High -> Critical)**: 계획서가 검증보고서보다 상향 조정. 보수적 접근이므로 양호하나, 검증보고서와의 정합성 기준에서는 불일치.
3. **SEC-06 (High -> Medium)**: Windows 관리자 권한 이슈를 Sprint 2로 이연하면서 Medium으로 다운그레이드.
4. **SEC-12 (Medium -> High)**: 계획서가 상향 조정.

### 3.3 누락 항목

| 누락 유형 | 상세 |
|----------|------|
| SEC-01 핵심 대응 누락 | 검증보고서는 SEC-01의 핵심 대응으로 "SHA-256 체크섬 검증 + GPG 서명"을 제안. 계획서는 GPG를 Out of Scope로 처리하고, SHA-256 체크섬 검증(`download_and_verify()` 패턴)도 명시적 FR이 없음. FR-S1-03은 osascript 인젝션만 대응 |
| 크로스 커팅 이슈 미반영 | 검증보고서의 "Cross-Cutting Concerns" 4건 중 (1) 입력 검증 레이어 부재는 설계서의 Input Validation Layer로 대응됨. (2) 에러 메시지 정보 누출은 설계서의 에러 핸들링으로 부분 대응됨. 그러나 (3) **보안 로깅 부재**와 (4) **npm audit 미적용**은 계획서에 명시적 FR이 없음 |
| 보안 로깅 | 검증보고서가 OWASP A09(Security Logging and Monitoring Failures)로 식별한 보안 로깅 부재가 계획서/설계서 모두에서 누락. 최소한 "인증 시도 실패", "토큰 갱신", "파일 권한 변경" 이벤트의 로깅이 필요 |
| npm audit | 검증보고서의 "Dependencies Not Audited" 지적에 대해 계획서 QA-05가 Out of Scope로 처리하지만, `npm ci` 전환은 설계서에서 Dockerfile 변경으로 부분 대응됨. `npm audit` CI 단계는 여전히 미반영 |

---

## 4. 설계서 갭

### 4.1 수정 코드 불일치

Sprint 1 범위 내 검증보고서 vs 설계서 수정 코드 비교:

| SEC-ID | 검증보고서 수정 코드 | 설계서 수정 코드 | 불일치 |
|--------|:------------------:|:---------------:|:------:|
| SEC-01 | `download_and_verify()` (SHA-256 체크섬) | 미포함 | **갭**: 설계서에 대응 없음 |
| SEC-02 | `.env` 파일 + `chmod 600` + `--env-file` | `.env` 파일 + `chmod 600` + `--env-file` + `chmod 600 .mcp.json` | 설계서가 더 상세. **양호** |
| SEC-03 | 플레이스홀더 명칭 변경 권고 | 미포함 (Informational이므로) | 구조적 누락, 수용 가능 |
| SEC-04 | `fs.writeFileSync(..., { mode: 0o600 })` + `ensureConfigDir` mode 0o700 | 동일 + 방어적 `chmodSync` 추가 | 설계서가 더 상세. **양호** |
| SEC-05 | `groupadd/useradd` + `USER mcp` + chown | 동일 + `npm ci` + `HEALTHCHECK` + `NODE_ENV=production` | 설계서가 더 상세. **양호** |
| SEC-06 | `Invoke-AsAdmin` 패턴 | 미포함 (Sprint 2 범위) | 구조적 누락, Sprint 2 설계서 필요 |
| SEC-07 | `SCOPE_MAP` + `getScopesForModules()` | 미포함 (Sprint 4 범위) | 구조적 누락, Sprint 4 설계서 필요 |
| SEC-08 | `crypto.randomBytes(32)` + state 검증 | 동일 + 타임아웃 + HTML 에러 페이지 | 설계서가 더 상세. **양호** |
| SEC-08a | `echo "$json" \| node -e "..."` stdin 방식 | 동일 패턴 + `process.stdout.write` (trailing newline 방지) | 설계서가 더 상세. **양호** |
| GWS-07 | `escapeDriveQuery()` + `DRIVE_ID_PATTERN` 검증 | 동일 + `validateDriveId()` 함수 + 전체 Drive 핸들러에 적용 | 설계서가 더 상세. **양호** |
| GWS-08 | `sanitizeEmailHeader()` + `validateEmail()` | 동일 + `validateEmailAddress()` (콤마구분 + Name <email> 지원) | 설계서가 더 상세. **양호** |
| SEC-12 | 환경변수 방식 (`MCP_CONFIG_PATH=... node -e "process.env..."`) | 동일 + `google/install.sh`도 함께 수정 + `{ mode: 0o600 }` .mcp.json 쓰기 | 설계서가 더 상세. **양호** |

**결론**: Sprint 1 범위 내 9건 중 8건은 설계서가 검증보고서보다 더 상세하고 구체적인 수정 코드를 제시. SEC-01만 완전 누락.

### 4.2 OWASP 매핑 불일치

| SEC-ID | 검증보고서 OWASP | 설계서 OWASP | 불일치 |
|--------|:---------------:|:-----------:|:------:|
| SEC-01 | A08 (Software and Data Integrity Failures) | N/A (미포함) | 설계서 미포함으로 비교 불가 |
| SEC-02 | A02 (Cryptographic Failures) | A02 | 없음 |
| SEC-03 | N/A (Informational) | N/A (미포함) | 해당 없음 |
| SEC-04 | A02 (Cryptographic Failures) | A02 | 없음 |
| SEC-05 | A05 (Security Misconfiguration) | A05 | 없음 |
| SEC-06 | A04 (Insecure Design) | N/A (미포함) | 설계서 미포함으로 비교 불가 |
| SEC-07 | A01 (Broken Access Control) | N/A (미포함) | 설계서 미포함으로 비교 불가 |
| SEC-08 | A07 (Identification and Authentication Failures) | A07 | 없음 |
| SEC-08a | A03 (Injection) | A03 | 없음 |
| GWS-07 | A03 (Injection) | A03 | 없음 |
| GWS-08 | A03 (Injection) | A03 | 없음 |
| SEC-12 | A03 (Injection) | A03 | 없음 |

**결론**: 설계서에 포함된 모든 이슈의 OWASP 매핑은 검증보고서와 100% 일치. 불일치 없음.

### 4.3 누락 항목

| 누락 항목 | 심각도 | 상세 |
|----------|:------:|------|
| **SEC-01 전체** | **Critical** | 검증보고서에서 가장 높은 우선순위(1위)로 지정된 `curl\|bash` 무결성 검증이 설계서에 완전히 누락. 계획서에서 GPG 서명을 Out of Scope으로 처리했으나, SHA-256 체크섬 검증은 Out of Scope가 아님에도 설계서에 반영되지 않음 |
| **FR-S1-05 (SEC-03)** | Low | Figma 플레이스홀더 명칭 변경은 계획서에 FR-S1-05로 존재하나 설계서 미포함. Low 우선순위이므로 영향 미미 |
| **Input Validation Layer 확장** | Medium | 설계서의 Validation Coverage Matrix가 Drive/Gmail만 커버. Calendar, Docs, Sheets, Slides 도구의 입력 검증은 미정의 |
| **보안 로깅** | Medium | 검증보고서의 Cross-Cutting Concern #3 (OWASP A09)에 대한 설계 없음 |

### 4.4 설계서 공수와 검증보고서 공수 비교

Sprint 1 해당 이슈들의 공수를 비교한다:

| FR-ID | 검증보고서 해당 SEC | 검증보고서 공수 | 설계서 공수 | 차이 |
|-------|:------------------:|:-------------:|:---------:|:----:|
| FR-S1-01 | SEC-08 | 1-2h | 1-2h | 일치 |
| FR-S1-02 | GWS-07 | 2-3h | 2-3h | 일치 |
| FR-S1-03 | SEC-08a | 3-4h | 3-4h | 일치 |
| FR-S1-04 | SEC-02 | 4-6h (env file) | 4-6h | 일치 |
| FR-S1-06 | SEC-05 | 2-3h | 2-3h | 일치 |
| FR-S1-07 | SEC-04 | 2h (권한만) | 0.5h | **갭**: 설계서가 더 낙관적 (권한 설정만이므로 합리적) |
| FR-S1-08 | SEC-04 (관련) | (포함) | 0.5h | 검증보고서에서 별도 분리 안 됨 |
| FR-S1-09 | SEC-12 | 3-4h | 2-3h | **갭**: 설계서가 1시간 낙관적 |
| FR-S1-10 | GWS-08 | 2h | 1-2h | 근사 일치 |
| 입력 검증 레이어 | (Cross-Cutting) | N/A | 2-3h | 검증보고서에 별도 공수 없음, 설계서 추가 항목 |
| 통합 테스트 | N/A | N/A | 3-4h | 검증보고서에 별도 공수 없음, 설계서 추가 항목 |
| **합계** | | **~24-32h** (Sprint 1 해당분 추산) | **22-33h** | 근사 일치 |

**결론**: 개별 이슈 수준에서 1-2시간 정도의 차이가 존재하나, 합계 범위가 겹쳐서 전체적으로는 정합. 설계서가 "입력 검증 레이어"와 "통합 테스트"를 추가 항목으로 산출한 것은 적절하며, 검증보고서에는 이 항목들이 포함되지 않았다.

---

## 5. 보완 권고사항

### 5.1 계획서 수정 사항

| # | 수정 대상 | 현재 상태 | 권고 |
|---|----------|----------|------|
| P-01 | **SEC-01 대응 FR 추가** | FR-S1-03이 osascript 인젝션만 대응, SHA-256 체크섬은 미대응 | Sprint 1에 `FR-S1-11: 원격 스크립트 다운로드 무결성 검증` 추가. `download_and_verify()` 패턴으로 `curl\|bash`를 `curl -o tmpfile + shasum 검증 + source` 로 변경. GPG 서명은 Out of Scope 유지 |
| P-02 | **SEC-02 우선순위 정정** | FR-S1-04가 **High**로 표기 | **Critical**로 상향. 검증보고서에서 Critical로 확인된 이슈이며, 계획서 Appendix A.1에서도 Critical로 기록되어 있어 본문과 부록 간 불일치 |
| P-03 | **SEC-06 우선순위 정정** | FR-S2-10이 **Medium**으로 표기 | **High**로 복원. 검증보고서에서 High로 확인. Sprint 2 이연은 유지하되 우선순위는 원래 수준 반영 |
| P-04 | **개별 FR 공수 명시** | Sprint 요구사항 테이블에 공수 열 없음 | 각 FR에 검증보고서 기반 공수 추정을 열로 추가. Sprint별 합산 시간 산출 가능하도록 |
| P-05 | **보안 로깅 FR 추가** | 누락 | Sprint 3 또는 4에 `FR-Sx-xx: 보안 이벤트 로깅` 추가. OWASP A09 대응. 최소 항목: 인증 실패, 토큰 갱신, 파일 권한 변경 |
| P-06 | **npm audit CI 단계 추가** | QA-05 Out of Scope | FR-S3-03(CI 자동화)에 `npm audit` 단계를 포함하도록 확장. 또는 별도 FR로 분리 |

### 5.2 설계서 수정 사항

| # | 수정 대상 | 현재 상태 | 권고 |
|---|----------|----------|------|
| D-01 | **SEC-01 설계 추가** | 완전 누락 | `FR-S1-11: Remote Script Integrity Verification` 섹션 추가. `checksums.json` 매니페스트 + `download_and_verify()` 함수 설계. install.sh의 `curl\|bash` 패턴 3곳 + install.ps1의 `irm\|iex` 패턴 1곳 대응 |
| D-02 | **Input Validation 확장** | Drive/Gmail만 커버 | Calendar, Docs, Sheets, Slides 도구의 입력 검증 매트릭스 추가. 특히 Calendar의 날짜/시간 파라미터, Sheets의 범위 문자열(A1 notation) 검증 |
| D-03 | **FR-S1-07 공수 조정** | 0.5h | 1h로 조정. 기존 파일 마이그레이션(기존 644 -> 600) 및 Windows 호환성 테스트 포함 시 0.5h는 낙관적 |
| D-04 | **google/install.sh 범위 명시** | FR-S1-09에서 언급하나 별도 설계 상세 부족 | google/install.sh lines 330-346의 전체 수정 코드를 상세히 기술. 현재는 간략한 코드만 제시 |

---

## 6. 구체적 추가 내용 제안

### 6.1 SEC-01 설계서 추가안 (D-01 대응)

다음 내용을 `security-spec.md`에 추가할 것을 권고한다:

```markdown
## FR-S1-11: Remote Script Integrity Verification

**Verification Report Reference:** SEC-01
**OWASP Mapping:** A08 -- Software and Data Integrity Failures
**Severity:** Critical
**Effort:** 6-8 hours

### 1. Current Vulnerability

install.sh lines 350-351:
- `curl -sSL "$BASE_URL/modules/$module_name/install.sh" | bash`

install.sh lines 101-117:
- `curl -sSL "$BASE_URL/modules.json"` (무결성 미검증)
- `curl -sSL "$BASE_URL/modules/$name/module.json"` (무결성 미검증)

install.ps1 line 336:
- `irm "$BaseUrl/modules/$ModuleName/install.ps1" | iex`

### 2. Refactored Design

1. GitHub 리포지토리에 `checksums.json` 발행:
   - 각 스크립트/모듈 파일의 SHA-256 해시 포함
   - 릴리스 시 자동 생성 (CI/CD 파이프라인)

2. `download_and_verify()` 함수:
   - 원격 파일을 임시 파일로 다운로드
   - SHA-256 해시 비교
   - 일치 시에만 실행

3. 실패 시 명확한 에러 메시지 출력 후 중단
```

### 6.2 계획서 FR-S1-04 우선순위 정정안 (P-02 대응)

계획서 Sprint 1 테이블에서:

**현재**: `FR-S1-04 | ... | **High** | ...`
**수정**: `FR-S1-04 | ... | **Critical** | ...`

부록 A.1과의 정합성 확보.

### 6.3 계획서 개별 FR 공수 열 추가안 (P-04 대응)

Sprint 1 테이블에 "공수(h)" 열을 추가:

| ID | Requirement | Priority | 공수(h) | 대상 파일 |
|----|-------------|:--------:|:-------:|----------|
| FR-S1-01 | OAuth state 파라미터 추가 | Critical | 1-2 | oauth.ts:113-118 |
| FR-S1-02 | Drive API 쿼리 이스케이핑 | Critical | 2-3 | drive.ts:18,59 |
| FR-S1-03 | osascript 인젝션 방지 | Critical | 3-4 | install.sh:29-39 |
| ... | ... | ... | ... | ... |

### 6.4 보안 로깅 FR 추가안 (P-05 대응)

```markdown
| FR-S3-09 | **보안 이벤트 로깅** -- 인증 실패/성공, 토큰 갱신, 파일 권한 변경 이벤트를
  stderr에 구조화된 형태로 출력. 최소 필드: timestamp, event_type, result,
  detail | **Medium** | `oauth.ts`, `index.ts` | OWASP A09: 보안 로깅 부재 |
```

---

## 7. 종합 평가

### 7.1 문서 정합성 점수

| 비교 축 | 점수 | 근거 |
|---------|:----:|------|
| 검증보고서 -> 계획서 | **85/100** | 12건 전체 반영이나, SEC-01 핵심 대응(checksum) 누락, SEC-02 우선순위 불일치, 개별 공수 미기재 |
| 검증보고서 -> 설계서 | **78/100** | Sprint 1 범위 내 높은 정합성(8/9건 양호), 그러나 SEC-01 완전 누락(Critical)이 큰 감점 요인 |
| 계획서 <-> 설계서 | **90/100** | Sprint 1 범위 내 FR-S1-01~S1-10 대부분 양방향 일치. FR-S1-05 설계 미포함은 Low이므로 감점 미미 |

### 7.2 조치 우선순위

1. **(즉시)** SEC-01 대응 FR 및 설계 추가 -- Critical 이슈의 완전 누락은 가장 시급
2. **(즉시)** SEC-02 (FR-S1-04) 우선순위를 Critical로 정정
3. **(Sprint 1 착수 전)** 개별 FR 공수를 계획서에 반영하여 Sprint 계획 정밀도 확보
4. **(Sprint 3 계획 시)** 보안 로깅 FR 추가, npm audit CI 단계 추가
5. **(Sprint 2/4 설계 시)** SEC-06, SEC-07의 설계서 작성

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-12 | 초안 작성 -- 12개 보안 이슈 전수 갭 분석 | Security Architect Agent |
