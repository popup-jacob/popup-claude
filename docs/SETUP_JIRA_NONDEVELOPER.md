# Jira + Confluence 설정 가이드 (비개발자용)

> mcp-atlassian을 사용하여 Docker 기반으로 설정하는 방법입니다.

---

## 이 가이드가 맞는 경우

- [x] 비개발자입니다 (기획자, 디자이너, 마케터 등)
- [x] Jira와 Confluence를 Claude에서 사용하고 싶습니다
- [x] IT팀에서 Docker를 설치해줬습니다

---

## 사전 요구사항

- [ ] Docker Desktop 설치됨 (IT팀에 요청)
- [ ] Atlassian 계정 보유

---

## 설치 순서

### 1단계: 파일 다운로드

ZIP 파일 다운로드:
1. https://github.com/popup-studio-ai/AI-driven-work 접속
2. 초록색 `<> Code` 버튼 클릭
3. `Download ZIP` 클릭
4. 바탕화면에 압축 풀기
5. `installer_popup` 폴더로 이동

### 2단계: 설치 스크립트 실행

#### Windows

1. `installer_popup` 폴더에서 마우스 오른쪽 클릭
2. "터미널에서 열기" 클릭
3. 아래 명령어 입력 후 Enter:

```powershell
powershell -ep bypass -File install.ps1
```

4. "관리자 권한이 필요합니다" → "예" 클릭

#### Mac

1. 터미널 열기
2. 아래 명령어 입력:

```bash
chmod +x install.sh && ./install.sh
```

### 3단계: API 토큰 생성

1. 이 링크 열기: https://id.atlassian.com/manage-profile/security/api-tokens
2. **"API 토큰 만들기"** 클릭
3. 토큰 이름: `MCP` 입력
4. **"만들기"** 클릭
5. **토큰 복사해서 메모장에 저장** (다시 못 봄!)

### 4단계: MCP 설정

#### Windows

```powershell
powershell -ep bypass -File setup.ps1
```

#### Mac

```bash
chmod +x setup.sh && ./setup.sh
```

### 5단계: 질문에 답하기

```
직군 선택: 2 (Non-developer)
MCP Server 선택: 2 (mcp-atlassian)
```

그 다음 나오는 질문들:

```
Confluence URL: https://회사이름.atlassian.net/wiki
Confluence email: 본인이메일@회사.com
Confluence API token: (복사한 토큰 붙여넣기)

Jira URL: https://회사이름.atlassian.net
Jira email: 본인이메일@회사.com
Jira API token: (복사한 토큰 붙여넣기)
```

---

## 설치 확인

VS Code에서 Claude를 열고 입력:

```
Jira 프로젝트 목록 보여줘
```

프로젝트 목록이 나오면 성공!

---

## 문제 해결

### Docker Desktop이 안 열려요

→ 컴퓨터 재부팅 후 다시 시도

### API 토큰을 잃어버렸어요

→ https://id.atlassian.com/manage-profile/security/api-tokens 에서 새로 생성

### "command not found" 에러

→ 터미널을 닫고 새로 열어보세요

### Jira가 안 보여요

1. Docker Desktop이 실행 중인지 확인
2. API 토큰이 올바른지 확인
3. 회사 Jira URL이 맞는지 확인

---

## 다음 단계

Google Workspace도 연동하고 싶다면:
- [Google 설정 가이드 (직원용)](SETUP_GOOGLE_INTERNAL_EMPLOYEE.md)
