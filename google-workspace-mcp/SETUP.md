# Google Workspace MCP 설정 가이드 (개발자용 수동 설정)

> 일반 사용자는 [ADW 설치 프로그램](../README.md)을 사용하세요.
> 이 가이드는 Google MCP를 직접 빌드/개발하려는 경우를 위한 것입니다.

## 1단계: Google Cloud Console 설정

### 1.1 프로젝트 생성
1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. 상단 프로젝트 선택 → "새 프로젝트"
3. 프로젝트 이름: `google-workspace-mcp` (원하는 이름)
4. "만들기" 클릭

### 1.2 API 활성화
1. 왼쪽 메뉴 → "API 및 서비스" → "라이브러리"
2. 다음 API 검색하여 각각 "사용" 클릭:
   - Gmail API
   - Google Calendar API
   - Google Drive API
   - Google Docs API
   - Google Sheets API
   - Google Slides API

### 1.3 OAuth 동의 화면 설정
1. 왼쪽 메뉴 → "OAuth 동의 화면"
2. User Type: "내부" (회사 계정) 또는 "외부" 선택
3. 앱 정보 입력:
   - 앱 이름: `Google Workspace MCP`
   - 사용자 지원 이메일: 본인 이메일
   - 개발자 연락처: 본인 이메일
4. "저장 후 계속"
5. Scopes 추가 → "범위 추가 또는 삭제" 클릭:
   ```
   https://www.googleapis.com/auth/gmail.modify
   https://www.googleapis.com/auth/calendar
   https://www.googleapis.com/auth/drive
   https://www.googleapis.com/auth/documents
   https://www.googleapis.com/auth/spreadsheets
   https://www.googleapis.com/auth/presentations
   ```
6. "저장 후 계속" → "대시보드로 돌아가기"

### 1.4 OAuth 클라이언트 ID 생성
1. 왼쪽 메뉴 → "사용자 인증 정보"
2. 상단 "+ 사용자 인증 정보 만들기" → "OAuth 클라이언트 ID"
3. 애플리케이션 유형: "데스크톱 앱"
4. 이름: `Google Workspace MCP Client`
5. "만들기" 클릭
6. **"JSON 다운로드"** 클릭 → `client_secret_xxx.json` 파일 저장

---

## 2단계: 프로젝트 설정

### 2.1 설정 폴더 생성
```bash
# 프로젝트 폴더에서
mkdir .google-workspace
```

### 2.2 client_secret.json 복사
다운로드한 JSON 파일을 `.google-workspace/client_secret.json`으로 복사:
```bash
cp ~/Downloads/client_secret_xxx.json .google-workspace/client_secret.json
```

### 2.3 의존성 설치
```bash
npm install
```

### 2.4 빌드
```bash
npm run build
```

---

## 3단계: 첫 실행 (로그인)

```bash
npm run dev
```

1. 브라우저가 자동으로 열림
2. Google 계정 선택
3. "허용" 클릭
4. "인증이 완료되었습니다" 페이지 확인
5. 브라우저 닫기

토큰이 `.google-workspace/token.json`에 자동 저장됩니다.

---

## 4단계: Docker 이미지 빌드

```bash
docker build -t google-workspace-mcp .
```

---

## 5단계: Claude Desktop 연동

### 5.1 .mcp.json 파일 생성 (프로젝트 폴더에)
```json
{
  "mcpServers": {
    "google-workspace": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "C:/경로/.google-workspace:/app/.google-workspace",
        "google-workspace-mcp"
      ]
    }
  }
}
```

### 5.2 경로 수정
- `C:/경로/`를 실제 `.google-workspace` 폴더가 있는 경로로 변경

### 5.3 Claude Desktop 재시작

---

## 사용 예시

```
"내 메일함에서 회의 관련 메일 찾아줘"
"1월 27일 오후 2시에 팀 미팅 잡아줘. 철수, 영희 초대해"
"오늘 회의 내용으로 문서 만들어줘"
"이 데이터 스프레드시트에 정리해줘"
```

---

## 문제 해결

### 토큰 만료
토큰은 자동으로 갱신됩니다. 문제가 있으면:
```bash
rm .google-workspace/token.json
npm run dev  # 다시 로그인
```

### 권한 오류
OAuth 동의 화면에서 필요한 Scope가 모두 추가되었는지 확인하세요.
