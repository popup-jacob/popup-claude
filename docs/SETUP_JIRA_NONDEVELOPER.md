# Jira + Confluence 설정 가이드 (비개발자용)

> mcp-atlassian을 사용하여 Docker 기반으로 설정하는 방법입니다.

---

## 이 가이드가 맞는 경우

- [x] 비개발자입니다 (기획자, 디자이너, 마케터 등)
- [x] Jira와 Confluence를 Claude에서 사용하고 싶습니다

---

## 사전 요구사항

- [ ] Docker Desktop 설치됨
- [ ] Atlassian 계정 보유

---

## 1단계: API 토큰 생성 (먼저!)

1. 이 링크 열기: https://id.atlassian.com/manage-profile/security/api-tokens
2. **"API 토큰 만들기"** 클릭
3. 토큰 이름: `MCP` 입력
4. **"만들기"** 클릭
5. **토큰 복사해서 메모장에 저장** (다시 못 봄!)

---

## 2단계: 설치

### Windows

`Win + R` 키를 누르고, 아래 명령어를 붙여넣고 실행:
```
powershell -ep bypass -c "irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_mcp.ps1|iex"
```

### Mac

터미널을 열고 아래 명령어 실행:
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_all.sh | bash
```

---

## 3단계: 설치 중 안내

스크립트가 실행되면:

1. **Jira/Confluence MCP 설정 여부** → `y` 입력
2. **역할 선택** → `2` (Non-developer) 선택
3. **MCP Server 선택** → `2` (mcp-atlassian) 선택
4. 아래 정보 입력:

```
Confluence URL: https://회사이름.atlassian.net/wiki
Confluence email: 본인이메일@회사.com
Confluence API token: (복사한 토큰 붙여넣기)

Jira URL: https://회사이름.atlassian.net
Jira email: 본인이메일@회사.com
Jira API token: (복사한 토큰 붙여넣기)
```

5. 완료!

---

## 설치 확인

VS Code 또는 터미널에서 Claude에게 물어보세요:

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
