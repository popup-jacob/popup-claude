# Plan: Script Modularization (final-installer-v2)

> **Feature**: script-modularization
> **Created**: 2026-02-03
> **Status**: Plan Phase
> **Project**: final-installer-v2

---

## 1. Overview

### 1.1 Problem Statement
현재 final-installer(v1)는 `setup_basic.ps1`과 `setup_mcp.ps1` 두 개의 분리된 스크립트로 구성되어 있어 사용자가 두 번에 나눠 실행해야 합니다. 또한 MCP 설정 시 모든 옵션이 대화형으로 진행되어, 원하는 기능만 선택적으로 설치하기 어렵습니다.

### 1.2 Goal
파라미터 기반의 모듈화된 설치 시스템을 구축하여, 하나의 명령어로 원하는 기능만 선택 설치할 수 있도록 합니다.

```powershell
# 예시: Google과 Jira 모두 설치
& ([scriptblock]::Create((irm .../install.ps1))) -google -jira

# 예시: 기본만 설치 (Claude + bkit)
& ([scriptblock]::Create((irm .../install.ps1)))
```

### 1.3 Success Criteria
- [ ] `install.ps1` - Windows 메인 진입점 (파라미터 파싱)
- [ ] `install.sh` - Mac/Linux 메인 진입점 (파라미터 파싱)
- [ ] `modules/base.ps1` - 기본 설치 모듈 (v1 setup_basic.ps1 마이그레이션)
- [ ] `modules/base.sh` - 기본 설치 모듈 (Mac/Linux)
- [ ] `modules/google.ps1` - Google MCP 모듈 (v1 setup_mcp.ps1에서 추출)
- [ ] `modules/google.sh` - Google MCP 모듈 (Mac/Linux)
- [ ] `modules/jira.ps1` - Jira MCP 모듈 (v1 setup_mcp.ps1에서 추출)
- [ ] `modules/jira.sh` - Jira MCP 모듈 (Mac/Linux)
- [ ] 하나의 터미널 창에서 모든 설치 순차 진행

---

## 2. Requirements Analysis

### 2.1 Current State (AS-IS) - v1 구조

```
final-installer/
├── setup_basic.ps1      # 200줄 - Node, Git, VS Code, Docker, Claude, bkit
├── setup_mcp.ps1        # 553줄 - Google MCP + Jira MCP (대화형)
├── setup_admin.ps1      # Google Cloud Admin 전용
├── setup_all.sh         # Mac/Linux 통합 스크립트
└── setup_admin.sh       # Mac/Linux Admin 전용
```

**v1 문제점:**
1. 두 번 실행 필요 (basic → 재부팅 → mcp)
2. 기능별 선택 불가 (Google만 또는 Jira만 설치 어려움)
3. 자동화 불가 (모든 입력이 대화형)

### 2.2 Target State (TO-BE) - v2 구조

```
final-installer-v2/
├── install.ps1          # 메인 진입점 (파라미터 파싱 + 모듈 호출)
├── install.sh           # Mac/Linux 메인 진입점
└── modules/
    ├── base.ps1         # 기본 설치 (Node, Git, VS Code, Docker, Claude, bkit)
    ├── base.sh
    ├── google.ps1       # Google MCP 모듈
    ├── google.sh
    ├── jira.ps1         # Jira MCP 모듈
    └── jira.sh
```

**v2 장점:**
1. 한 번 실행으로 완료
2. 파라미터로 기능 선택 (`-google`, `-jira`)
3. CI/CD 자동화 가능 (비대화형 옵션)

### 2.3 Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-01 | install.ps1 파라미터 파싱 (-google, -jira) | P0 | ARCHITECTURE.md |
| FR-02 | base 모듈 항상 실행 | P0 | ARCHITECTURE.md |
| FR-03 | 선택된 모듈만 순차 실행 | P0 | ARCHITECTURE.md |
| FR-04 | 진행 상황 표시 ([1/N] Installing...) | P1 | ARCHITECTURE.md |
| FR-05 | 에러 발생 시 중단 및 메시지 출력 | P1 | New |
| FR-06 | Admin/Employee 분기 유지 (Google) | P0 | v1 setup_mcp.ps1 |
| FR-07 | Rovo/mcp-atlassian 분기 유지 (Jira) | P0 | v1 setup_mcp.ps1 |

---

## 3. Module Specifications

### 3.1 install.ps1 (메인 진입점)

```powershell
param(
    [switch]$google,      # Google MCP 설치
    [switch]$jira,        # Jira MCP 설치
    [switch]$all,         # 전체 설치
    [switch]$skipBase     # 기본 설치 스킵 (테스트용)
)
```

**역할:**
- 파라미터 파싱
- 모듈 순차 호출 (irm + iex 패턴)
- 진행 상황 표시
- 최종 결과 요약

### 3.2 modules/base.ps1

**v1 setup_basic.ps1에서 마이그레이션:**
- winget 체크
- Node.js 설치
- Git 설치
- VS Code 설치
- Docker Desktop 설치
- Claude CLI 설치 (npm)
- bkit 플러그인 설치

**변경점:**
- Admin 체크/권한 상승 로직을 install.ps1로 이동
- 독립 실행 가능하도록 유지

### 3.3 modules/google.ps1

**v1 setup_mcp.ps1 Google 섹션에서 추출:**
- Docker 실행 체크
- Admin/Employee 분기
- Admin: gcloud 설치, 프로젝트 생성, API 활성화, OAuth 설정
- Employee: client_secret.json 체크, Docker 이미지 pull, OAuth 인증
- .mcp.json 설정

### 3.4 modules/jira.ps1

**v1 setup_mcp.ps1 Jira 섹션에서 추출:**
- Rovo MCP (비개발자) - SSE 연결
- mcp-atlassian (개발자) - Docker + API Token
- .mcp.json 설정

---

## 4. Implementation Order

```
Phase 1: 메인 진입점
├── 1.1 install.ps1 작성 (파라미터 파싱 + 모듈 호출 로직)
└── 1.2 install.sh 작성 (Bash 버전)

Phase 2: Base 모듈
├── 2.1 modules/base.ps1 작성 (v1 setup_basic.ps1 마이그레이션)
└── 2.2 modules/base.sh 작성

Phase 3: Google 모듈
├── 3.1 modules/google.ps1 작성 (v1에서 추출)
└── 3.2 modules/google.sh 작성

Phase 4: Jira 모듈
├── 4.1 modules/jira.ps1 작성 (v1에서 추출)
└── 4.2 modules/jira.sh 작성

Phase 5: 테스트 & 검증
├── 5.1 Windows 전체 플로우 테스트
└── 5.2 Mac/Linux 전체 플로우 테스트
```

---

## 5. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| 모듈 간 의존성 문제 | 설치 실패 | 각 모듈에 의존성 체크 로직 포함 |
| 재부팅 필요 (Docker) | UX 저하 | 재부팅 필요 여부 명확히 안내 |
| PATH 갱신 문제 | 명령어 인식 실패 | 각 설치 후 PATH 새로고침 |

---

## 6. References

- ARCHITECTURE.md: 전체 설계 문서
- v1 setup_basic.ps1: 기본 설치 로직
- v1 setup_mcp.ps1: MCP 설정 로직

---

## Next Steps

1. ✅ Plan 문서 작성 완료
2. ⏳ Design 문서 작성 (상세 설계)
3. ⏳ 구현 시작
