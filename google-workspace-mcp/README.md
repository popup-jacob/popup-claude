# Google Workspace MCP

Claude Code에서 Google Workspace (Gmail, Calendar, Drive)에 접근할 수 있게 해주는 MCP 서버입니다.

## 설치 방법

### 일반 사용자

[원클릭 설치](../README.md)를 사용하세요. Google MCP가 자동으로 설정됩니다.

### 관리자

팀을 위해 Google MCP를 설정하려면:

1. [내부 관리자 가이드](../docs/SETUP_GOOGLE_INTERNAL_ADMIN.md) 참고
2. Google Cloud Console에서 OAuth 설정
3. 직원들에게 `client_secret.json` 공유

---

## Docker 이미지

```bash
# 이미지 다운로드
docker pull ghcr.io/popup-jacob/google-workspace-mcp:latest

# 실행
docker run -i --rm \
  -v "$HOME/.google-workspace:/app/.google-workspace" \
  ghcr.io/popup-jacob/google-workspace-mcp:latest
```

---

## 지원 기능

| 서비스 | 기능 |
|--------|------|
| Gmail | 이메일 읽기, 검색 |
| Calendar | 일정 조회, 생성 |
| Drive | 파일 검색, 다운로드 |

---

## 개발

### 빌드

```bash
npm install
npm run build
```

### Docker 이미지 빌드

```bash
docker build -t google-workspace-mcp .
```

### Multi-arch 빌드 (AMD64 + ARM64)

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/popup-jacob/google-workspace-mcp:latest --push .
```
