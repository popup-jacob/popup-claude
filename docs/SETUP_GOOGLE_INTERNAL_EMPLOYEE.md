# Google MCP 설정 가이드 (직원용)

> 관리자에게 받은 파일로 설정하는 방법입니다.

---

## 관리자에게 받을 파일

이 4개 파일을 한 폴더에 저장하세요:

- `client_secret.json`
- `google-workspace-mcp.tar`
- `setup_employee.ps1` (Windows용)
- `setup_employee.sh` (Mac용)

---

## 설치 방법

### 1. Docker Desktop 설치

1. https://www.docker.com/products/docker-desktop/ 접속
2. 다운로드 → 설치
3. 설치 후 **Docker Desktop 실행** (고래 아이콘)

### 2. 스크립트 실행

파일 받은 폴더에서:

**Windows:**
1. 폴더 빈 공간에서 마우스 오른쪽 클릭
2. "터미널에서 열기" 클릭
3. 아래 명령어 복사 → 붙여넣기 → Enter

```
powershell -ep bypass -File setup_employee.ps1
```

**Mac:**
1. 터미널 열기
2. 아래 명령어 입력:

```
chmod +x setup_employee.sh && ./setup_employee.sh
```

### 3. 화면 안내 따라하기

스크립트가 실행되면 이런 화면들이 나와요:

```
[1/5] Docker 확인 중...
      → Docker Desktop이 실행 중이면 자동으로 넘어감

[2/5] 설정 폴더 생성 중...
      → 자동으로 생성됨

[3/5] client_secret.json 확인 중...
      → 파일 탐색기가 열림
      → 관리자에게 받은 client_secret.json을
        열린 폴더에 복사하고 Enter

[4/5] Docker 이미지 확인 중...
      → "1" 입력 후 Enter
      → tar 파일 경로 물어보면:
        관리자에게 받은 google-workspace-mcp.tar 파일을
        드래그해서 터미널에 놓기 → Enter

[5/5] Claude 설정 파일 생성 중...
      → 자동으로 완료됨
```

### 4. VS Code 재시작 후 테스트

1. VS Code 완전히 종료 후 다시 열기
2. Claude 채팅창에 입력:

```
내 캘린더 일정 보여줘
```

3. 브라우저가 열리면 **회사 계정**으로 로그인
4. 캘린더가 보이면 성공!

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
