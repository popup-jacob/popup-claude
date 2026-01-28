# Jira + Confluence 설정 가이드 (개발자용)

> Rovo MCP를 사용하여 빠르고 간편하게 설정하는 방법입니다.

---

## 이 가이드가 맞는 경우

- [x] 개발자입니다
- [x] Jira와 Confluence를 Claude에서 사용하고 싶습니다
- [x] 빠르고 간단한 설정을 원합니다

---

## 장점

| 항목 | Rovo MCP |
|------|----------|
| 설치 난이도 | 쉬움 |
| Docker 필요 | 아니오 |
| API 토큰 필요 | 아니오 |
| 설정 시간 | 약 5분 |

---

## 설치 순서

### 1단계: 파일 다운로드

```bash
git clone https://github.com/popup-studio-ai/AI-driven-work.git
cd AI-driven-work/installer_popup
```

또는 ZIP 다운로드 후 `installer_popup` 폴더로 이동

### 2단계: 설치 스크립트 실행

#### Windows

```powershell
powershell -ep bypass -File install_dev.ps1
```

#### Mac

```bash
chmod +x install_dev.sh && ./install_dev.sh
```

### 3단계: MCP 설정

#### Windows

```powershell
powershell -ep bypass -File setup.ps1
```

#### Mac

```bash
chmod +x setup.sh && ./setup.sh
```

### 4단계: 질문에 답하기

```
직군 선택: 1 (Developer)
MCP Server 선택: 1 (Rovo MCP Server)
```

### 5단계: 브라우저에서 로그인

1. 브라우저가 자동으로 열립니다
2. Atlassian 계정으로 로그인
3. "허용" 버튼 클릭
4. 완료!

---

## 설치 확인

VS Code에서 Claude를 열고 입력:

```
Jira 프로젝트 목록 보여줘
```

프로젝트 목록이 나오면 성공!

---

## 문제 해결

### 브라우저가 안 열려요

→ 수동으로 터미널에 표시된 URL을 복사해서 브라우저에 붙여넣기

### 로그인했는데 안 돼요

→ VS Code를 재시작하세요

### Claude에서 Jira가 안 보여요

→ `.mcp.json` 파일이 프로젝트 폴더에 있는지 확인하세요

---

## 다음 단계

Google Workspace도 연동하고 싶다면:
- [Google 설정 가이드 (관리자)](SETUP_GOOGLE_INTERNAL_ADMIN.md)
- [Google 설정 가이드 (직원)](SETUP_GOOGLE_INTERNAL_EMPLOYEE.md)
