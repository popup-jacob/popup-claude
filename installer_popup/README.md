# Claude Code + Jira/Confluence 설치 가이드

> Claude Code와 Atlassian MCP Server를 설정하는 스크립트입니다.

---

## 권장: 원클릭 설치 사용

더 간단한 설치를 원하시면 [final-installer](../final-installer/)를 사용하세요.

### Windows
```
Win + R 누르고 실행:
powershell -ep bypass -c "irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_basic.ps1|iex"
```

### Mac
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_all.sh | bash
```

---

## 이 폴더의 스크립트

| 파일 | 설명 |
|------|------|
| `install.ps1` / `install.sh` | 기본 도구 설치 (비개발자용) |
| `install_dev.ps1` / `install_dev.sh` | 기본 도구 + Docker 설치 (개발자용) |
| `setup.ps1` / `setup.sh` | Jira/Confluence MCP 설정 |

---

## 로컬 설치 방법

### Windows

```powershell
# 1단계: 프로그램 설치
powershell -ep bypass -File install.ps1      # 비개발자
powershell -ep bypass -File install_dev.ps1  # 개발자

# 2단계: 재부팅 (개발자만)

# 3단계: MCP 설정
powershell -ep bypass -File setup.ps1
```

### Mac

```bash
# 1단계: 프로그램 설치
chmod +x install.sh && ./install.sh      # 비개발자
chmod +x install_dev.sh && ./install_dev.sh  # 개발자

# 2단계: MCP 설정
chmod +x setup.sh && ./setup.sh
```

---

## setup 실행 시 질문

### 역할 선택 (통합 질문)

```
역할을 선택하세요:

1. 비개발자 (Rovo MCP - 로그인만)
   - 기획, 디자인, 마케팅, 운영
   - 간편 설정: OAuth 로그인만

2. 개발자 (mcp-atlassian - Docker)
   - 백엔드, 프론트엔드, DevOps, QA
   - 전체 기능: API 토큰 + Docker

선택하세요 (1 또는 2):
```

### 1번 선택 시 (Rovo MCP)

- 브라우저가 열림
- Atlassian 계정으로 로그인
- "허용" 버튼 클릭
- 끝!

### 2번 선택 시 (mcp-atlassian)

API 토큰이 필요합니다:

1. https://id.atlassian.com/manage-profile/security/api-tokens 접속
2. **"API 토큰 만들기"** 클릭
3. 토큰 이름 입력 (예: MCP)
4. 토큰 복사해서 저장 (다시 못 봄!)

그 다음 정보 입력:

```
Confluence URL: https://회사이름.atlassian.net/wiki
Jira URL: https://회사이름.atlassian.net
이메일: 본인이메일@회사.com
API 토큰: (복사한 토큰 붙여넣기)
```

---

## 설치 확인

VS Code 또는 터미널에서 Claude에게:

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

### Jira가 안 보여요

1. Docker Desktop이 실행 중인지 확인
2. API 토큰이 올바른지 확인
3. 회사 Jira URL이 맞는지 확인

---

## 도움이 필요하면

IT팀에 문의하세요.

**필요한 정보:**
- 어떤 파일을 실행했는지
- 에러 메시지 (화면 캡처)
- Windows/Mac 여부
