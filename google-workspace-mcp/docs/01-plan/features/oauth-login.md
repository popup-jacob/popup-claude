# Feature Plan: OAuth 로그인 방식 인증

## 개요
- **기능명**: Google OAuth 로그인 인증
- **목표**: 토큰 복사/붙여넣기 없이 Google 로그인만으로 인증

## 요구사항

### 사용자 경험
1. 처음 사용 시 브라우저에서 Google 로그인 창 열림
2. 본인 계정 선택 및 권한 허용
3. 자동으로 토큰 저장
4. 다음부터는 자동 로그인

### 기술 요구사항
- OAuth 2.0 Authorization Code Flow
- Refresh Token으로 자동 갱신
- 토큰 로컬 저장 (credentials.json)

## 필요한 Google API Scopes
```
https://www.googleapis.com/auth/gmail.modify
https://www.googleapis.com/auth/calendar
https://www.googleapis.com/auth/drive
https://www.googleapis.com/auth/documents
https://www.googleapis.com/auth/spreadsheets
https://www.googleapis.com/auth/presentations
```

## 사전 준비 (사용자)
1. Google Cloud Console에서 프로젝트 생성
2. OAuth 동의 화면 설정
3. OAuth 2.0 클라이언트 ID 생성 (Desktop App)
4. client_secret.json 다운로드

## 구현 계획
1. OAuth 인증 모듈 작성
2. 토큰 저장/로드/갱신 로직
3. MCP 서버 시작 시 인증 체크
