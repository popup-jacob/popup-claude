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

## 설치 방법

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

## 설치 중 안내

스크립트가 실행되면:

1. **Jira/Confluence MCP 설정 여부** → `y` 입력
2. **역할 선택** → `1` (Developer) 선택
3. **MCP Server 선택** → `1` (Rovo MCP Server) 선택
4. **브라우저 로그인** → Atlassian 계정으로 로그인 → "허용" 클릭
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

### 브라우저가 안 열려요

→ 수동으로 터미널에 표시된 URL을 복사해서 브라우저에 붙여넣기

### 로그인했는데 안 돼요

→ VS Code를 재시작하세요

### Claude에서 Jira가 안 보여요

→ `~/.mcp.json` 파일이 있는지 확인하세요

---

## 다음 단계

Google Workspace도 연동하고 싶다면:
- [Google 설정 가이드 (관리자)](SETUP_GOOGLE_INTERNAL_ADMIN.md)
- [Google 설정 가이드 (직원)](SETUP_GOOGLE_INTERNAL_EMPLOYEE.md)
