# Plan: Dynamic Module System

> **Feature**: dynamic-module-system
> **Created**: 2026-02-03
> **Status**: Planning

---

## 1. 배경 (Background)

현재 설치 스크립트(install.ps1, install.sh)는 모듈이 하드코딩되어 있어,
새 모듈 추가 시 메인 스크립트 수정이 필요합니다.

커뮤니티에서 모듈을 기여할 수 있는 확장 가능한 구조가 필요합니다.

---

## 2. 목표 (Goals)

### Primary Goals
- [x] 모듈 자동 인식 시스템 구축 (modules/ 폴더 스캔)
- [x] module.json 표준 스펙 정의 (7개 모듈 적용)
- [ ] 랜딩페이지 동적 모듈 표시 (adw-landing-page 연동 예정)
- [ ] 커뮤니티 모듈 기여 워크플로우 문서화 (CONTRIBUTING.md)

### Success Criteria
- 새 모듈 추가 시 install.ps1/install.sh 수정 불필요
- module.json만 있으면 랜딩페이지에 자동 표시
- 기존 google, atlassian 모듈을 새 포맷으로 마이그레이션

---

## 3. 범위 (Scope)

### In Scope
- module.json 스펙 정의
- install.ps1/install.sh 동적 모듈 로딩 구현
- 기존 모듈 리팩토링 (google, atlassian → 새 폴더 구조)
- 새 모듈 추가 (slack, notion, github)
- registry.json (모듈 목록 관리)
- 랜딩페이지 동적 생성

### Out of Scope
- 모듈 자동 업데이트 시스템
- 버전 호환성 체크
- 모듈 의존성 관리

---

## 4. 기술 요구사항 (Technical Requirements)

### 4.1 module.json 스펙

```json
{
  "name": "module-id",
  "displayName": "Display Name",
  "description": "Module description",
  "version": "1.0.0",
  "author": "author-name",

  "type": "mcp",
  "complexity": "simple | moderate | complex",

  "requirements": {
    "docker": true,
    "node": false,
    "adminSetup": false
  },

  "mcpConfig": {
    "serverName": "mcp-server-name",
    "command": "docker | npx | node",
    "argsTemplate": ["arg1", "arg2", "{variable}"]
  },

  "links": {
    "docs": "https://...",
    "repo": "https://..."
  }
}
```

### 4.2 폴더 구조

```
final-installer-v2/
├── install.ps1              # 동적 모듈 로딩
├── install.sh               # 동적 모듈 로딩
├── registry.json            # 모듈 목록
│
├── modules/
│   ├── base/
│   │   ├── module.json
│   │   ├── install.ps1
│   │   └── install.sh
│   │
│   ├── google/
│   │   ├── module.json
│   │   ├── install.ps1
│   │   ├── install.sh
│   │   └── README.md
│   │
│   ├── atlassian/
│   ├── slack/
│   ├── notion/
│   └── github/
│
└── web/
    └── index.html           # 동적 모듈 체크박스 생성
```

### 4.3 명령어 방식 변경

**Before:**
```powershell
.\install.ps1 -google -jira
```

**After:**
```powershell
.\install.ps1 -modules "google,atlassian"
```

### 4.4 동적 로딩 로직

```powershell
# 1. registry.json 읽기
# 2. 사용자가 선택한 모듈 파싱
# 3. 각 모듈의 module.json 읽기
# 4. 각 모듈의 install.ps1 실행
# 5. mcpConfig로 .mcp.json 업데이트
```

---

## 5. 커뮤니티 기여 워크플로우

### 새 모듈 기여 방법

```
1. modules/{my-module}/ 폴더 생성
2. module.json 작성 (스펙 준수)
3. install.ps1, install.sh 작성
4. README.md 작성 (사용 가이드)
5. PR 보내기

→ 메인테이너 승인 시:
  - registry.json에 모듈 추가
  - 랜딩페이지에 자동으로 표시됨
```

### 모듈 검증 체크리스트

- [ ] module.json 스펙 준수
- [ ] install.ps1 / install.sh 둘 다 존재
- [ ] 로컬 테스트 통과
- [ ] README.md 존재
- [ ] 보안 검토 (민감 정보 하드코딩 없음)

---

## 6. 구현 순서 (Implementation Order)

| Phase | Task | Priority | Status |
|-------|------|----------|--------|
| 1 | module.json 스펙 확정 | HIGH | ✅ 완료 |
| 2 | 기존 모듈 리팩토링 (base, google, atlassian) | HIGH | ✅ 완료 |
| 3 | install.ps1/install.sh 동적 로딩 구현 | HIGH | ✅ 완료 |
| 4 | 새 모듈 추가 (slack, notion, github, figma) | MEDIUM | ⚠️ 테스트 필요 |
| 5 | registry.json 생성 | HIGH | ❌ 미완료 |
| 6 | 랜딩페이지 동적 생성 (adw-landing-page 연동) | MEDIUM | ❌ 미완료 |
| 7 | 기여 가이드 문서 작성 (CONTRIBUTING.md) | LOW | ❌ 미완료 |
| 8 | 각 모듈 README.md 작성 | LOW | ❌ 미완료 |

---

## 7. 리스크 (Risks)

| Risk | Impact | Mitigation |
|------|--------|------------|
| 기존 스크립트와 호환성 | HIGH | 기존 플래그 방식도 유지 (deprecated) |
| 원격 실행 시 registry.json 접근 | MEDIUM | GitHub Raw URL 사용 |
| 악성 모듈 기여 | MEDIUM | PR 리뷰 필수, 보안 체크리스트 |

---

## 8. 참고 (References)

- 기존 ARCHITECTURE.md
- script-modularization.report.md (이전 작업)
