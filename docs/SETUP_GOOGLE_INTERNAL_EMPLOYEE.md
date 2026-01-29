# Google MCP 설정 가이드 (직원용)

> 관리자에게 받은 파일로 설정하는 방법입니다.

---

## 관리자에게 받을 파일

`client_secret.json` 파일 1개만 받으면 됩니다.

---

## 설치 방법

### Windows

**1단계:** `Win + R` 키를 누르고, 아래 명령어를 붙여넣고 실행:
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

1. **Google MCP 설정 여부** → `y` 입력
2. **역할 선택** → `2` (Employee) 선택
3. **client_secret.json 복사** → 폴더가 열리면 관리자에게 받은 파일을 복사
4. **Google 로그인** → 브라우저가 열리면 **회사 계정**으로 로그인
5. 완료!

---

## 설치 확인

VS Code 또는 터미널에서 Claude에게 물어보세요:

```
내 캘린더 일정 보여줘
```

캘린더가 보이면 성공!

---

## 사용 예시

```
"내 캘린더 일정 보여줘"
"홍길동@회사.com한테 메일 보내줘"
"드라이브에서 기획서 찾아줘"
"새 문서 만들어줘"
```

---

## 문제가 생기면

### "Docker Desktop이 실행 중이 아닙니다"

→ 작업 표시줄에서 고래 아이콘(Docker) 클릭해서 실행

### "내부 사용자만 앱에 액세스할 수 있습니다"

→ gmail.com 말고 **회사 이메일**로 로그인하세요

### 로그인 화면이 안 떠요

→ VS Code를 완전히 껐다가 다시 켜보세요

### 그래도 안 되면

→ IT팀에 문의하세요
