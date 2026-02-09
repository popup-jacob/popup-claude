# ADW Installer 코드 리뷰 체크리스트

> 각 파일을 하나씩 검토하며 체크합니다.

---

## 1. 메인 진입점

### 1.1 install.ps1 (Windows)
- [x] 파라미터 파싱 정상 작동
- [x] 환경변수 지원 (`$env:MODULES`, `$env:SKIP_BASE`, etc.)
- [x] 관리자 권한 상승 로직
- [x] 모듈 스캔 (`Get-AvailableModules`)
- [x] 상태 체크 (`Get-InstallStatus`)
- [x] Docker 필요성 판단
- [x] 모듈 검증
- [x] 순차 실행 (`Invoke-Module`)
- [x] 에러 처리
- [x] 완료 요약

### 1.2 install.sh (Mac/Linux)
- [x] 파라미터 파싱 정상 작동
- [x] 환경변수 지원 (`MODULES`, `SKIP_BASE`, etc.)
- [x] 모듈 스캔
- [x] 상태 체크
- [x] Docker 필요성 판단
- [x] 모듈 검증
- [x] 순차 실행
- [x] 에러 처리 *(수정됨: run_module에 에러 캐치 추가)*
- [x] 완료 요약

---

## 2. Base 모듈

### 2.1 modules/base/module.json
- [ ] 메타데이터 정확성 (name, displayName, description)
- [ ] required: true 설정
- [ ] order: 0 설정

### 2.2 modules/base/install.ps1 (Windows)
- [ ] winget 체크
- [ ] Node.js 설치
- [ ] Git 설치
- [ ] VS Code 설치
- [ ] Docker Desktop 설치 (조건부)
- [ ] Claude Code CLI 설치 (버전 고정)
- [ ] bkit Plugin 설치
- [ ] PATH 갱신 (`Refresh-Path`)
- [ ] 에러 처리

### 2.3 modules/base/install.sh (Mac/Linux)
- [ ] Homebrew 체크/설치 (Mac)
- [ ] Node.js 설치
- [ ] Git 설치
- [ ] VS Code 설치
- [ ] Docker Desktop 설치 (조건부)
- [ ] Claude Code CLI 설치
- [ ] bkit Plugin 설치
- [ ] 에러 처리

---

## 3. Google 모듈

### 3.1 modules/google/module.json
- [ ] 메타데이터 정확성
- [ ] requirements.docker: true
- [ ] requirements.adminSetup: true
- [ ] mcpConfig 설정

### 3.2 modules/google/install.ps1 (Windows)
- [ ] Docker 실행 체크
- [ ] Admin/Employee 분기
- [ ] **Admin 경로:**
  - [ ] gcloud CLI 설치
  - [ ] gcloud 로그인
  - [ ] Internal/External 선택
  - [ ] 프로젝트 생성/선택
  - [ ] API 활성화 (6개)
  - [ ] OAuth Consent Screen 안내
  - [ ] OAuth 클라이언트 생성 안내
- [ ] **Employee 경로:**
  - [ ] client_secret.json 체크
  - [ ] Docker 이미지 pull
  - [ ] OAuth 인증
  - [ ] .mcp.json 설정
- [ ] 에러 처리

### 3.3 modules/google/install.sh (Mac/Linux)
- [ ] Docker 실행 체크
- [ ] Admin/Employee 분기
- [ ] Admin 경로 (위와 동일)
- [ ] Employee 경로 (위와 동일)
- [ ] 에러 처리

---

## 4. Atlassian 모듈

### 4.1 modules/atlassian/module.json
- [ ] 메타데이터 정확성
- [ ] mcpConfig 설정

### 4.2 modules/atlassian/install.ps1 (Windows)
- [ ] Docker 유무 감지
- [ ] Docker/Rovo 선택지 제공
- [ ] **Docker 경로:**
  - [ ] Docker 실행 체크
  - [ ] Atlassian URL, 이메일, API 토큰 입력
  - [ ] Docker 이미지 pull
  - [ ] .mcp.json 설정
- [ ] **Rovo 경로:**
  - [ ] `claude mcp add` 실행
- [ ] 에러 처리

### 4.3 modules/atlassian/install.sh (Mac/Linux)
- [ ] Docker 유무 감지
- [ ] Docker/Rovo 선택지 제공
- [ ] Docker 경로 (위와 동일)
- [ ] Rovo 경로 (위와 동일)
- [ ] 에러 처리

---

## 5. Notion 모듈

### 5.1 modules/notion/module.json
- [ ] 메타데이터 정확성
- [ ] type: "remote-mcp"
- [ ] mcpConfig (transport: http)

### 5.2 modules/notion/install.ps1 (Windows)
- [ ] Claude CLI 체크
- [ ] `claude mcp add` 실행
- [ ] OAuth 인증 (oauth-helper 사용)
- [ ] 에러 처리

### 5.3 modules/notion/install.sh (Mac/Linux)
- [ ] Claude CLI 체크
- [ ] `claude mcp add` 실행
- [ ] OAuth 인증
- [ ] 에러 처리

---

## 6. GitHub 모듈

### 6.1 modules/github/module.json
- [ ] 메타데이터 정확성
- [ ] type: "cli"

### 6.2 modules/github/install.ps1 (Windows)
- [ ] gh CLI 설치 (winget)
- [ ] PATH 갱신
- [ ] `gh auth login` 실행
- [ ] 에러 처리

### 6.3 modules/github/install.sh (Mac/Linux)
- [ ] gh CLI 설치 (Homebrew/apt)
- [ ] `gh auth login` 실행
- [ ] 에러 처리

---

## 7. Figma 모듈

### 7.1 modules/figma/module.json
- [ ] 메타데이터 정확성
- [ ] type: "remote-mcp"
- [ ] mcpConfig 설정

### 7.2 modules/figma/install.ps1 (Windows)
- [ ] Claude CLI 체크
- [ ] `claude mcp add` 실행
- [ ] OAuth 인증 (oauth-helper 사용)
- [ ] 에러 처리

### 7.3 modules/figma/install.sh (Mac/Linux)
- [ ] Claude CLI 체크
- [ ] `claude mcp add` 실행
- [ ] OAuth 인증
- [ ] 에러 처리

---

## 8. 공유 유틸리티

### 8.1 modules/shared/oauth-helper.ps1 (Windows)
- [ ] 기존 토큰 확인
- [ ] OAuth 메타데이터 fetch
- [ ] PKCE 코드 생성
- [ ] 인증 URL 생성
- [ ] 로컬 콜백 리스너
- [ ] 토큰 교환
- [ ] .credentials.json 저장
- [ ] 에러 처리

### 8.2 modules/shared/oauth-helper.sh (Mac/Linux)
- [ ] 기존 토큰 확인
- [ ] OAuth 메타데이터 fetch
- [ ] PKCE 코드 생성
- [ ] 인증 URL 생성
- [ ] 로컬 콜백 리스너
- [ ] 토큰 교환
- [ ] .credentials.json 저장
- [ ] 에러 처리

---

## 9. 통합 테스트

### 9.1 Windows
- [ ] 기본 설치만 (`install.ps1`)
- [ ] Google 모듈 (`-modules "google"`)
- [ ] Atlassian 모듈 (`-modules "atlassian"`)
- [ ] 복합 설치 (`-modules "google,atlassian"`)
- [ ] 전체 설치 (`-all`)

### 9.2 Mac/Linux
- [ ] 기본 설치만 (`install.sh`)
- [ ] Google 모듈 (`MODULES="google"`)
- [ ] Atlassian 모듈 (`MODULES="atlassian"`)
- [ ] 복합 설치 (`MODULES="google,atlassian"`)
- [ ] 전체 설치 (`--all`)

---

## 진행 상황

| 섹션 | 상태 | 메모 |
|------|------|------|
| 1. 메인 진입점 | ✅ 완료 | install.sh 에러 처리 수정됨 |
| 2. Base 모듈 | ⏳ 대기 | |
| 3. Google 모듈 | ⏳ 대기 | |
| 4. Atlassian 모듈 | ⏳ 대기 | |
| 5. Notion 모듈 | ⏳ 대기 | |
| 6. GitHub 모듈 | ⏳ 대기 | |
| 7. Figma 모듈 | ⏳ 대기 | |
| 8. 공유 유틸리티 | ⏳ 대기 | |
| 9. 통합 테스트 | ⏳ 대기 | |

---

## 10. 미완료 항목 (from installer/docs)

> 기존 PDCA 문서에서 옮겨온 미완료/테스트 필요 항목들

### 10.1 테스트 필요 모듈
- [ ] slack 모듈 (스크립트 작성됨, 테스트 필요)
- [ ] notion 모듈 (스크립트 작성됨, 테스트 필요)
- [ ] github 모듈 (스크립트 작성됨, 테스트 필요)
- [ ] figma 모듈 (스크립트 작성됨, 테스트 필요)

### 10.2 미구현 항목
- [ ] `registry.json` 생성
- [ ] `web/index.html` (또는 adw-landing-page 연동)
- [ ] `docs/CONTRIBUTING.md` 작성
- [ ] `modules/*/README.md` 작성 (7개 모듈)

---

## 11. module.json 스펙 (참조용)

> 각 모듈의 module.json이 이 스펙을 준수하는지 확인

```json
{
  "name": "module-id",           // 필수: 폴더명과 동일
  "displayName": "Display Name", // 필수: 랜딩페이지 표시명
  "description": "설명",          // 필수: 모듈 설명
  "version": "1.0.0",            // 필수: 모듈 버전
  "author": "author-name",       // 필수: 작성자

  "type": "mcp | cli | config",  // 필수: 모듈 타입
  "complexity": "simple | moderate | complex", // 필수

  "requirements": {
    "docker": true/false,        // 필수: Docker 필요 여부
    "node": true/false,          // 필수: Node.js 필요 여부
    "adminSetup": true/false     // 필수: 관리자 설정 필요 여부
  },

  "mcpConfig": {                 // MCP 타입인 경우 필수
    "serverName": "mcp-server-name",
    "command": "docker | npx | node",
    "args": ["arg1", "arg2", "{variable}"]
  },

  "links": {                     // 선택
    "docs": "https://...",
    "repo": "https://..."
  }
}
```

### complexity 레벨 기준
| Level | 설명 | 예시 |
|-------|------|------|
| simple | API 키만 입력 | Notion, Slack |
| moderate | CLI 설치 + 로그인 | GitHub (gh CLI) |
| complex | OAuth + 프로젝트 설정 | Google Workspace |

### mcpConfig.args 변수
| 변수 | 치환값 |
|------|--------|
| `{configDir}` | 사용자 설정 디렉토리 (~/.{module-name}) |
| `{homeDir}` | 사용자 홈 디렉토리 |

---

## 메모

(리뷰 중 발견한 이슈나 개선점 기록)

