# AI-Driven Work 설정 가이드

> Claude와 업무 도구들을 연동하여 AI 기반 업무 환경을 구축하는 가이드입니다.

---

## 전체 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                         Claude                                  │
│                           │                                     │
│            ┌──────────────┼──────────────┐                     │
│            │              │              │                     │
│            ▼              ▼              ▼                     │
│     ┌──────────┐   ┌──────────┐   ┌──────────┐                │
│     │   Jira   │   │Confluence│   │  Google  │                │
│     │          │   │          │   │Workspace │                │
│     └──────────┘   └──────────┘   └──────────┘                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

연동하고 싶은 조합을 선택하세요:

| # | 조합 | 용도 |
|---|------|------|
| 1 | Jira + Confluence + Claude | 프로젝트 관리, 문서 작업 |
| 2 | Google + Claude | 이메일, 캘린더, 드라이브, 문서 |
| 3 | 전부 다 | 완전한 AI 업무 환경 |

---

## 0단계: 기본 설치 (모든 조합 공통)

> Claude Code와 필수 프로그램들을 설치합니다.

### 파일 다운로드

```bash
git clone https://github.com/popup-studio-ai/AI-driven-work.git
cd AI-driven-work/installer_popup
```

또는 [ZIP 다운로드](https://github.com/popup-studio-ai/AI-driven-work/archive/refs/heads/main.zip) 후 `installer_popup` 폴더로 이동

### 설치 스크립트 실행

#### Windows

```powershell
# 비개발자 (기획자, 디자이너, 마케터 등)
powershell -ep bypass -File install.ps1

# 개발자 (Docker 포함)
powershell -ep bypass -File install_dev.ps1
```

#### Mac

```bash
# 비개발자
chmod +x install.sh && ./install.sh

# 개발자 (Docker 포함)
chmod +x install_dev.sh && ./install_dev.sh
```

### 설치되는 프로그램

| 프로그램 | 설명 | 비개발자 | 개발자 |
|---------|------|:-------:|:------:|
| Node.js | JavaScript 실행 환경 | ✅ | ✅ |
| Git | 버전 관리 | ✅ | ✅ |
| VS Code | 코드 편집기 | ✅ | ✅ |
| Claude Code CLI | 터미널에서 Claude 사용 | ✅ | ✅ |
| Docker Desktop | 컨테이너 실행 환경 | ❌ | ✅ |

---

## 1. Jira + Confluence + Claude 연동

### 질문: 개발자인가요?

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   개발자인가요?                                              │
│                                                             │
│   ┌─────────────┐              ┌─────────────┐             │
│   │     예      │              │    아니오    │             │
│   └──────┬──────┘              └──────┬──────┘             │
│          │                            │                     │
│          ▼                            ▼                     │
│   ┌─────────────┐              ┌─────────────┐             │
│   │  Rovo MCP   │              │ mcp-atlassian│             │
│   │  (간편)     │              │  (Docker)   │             │
│   └─────────────┘              └─────────────┘             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

| 나는... | 가이드 |
|---------|--------|
| 개발자 | [SETUP_JIRA_DEVELOPER.md](SETUP_JIRA_DEVELOPER.md) |
| 비개발자 (기획자, 디자이너 등) | [SETUP_JIRA_NONDEVELOPER.md](SETUP_JIRA_NONDEVELOPER.md) |

### 비교표

| 방식 | 대상 | Docker 필요 | API 토큰 필요 |
|------|------|:-----------:|:------------:|
| Rovo MCP | 개발자 | ❌ | ❌ |
| mcp-atlassian | 모두 | ✅ | ✅ |

---

## 2. Google + Claude 연동

### 질문 1: 회사가 Google Workspace를 사용하나요?

> **Google Workspace** = 회사 이메일이 `@회사.com` 형태 (예: jacob@popupstudio.ai)
>
> **일반 Gmail** = `@gmail.com`

### 질문 2: 설정하는 사람인가요, 사용하는 사람인가요?

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   회사가 Google Workspace를 사용하나요?                                       │
│                                                                             │
│   ┌─────────────────────┐                    ┌─────────────────────┐       │
│   │         예          │                    │       아니오        │       │
│   │  (회사 이메일 사용)  │                    │   (Gmail 사용)      │       │
│   └──────────┬──────────┘                    └──────────┬──────────┘       │
│              │                                          │                   │
│              ▼                                          ▼                   │
│   ┌─────────────────────┐                    ┌─────────────────────┐       │
│   │   Internal 모드     │                    │   External 모드     │       │
│   │  (무제한, 만료없음)  │                    │  (100명, 7일만료)   │       │
│   └──────────┬──────────┘                    └──────────┬──────────┘       │
│              │                                          │                   │
│       ┌──────┴──────┐                            ┌──────┴──────┐           │
│       │             │                            │             │           │
│       ▼             ▼                            ▼             ▼           │
│   ┌───────┐    ┌───────┐                    ┌───────┐    ┌───────┐        │
│   │ 관리자 │    │ 직원  │                    │ 관리자 │    │ 팀원  │        │
│   └───────┘    └───────┘                    └───────┘    └───────┘        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

| 회사 유형 | 역할 | 가이드 |
|-----------|------|--------|
| Google Workspace 회사 | 관리자 (설정하는 사람) | [SETUP_GOOGLE_INTERNAL_ADMIN.md](SETUP_GOOGLE_INTERNAL_ADMIN.md) |
| Google Workspace 회사 | 직원 (사용하는 사람) | [SETUP_GOOGLE_INTERNAL_EMPLOYEE.md](SETUP_GOOGLE_INTERNAL_EMPLOYEE.md) |
| 일반 Gmail 사용 | 관리자 (설정하는 사람) | [SETUP_GOOGLE_EXTERNAL_ADMIN.md](SETUP_GOOGLE_EXTERNAL_ADMIN.md) |
| 일반 Gmail 사용 | 팀원 (사용하는 사람) | [SETUP_GOOGLE_EXTERNAL_EMPLOYEE.md](SETUP_GOOGLE_EXTERNAL_EMPLOYEE.md) |

### 비교표

| 모드 | 대상 | 사용자 수 | 토큰 만료 | Google 검토 |
|------|------|:--------:|:--------:|:-----------:|
| Internal | Google Workspace 회사 | 무제한 | 없음 | 불필요 |
| External | Gmail 사용자 | 100명 | 7일 | 100명 초과시 필요 |

---

## 3. 전부 다 연동 (Jira + Confluence + Google + Claude)

두 가지를 모두 연동하려면:

1. **0단계**: 기본 설치 완료
2. **1단계**: Jira + Confluence 가이드 따라 설정
3. **2단계**: Google 가이드 따라 설정
4. **3단계**: `.mcp.json` 파일에 두 설정 합치기

### 합친 .mcp.json 예시

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "mcp-atlassian", "..."]
    },
    "google-workspace": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "C:/Users/내이름/.google-workspace:/app/.google-workspace",
        "google-workspace-mcp"
      ]
    }
  }
}
```

---

## 자주 묻는 질문

### Q: 우리 회사가 Google Workspace인지 어떻게 알아요?

**A:** 회사 이메일이 `@gmail.com`이 아니라 `@회사이름.com` 형태면 Google Workspace입니다.

### Q: Internal이랑 External 뭐가 달라요?

**A:**
- **Internal**: Google Workspace 회사 전용. 무제한 사용, 토큰 만료 없음
- **External**: 누구나 가능. 100명 제한, 7일마다 재로그인

### Q: 관리자 vs 직원?

**A:**
- **관리자**: 처음 설정하는 사람. Google Cloud Console에서 프로젝트/Client ID 생성
- **직원**: 관리자가 설정한 걸 사용. `client_secret.json` 파일만 받으면 됨

### Q: 개발자 vs 비개발자?

**A:**
- **개발자**: Docker 사용 가능, 터미널 익숙함
- **비개발자**: Docker 없이 간단한 방식 선호

---

## 설치 확인

모든 설정이 끝나면 VS Code에서 Claude를 열고 테스트:

```
# Jira + Confluence 테스트
"Jira 프로젝트 목록 보여줘"
"Confluence에서 최근 문서 찾아줘"

# Google 테스트
"내 캘린더 일정 보여줘"
"jacob@회사.com한테 메일 보내줘"
"드라이브에서 기획서 찾아줘"
```

---

## 도움이 필요하면

1. 각 가이드의 "문제 해결" 섹션 확인
2. IT팀에 문의
3. GitHub Issues에 질문
